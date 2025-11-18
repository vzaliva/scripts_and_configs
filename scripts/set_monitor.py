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
from pathlib import Path

from rich.console import Console
from rich.table import Table

console = Console()

# Workspaces that should live on the external monitor when it is present
EXTERNAL_WORKSPACES = [6, 7, 8, 9, 10]


def run(cmd: list[str]) -> str:
    return subprocess.check_output(cmd, text=True)


def detect_external_output(xr_output: str) -> str | None:
    for line in xr_output.splitlines():
        if re.match(r"^(HDMI-[0-9]+|DisplayPort-[0-9]+(-[0-9]+)?)\s+connected", line):
            return line.split()[0]
    return None


def detect_internal_output(xr_output: str) -> str | None:
    for line in xr_output.splitlines():
        if re.match(r"^(eDP[^ \t]*|LVDS[^ \t]*)\s+connected", line):
            return line.split()[0]
    return None


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
        console.print(f"[red]Error running xrandr:[/red] {e}", file=sys.stderr)
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
        console.print(
            "[red]Error: no internal display (eDP/LVDS) detected[/red]",
            file=sys.stderr,
        )
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


def configure_monitors(verbose: bool) -> None:
    try:
        xr_output = run(["xrandr"])
    except Exception as e:
        console.print(f"[red]Error running xrandr:[/red] {e}", file=sys.stderr)
        raise SystemExit(1)

    external = detect_external_output(xr_output)
    internal = detect_internal_output(xr_output)

    if not internal:
        console.print(
            "[red]Error: no internal display (eDP/LVDS) detected[/red]",
            file=sys.stderr,
        )
        raise SystemExit(1)

    # Snapshot current workspace state so we can restore per-output
    # visible workspaces and the globally focused workspace after moves.
    workspaces_before = get_workspaces()
    workspace_numbers = [w["num"] for w in workspaces_before]
    focused_ws = next((w["num"] for w in workspaces_before if w.get("focused")), None)
    visible_before_by_output: dict[str, int] = {}
    for w in workspaces_before:
        out = w.get("output")
        if w.get("visible") and isinstance(out, str):
            visible_before_by_output[out] = w["num"]

    def i3(cmd: str) -> None:
        subprocess.run(["i3-msg", "-q", cmd], check=False)

    if external is None:
        if verbose:
            console.print("No secondary monitor found")
        subprocess.run(["xrandr", "--auto"], check=False)
        for ws in workspace_numbers:
            i3(f"workspace {ws}; move workspace to output {internal}")
    else:
        if verbose:
            console.print(f"Found external monitor {external}")
        subprocess.run(["xrandr", "--output", external, "--auto"], check=False)
        subprocess.run(
            [
                "xrandr",
                "--output",
                external,
                "-s",
                "3840x2160",
                "--above",
                internal,
                "--rotate",
                "normal",
            ],
            check=False,
        )
        subprocess.run(["xrandr", "--dpi", f"96/{internal}"], check=False)
        subprocess.run(["xrandr", "--output", internal, "--primary"], check=False)

        for ws in workspace_numbers:
            if ws in EXTERNAL_WORKSPACES:
                i3(f"workspace {ws}; move workspace to output {external}")
            else:
                i3(f"workspace {ws}; move workspace to output {internal}")

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
        configure_monitors(verbose=args.verbose)


if __name__ == "__main__":
    main()
