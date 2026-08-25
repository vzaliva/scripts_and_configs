#!/usr/bin/env python3

# Automatically configure external monitor layout and move i3 workspaces.
# Dependencies (Ubuntu packages):
#   - python3
#   - python3-rich
#   - x11-xserver-utils  (for xrandr)
#   - i3-wm              (for i3-msg)
#   - python3-pulsectl, python3-rich  (for ~/bin/set_sound.py)

import argparse
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

from rich.console import Console
from rich.table import Table

console = Console()
err_console = Console(stderr=True)

# Workspaces pinned to the laptop panel whenever an external monitor is present.
# Everything else is left wherever it currently is, so manual placement sticks.
INTERNAL_WORKSPACES = [1, 2, 3, 4, 5]


def run(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, text=True)


def detect_external_outputs(xr_output: str) -> list[str]:
    """Every connected output that is not the built-in panel.

    Driver naming varies (HDMI-A-0, DisplayPort-10, DP-1-2), so match on
    "connected and not internal" instead of a list of port name patterns.
    """
    outputs: list[str] = []
    for line in xr_output.splitlines():
        m = re.match(r"^(\S+)\s+connected\b", line)
        if m and not re.match(r"^(eDP|LVDS)", m.group(1)):
            outputs.append(m.group(1))
    return outputs


def detect_internal_output(xr_output: str) -> str | None:
    for line in xr_output.splitlines():
        if re.match(r"^(eDP[^ \t]*|LVDS[^ \t]*)\s+connected", line):
            return line.split()[0]
    return None


def detect_modes(xr_output: str) -> dict[str, list[tuple[int, int, bool]]]:
    """Map each output name to its mode list as (width, height, preferred)."""
    modes: dict[str, list[tuple[int, int, bool]]] = {}
    current: str | None = None
    for line in xr_output.splitlines():
        if re.match(r"^\S", line):
            m = re.match(r"^(\S+)\s+(connected|disconnected)\b", line)
            current = m.group(1) if m else None
            if current:
                modes.setdefault(current, [])
            continue
        if current is None:
            continue
        m = re.match(r"^\s+(\d+)x(\d+)\s+(.*)$", line)
        if m:
            modes[current].append((int(m.group(1)), int(m.group(2)), "+" in m.group(3)))
    return modes


def best_mode(modes: list[tuple[int, int, bool]]) -> tuple[int, int] | None:
    """Preferred mode if the driver flags one, otherwise the largest by area."""
    if not modes:
        return None
    preferred = [m for m in modes if m[2]]
    pool = preferred or modes
    w, h, _ = max(pool, key=lambda m: (m[0] * m[1], m[0]))
    return (w, h)


def rank_externals(
    externals: list[str], modes: dict[str, list[tuple[int, int, bool]]]
) -> list[tuple[str, tuple[int, int] | None]]:
    """Order external outputs largest-panel first (stable on ties by name)."""
    ranked = [(name, best_mode(modes.get(name, []))) for name in externals]
    ranked.sort(key=lambda item: (-(item[1][0] * item[1][1]) if item[1] else 0, item[0]))
    return ranked


def detect_stale_outputs(xr_output: str) -> list[str]:
    """Disconnected outputs that still hold a CRTC (common after a dock reshuffle)."""
    stale: list[str] = []
    for line in xr_output.splitlines():
        m = re.match(r"^(\S+)\s+disconnected.*?\b\d+x\d+\+\d+\+\d+", line)
        if m:
            stale.append(m.group(1))
    return stale


def get_workspaces() -> list[dict]:
    try:
        data = run(["i3-msg", "-t", "get_workspaces"])
    except Exception:
        return []
    try:
        ws = json.loads(data)
    except Exception:
        return []
    return [w for w in ws if isinstance(w.get("num"), int) and w["num"] >= 0]


def get_workspace_numbers() -> list[int]:
    """Return numeric workspace IDs (>= 0)."""
    return [w["num"] for w in get_workspaces()]


def get_focused_workspace() -> int | None:
    """Return the numeric ID of the currently focused workspace, if any."""
    for w in get_workspaces():
        if w.get("focused"):
            return w["num"]
    return None


def list_outputs() -> None:
    try:
        xr = run(["xrandr"])
    except Exception as e:
        err_console.print(f"[red]Error running xrandr:[/red] {e}")
        raise SystemExit(1)

    outputs: list[dict] = []
    pattern = re.compile(r"^(\S+)\s+(connected|disconnected)(\s+primary)?\s*(.*)$")
    for line in xr.splitlines():
        m = pattern.match(line)
        if not m:
            continue
        name, status, primary, rest = m.group(1), m.group(2), m.group(3), m.group(4)
        primary_flag = bool(primary)

        if status == "connected":
            if re.match(r"^(eDP|LVDS)", name):
                group = "internal"
            else:
                group = "external"
        else:
            group = "disabled"

        outputs.append(
            {
                "name": name,
                "status": status,
                "primary": primary_flag,
                "rest": (rest or "").strip(),
                "group": group,
            }
        )

    internal = [o for o in outputs if o["group"] == "internal"]
    external = [o for o in outputs if o["group"] == "external" and o["status"] == "connected"]
    disabled = [o for o in outputs if o["group"] == "disabled"]

    if not internal:
        err_console.print("[red]Error: no internal display (eDP/LVDS) detected[/red]")
        raise SystemExit(1)

    workspaces = get_workspaces()
    ws_by_output: dict[str, list[dict]] = {}
    for w in workspaces:
        out = w.get("output") or ""
        ws_by_output.setdefault(out, []).append(w)

    def render_group(title: str, group: list[dict], style: str) -> None:
        if not group:
            return
        table = Table(title=title, show_header=True, header_style="bold")
        table.add_column("Output", style=style)
        table.add_column("Status")
        table.add_column("Primary")
        table.add_column("Mode")
        table.add_column("Workspaces")
        for o in group:
            wlist = sorted(ws_by_output.get(o["name"], []), key=lambda x: x["num"])
            ws_nums = ", ".join(str(w["num"]) for w in wlist)
            table.add_row(
                o["name"],
                o["status"],
                "yes" if o["primary"] else "",
                o["rest"],
                ws_nums,
            )
        console.print(table)
        console.print()

    render_group("Internal outputs", internal, "bold green")
    render_group("External outputs", external, "bold cyan")
    render_group("Disabled outputs", disabled, "bold red")

    # Chain into audio sinks list if available
    sound_script = Path.home() / "bin" / "set_sound.py"
    if sound_script.exists() and os.access(sound_script, os.X_OK):
        console.print()
        console.print("[bold]Audio sinks:[/bold]")
        subprocess.run([str(sound_script), "--list"], check=False)


def configure_monitors(verbose: bool, wake: bool = True) -> None:
    try:
        xr_output = run(["xrandr"])
    except Exception as e:
        err_console.print(f"[red]Error running xrandr:[/red] {e}")
        raise SystemExit(1)

    externals = detect_external_outputs(xr_output)
    internal = detect_internal_output(xr_output)

    if not internal:
        err_console.print("[red]Error: no internal display (eDP/LVDS) detected[/red]")
        raise SystemExit(1)

    # Snapshot current workspace state so we can restore per-output
    # visible workspaces and the globally focused workspace after moves.
    workspaces_before = get_workspaces()
    workspace_numbers = [w["num"] for w in workspaces_before]
    focused_ws = next((w["num"] for w in workspaces_before if w.get("focused")), None)
    visible_before_by_output: dict[str, int] = {}
    output_before_by_ws: dict[int, str] = {}
    for w in workspaces_before:
        out = w.get("output")
        if isinstance(out, str):
            output_before_by_ws[w["num"]] = out
            if w.get("visible"):
                visible_before_by_output[out] = w["num"]

    def i3(cmd: str) -> None:
        subprocess.run(["i3-msg", "-q", cmd], check=False)

    # Physical outputs get renumbered by the dock/MST hub between sessions, so
    # classify by panel size rather than by name: the biggest external panel is
    # the main one (stacked above the laptop), the next one sits to the left.
    modes = detect_modes(xr_output)
    ranked = rank_externals(externals, modes)

    main_external, main_mode = ranked[0] if ranked else (None, None)
    side_external, side_mode = ranked[1] if len(ranked) > 1 else (None, None)
    extra_externals = ranked[2:]

    def mode_args(mode: tuple[int, int] | None) -> list[str]:
        return ["--mode", f"{mode[0]}x{mode[1]}"] if mode else ["--auto"]

    if not externals:
        if verbose:
            console.print("No secondary monitor found")
        subprocess.run(["xrandr", "--auto"], check=False)
        for ws in workspace_numbers:
            i3(f"workspace {ws}; move workspace to output {internal}")
    else:
        if wake:
            # A monitor that lost its stream and went to standby only relocks
            # when the output is re-driven. X cannot see that state (it still
            # reports the output as on), so there is nothing to test for and
            # the cycle is unconditional. Dropping every external re-establishes
            # the whole MST topology rather than just one branch of it.
            if verbose:
                console.print(f"Cycling {', '.join(externals)} to force a relock")
            off_cmd = ["xrandr"]
            for name in externals:
                off_cmd += ["--output", name, "--off"]
            subprocess.run(off_cmd, check=False)
            time.sleep(2)

        # Configure every output in a single xrandr call: relative positions are
        # then resolved against the final layout, not a half-applied one.
        cmd = ["xrandr", "--output", internal, "--auto", "--primary"]

        for name in detect_stale_outputs(xr_output):
            if verbose:
                console.print(f"Switching off stale output {name}")
            cmd += ["--output", name, "--off"]

        if main_external:
            if verbose:
                console.print(
                    f"Found main external monitor {main_external} "
                    f"({mode_args(main_mode)[-1]}), placing above {internal}"
                )
            cmd += [
                "--output", main_external, *mode_args(main_mode),
                "--rotate", "normal", "--above", internal,
            ]

        if side_external:
            if verbose:
                console.print(
                    f"Found side monitor {side_external} "
                    f"({mode_args(side_mode)[-1]}), placing left of {internal}"
                )
            cmd += [
                "--output", side_external, *mode_args(side_mode),
                "--rotate", "normal", "--left-of", internal,
            ]

        for name, mode in extra_externals:
            if verbose:
                console.print(f"Found extra monitor {name}, placing right of {internal}")
            cmd += [
                "--output", name, *mode_args(mode),
                "--rotate", "normal", "--right-of", internal,
            ]

        subprocess.run(cmd, check=False)
        subprocess.run(["xrandr", "--dpi", f"96/{internal}"], check=False)

        # Only the pinned workspaces are relocated; the rest keep whatever
        # output they are on. Re-read the list first, because enabling an
        # output makes i3 plant a fresh empty workspace on it and that may
        # be one of the pinned numbers.
        present = set(workspace_numbers) | set(get_workspace_numbers())
        live_outputs = set(externals) | {internal}
        for ws in sorted(present):
            if ws in INTERNAL_WORKSPACES:
                i3(f"workspace {ws}; move workspace to output {internal}")
            elif wake:
                # Blanking the outputs above dumped everything onto the laptop
                # panel, so put manually placed workspaces back where they were.
                out = output_before_by_ws.get(ws)
                if out in live_outputs and out != internal:
                    i3(f"workspace {ws}; move workspace to output {out}")

    # Restore visible workspace on each output where possible, and ensure
    # the originally focused workspace ends up focused again.
    workspaces_after = get_workspaces()
    ws_output_after: dict[int, str] = {}
    for w in workspaces_after:
        out = w.get("output")
        if isinstance(out, str):
            ws_output_after[w["num"]] = out

    # Determine which workspaces we can restore on their original outputs.
    targets: list[int] = []
    for out, ws in visible_before_by_output.items():
        if ws_output_after.get(ws) == out:
            targets.append(ws)

    # Ensure the originally focused workspace is restored last so it is focused.
    if focused_ws is not None:
        if focused_ws in targets:
            targets = [ws for ws in targets if ws != focused_ws]
        targets.append(focused_ws)

    for ws in targets:
        i3(f"workspace number {ws}")

    # Finally, adjust audio sinks
    sound_script = Path.home() / "bin" / "set_sound.py"
    cmd = [str(sound_script)]
    if verbose:
        cmd.append("--verbose")
    if sound_script.exists() and os.access(sound_script, os.X_OK):
        subprocess.run(cmd, check=False)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Automatically configure an external monitor (if present) and move i3 workspaces.",
    )
    parser.add_argument(
        "-l",
        "--list",
        action="store_true",
        help="List available outputs and workspace layout, then exit.",
    )
    parser.add_argument(
        "--no-wake",
        dest="wake",
        action="store_false",
        help="Skip the wake cycle. By default the external outputs are re-driven "
        "first, to wake a monitor that dropped its DisplayPort stream and went "
        "into standby.",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Print additional information while configuring.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> None:
    args = parse_args(argv or sys.argv[1:])

    if args.list:
        list_outputs()
    else:
        configure_monitors(verbose=args.verbose, wake=args.wake)


if __name__ == "__main__":
    main()
