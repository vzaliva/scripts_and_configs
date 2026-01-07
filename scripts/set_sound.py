#!/usr/bin/env python3

# Automatically guess and set PulseAudio sound outputs and inputs.
# Dependencies (Ubuntu packages):
#   - python3-pulsectl
#   - python3-rich

import argparse
import sys

import pulsectl

try:
    from rich.console import Console
    from rich.table import Table
except ImportError:  # rich not available, fall back to plain output
    Console = None  # type: ignore
    Table = None  # type: ignore

console = Console() if Console is not None else None


# preferred output sinks (in this order)
# Entries are matched as case-insensitive substrings against either the
# sink description or the sink name, so you can use short names like
# "xm4", "xm5", "jabra", etc.
PREF_SINKS = [
    "Family",
    "WH-1000XM4",
    "jabra",
]

# sinks to hide/exclude when matching PREF_SINKS.
# Same matching rules as PREF_SINKS (case-insensitive substring against
# description or name). These sinks will still appear in --list but will
# not be auto-selected.
HIDE_SINKS = [
    "hdmi",
    "displayport",
]

# preferred input sources (in this order)
# Same matching rules as for sinks. Leave empty if you do not want the
# script to change the default source automatically.
PREF_SOURCES: list[str] = [
    "Webcam C930e",
    "Family 17h/19h HD Audio Controller Digital Microphone",
    "WH-1000XM4",
    "jabra",    
]

# sources to hide/exclude when matching PREF_SOURCES. Same matching rules as
# sinks: entries are case-insensitive substrings against description or
# name. Hidden sources will still appear in --list but will not be
# auto-selected.
HIDE_SOURCES: list[str] = [
    "hdmi",
    "monitor",
    "USB-C dock",
]


def find_sink(pattern, sinks):
    pattern = pattern.lower()
    for sink in sinks:
        if is_hidden_sink(sink):
            continue
        desc = (sink.description or "").lower()
        name = (sink.name or "").lower()
        if pattern in desc or pattern in name:
            return sink
    return None


def is_hidden_sink(sink):
    desc = (sink.description or "").lower()
    name = (sink.name or "").lower()
    for pattern in HIDE_SINKS:
        p = pattern.lower()
        if p and (p in desc or p in name):
            return True
    return False


def find_source(pattern, sources):
    pattern = pattern.lower()
    for source in sources:
        if is_hidden_source(source):
            continue
        desc = (source.description or "").lower()
        name = (source.name or "").lower()
        if pattern in desc or pattern in name:
            return source
    return None


def is_hidden_source(source):
    desc = (source.description or "").lower()
    name = (source.name or "").lower()
    for pattern in HIDE_SOURCES:
        p = pattern.lower()
        if p and (p in desc or p in name):
            return True
    return False

def list_sinks(pulse):
    sinks = pulse.sink_list()
    try:
        default_name = pulse.server_info().default_sink_name
    except pulsectl.PulseError:
        default_name = None

    # First: sinks matching PREF_SINKS (in that order, non-hidden only)
    ordered = []
    seen_names = set()

    def add_sink(s):
        if s is not None and getattr(s, "name", None) not in seen_names:
            ordered.append(s)
            seen_names.add(s.name)

    for pattern in PREF_SINKS:
        sink = find_sink(pattern, sinks)
        add_sink(sink)

    # Second: all other non-hidden sinks
    others = [
        s for s in sinks
        if not is_hidden_sink(s) and getattr(s, "name", None) not in seen_names
    ]

    # Finally: all hidden sinks (disabled for auto-selection)
    hidden_sinks = [
        s for s in sinks
        if is_hidden_sink(s) and getattr(s, "name", None) not in seen_names
    ]

    use_rich = console is not None and Table is not None and sys.stdout.isatty()

    if use_rich:
        def render_group(title, group, style):
            if not group:
                return
            table = Table(title=title, show_header=True, header_style="bold")
            table.add_column("Description", style=style)
            table.add_column("Name", style="cyan")
            table.add_column("Default")
            table.add_column("Hidden")
            for sink in group:
                description = sink.description or "<no description>"
                name = sink.name or "<no name>"
                is_default = default_name == sink.name
                hidden = is_hidden_sink(sink)
                table.add_row(
                    description,
                    name,
                    "yes" if is_default else "",
                    "yes" if hidden else "",
                )
            console.print(table)
            console.print()

        render_group("Preferred sinks", ordered, "bold green")
        render_group("Other sinks", others, "bold cyan")
        render_group("Hidden sinks (HIDE_SINKS)", hidden_sinks, "bold red")
    else:
        def print_group(title, group):
            if not group:
                return
            print(f"{title}:")
            for sink in group:
                description = sink.description or "<no description>"
                name = sink.name or "<no name>"
                is_default = default_name == sink.name
                hidden = is_hidden_sink(sink)
                default_marker = "*" if is_default else " "
                hidden_marker = "-" if hidden else " "
                print(f"  {default_marker}{hidden_marker} {description} [{name}]")
            print()

        print_group("Preferred sinks", ordered)
        print_group("Other sinks", others)
        print_group("Hidden sinks (HIDE_SINKS)", hidden_sinks)


def list_sources(pulse):
    sources = pulse.source_list()
    try:
        default_name = pulse.server_info().default_source_name
    except pulsectl.PulseError:
        default_name = None

    # First: sources matching PREF_SOURCES (in that order, non-hidden only)
    ordered: list = []
    seen_names: set[str] = set()

    def add_source(s):
        if s is not None and getattr(s, "name", None) not in seen_names:
            ordered.append(s)
            seen_names.add(s.name)

    for pattern in PREF_SOURCES:
        source = find_source(pattern, sources)
        add_source(source)

    # Second: all other non-hidden sources
    others = [
        s for s in sources
        if not is_hidden_source(s) and getattr(s, "name", None) not in seen_names
    ]

    # Finally: all hidden sources (disabled for auto-selection)
    hidden_sources = [
        s for s in sources
        if is_hidden_source(s) and getattr(s, "name", None) not in seen_names
    ]

    use_rich = console is not None and Table is not None and sys.stdout.isatty()

    if use_rich:
        def render_group(title, group, style):
            if not group:
                return
            table = Table(title=title, show_header=True, header_style="bold")
            table.add_column("Description", style=style)
            table.add_column("Name", style="cyan")
            table.add_column("Default")
            table.add_column("Hidden")
            for source in group:
                description = source.description or "<no description>"
                name = source.name or "<no name>"
                is_default = default_name == source.name
                hidden = is_hidden_source(source)
                table.add_row(
                    description,
                    name,
                    "yes" if is_default else "",
                    "yes" if hidden else "",
                )
            console.print(table)
            console.print()

        render_group("Preferred sources", ordered, "bold green")
        render_group("Other sources", others, "bold cyan")
        render_group("Hidden sources (HIDE_SOURCES)", hidden_sources, "bold red")
    else:
        def print_group(title, group):
            if not group:
                return
            print(f"{title}:")
            for source in group:
                description = source.description or "<no description>"
                name = source.name or "<no name>"
                is_default = default_name == source.name
                hidden = is_hidden_source(source)
                default_marker = "*" if is_default else " "
                hidden_marker = "-" if hidden else " "
                print(f"  {default_marker}{hidden_marker} {description} [{name}]")
            print()

        print_group("Preferred sources", ordered)
        print_group("Other sources", others)
        print_group("Hidden sources (HIDE_SOURCES)", hidden_sources)


def main():
    parser = argparse.ArgumentParser(
        description="Automatically guess and set preferred PulseAudio sound output."
    )
    parser.add_argument(
        "-l",
        "--list",
        action="store_true",
        help="List available output sinks and exit.",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Print selected sink when setting default.",
    )
    args = parser.parse_args()

    with pulsectl.Pulse("set-sound") as pulse:
        if args.list:
            list_sinks(pulse)
            # separate sinks and sources visually
            if console is not None and sys.stdout.isatty():
                console.print()
            else:
                print()
            list_sources(pulse)
            return

        sinks = pulse.sink_list()
        for sink_description in PREF_SINKS:
            sink = find_sink(sink_description, sinks)
            if sink is not None:
                if args.verbose:
                    print(f"Sound sink set to: {sink.description}")
                pulse.default_set(sink)
                break

        sources = pulse.source_list()
        for source_description in PREF_SOURCES:
            source = find_source(source_description, sources)
            if source is not None:
                if args.verbose:
                    print(f"Sound source set to: {source.description}")
                pulse.default_set(source)
                break


if __name__ == "__main__":
    main()
