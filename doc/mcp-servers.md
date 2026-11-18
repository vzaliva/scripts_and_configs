# MCP servers for the coding agents

Two coding-agent CLIs run on these machines: Codex, and another one that
keeps its server list in a JSON file in the home directory. Both use the same
MCP servers. This page records how they are installed, why they are installed
as commands instead of being started through `npx` or `uvx`, and how they get
updated. The agents' own configs are not tracked here: they hold an API key
and session state, so this page is the record.

## Servers

| Server | Transport | Installed with | Command the agent runs |
|---|---|---|---|
| `scholar_mcp` | stdio | `npm install -g scholar-mcp` | `scholar-mcp --transport=stdio` |
| `mcp-dblp` | stdio | `uv tool install mcp-dblp` | `mcp-dblp` |
| `lean-lsp` | stdio | `uv tool install lean-lsp-mcp` | `lean-lsp-mcp` |
| `context7` | stdio | `npm install -g @upstash/context7-mcp` | `context7-mcp --api-key <key>` |
| `pldb` | http | nothing to install | `https://pldb.kirancodes.me/mcp` |

`scholar_mcp`, `mcp-dblp` and `pldb` are user-wide. `lean-lsp` and `context7`
are only wanted in the poison-lang project; the other agent scopes them to it,
Codex loads all five everywhere. `context7` needs an API key, which lives only
in the local configs (branzino does not have it). `scholar_mcp` and `mcp-dblp`
carry environment settings (`SCHOLAR_*`, `RESEARCH_ALLOW_*`, `MCP_DBLP_HOME`);
keep them when changing the command.

## Why installed commands and not npx / uvx

- A launcher process stays alive next to every server: `npm exec` costs about
  40 MB, `uv` 10 to 20 MB. Every agent session starts its own copy of every
  server, so on katabasis (7 scholar, 7 dblp, 5 lean-lsp and 3 context7
  instances) the launchers were about 540 of 1830 MB.
- Measured at equal process age (35 s, whole process tree, proportional
  memory): scholar 127 MB with `npx` against 86 MB installed, dblp 61 against
  51 MB. On branzino, two fresh sessions with scholar, dblp and lean-lsp went
  from 12 processes and 603 MB to 6 processes and 395 MB (macOS physical
  footprint). The servers themselves are unchanged.
- `uv` forwards SIGTERM to the server, so killing the process group delivers
  two SIGTERMs about 85 microseconds apart, and lean-lsp-mcp can then spin at
  100% CPU forever (upstream issue oOo0oOo/lean-lsp-mcp#246). Starting the
  server directly removes the forwarded copy.

## Updating

`upd.sh` runs `npm update -g` and `uv tool upgrade --all`, so the four commands
follow the latest releases whenever it runs. That replaces `npx`/`uvx`'s
implicit refresh with a predictable one. A running session keeps the server it
started with: relaunch the session to pick up a new version. `/system-health`
reports outdated global npm packages and uv tools.

## mcp-dblp index

`mcp-dblp` answers from a local SQLite copy of DBLP (3.9 GB, about 8.8 million
publications), not from dblp.org. The prebuilt index is published monthly at
github.com/szeider/mcp-dblp-index. The first start downloads it (1.3 GB
compressed; a tool call waits up to 40 s meanwhile), and a server checks for a
newer release whenever it starts and installs it unless `MCP_DBLP_AUTO_UPDATE=0`.
Papers DBLP added after the release's dump date are not found. On 2026-11-18
the newest release is 2026-11-01, which both hosts have.

| Host | Index home |
|---|---|
| katabasis | `~/.cache/mcp-dblp`, set with `MCP_DBLP_HOME` in both agents' configs |
| branzino | `~/.mcp-dblp`, the default, nothing set |

Every server on a host has to see the same home. A server started without the
variable on katabasis creates an empty `~/.mcp-dblp` and, if it gets as far as
a tool call, downloads a second 4 GB copy there. The servers open the file
read-only and share its pages, so the index does not count once per process.
To check a host: `MCP_DBLP_HOME=<home> mcp-dblp-index status`; `mcp-dblp-index
update` installs a newer release by hand.

## Setting up a host

    npm install -g scholar-mcp @upstash/context7-mcp   # context7 only where the key exists
    uv tool install mcp-dblp
    uv tool install lean-lsp-mcp

The npm global bin directory (`~/.npm-packages/bin` on Ubuntu, Homebrew's bin on
macOS) and `~/.local/bin` must be on the PATH the agents are started with; the
`npx` and `uvx` commands they replace are found through the same directories.
Then change only `command` and `args` of each server entry to the bare command.
For Codex, edit the `[mcp_servers.<name>]` tables in `~/.codex/config.toml` in
place so the startup timeouts and env tables stay. For the other agent use its
`mcp add` command with the same scope as before and pass the environment
settings again, because removing an entry drops them.

## Things to know

- Codex hosts the servers of its terminal clients in a shared app-server
  (`codex app-server --listen unix://`, started by a small daemon), one
  complete set per client conversation. On 2026-11-18 it held two sets, a
  third appeared when another client was started, and after a daemon restart
  it held two sets for the two clients started. `ps` shows them as several
  `scholar-mcp` or `mcp-dblp` processes under the one app-server pid. A
  standalone Codex terminal session runs its own set instead.
- Restarting a Codex client does not restart the app-server, so a changed
  config only reaches the servers started afterwards and the older sets keep
  running with the old one. `codex app-server daemon restart` replaces them
  all, but interrupts running work.
- Stopping an agent that runs `uvx`-launched lean-lsp-mcp servers can leave
  one behind as an orphan spinning at 100% CPU. When the Codex app-server was
  restarted on 2026-11-18, the `uvx`-launched lean-lsp-mcp of the old worker
  was left running at PPID 1 with its `uv` parent gone, and `py-spy` showed
  the stack of oOo0oOo/lean-lsp-mcp#246. The lean-lsp-mcp started directly in
  the same worker exited cleanly. The suspected cause is the second SIGTERM
  that `uv` forwards, which direct launching removes; the signals were not
  captured, so that part is not confirmed.
- Scoping `lean-lsp` and `context7` to one project in Codex would need a
  project `.codex/config.toml`. That file would sit in the project repository,
  cannot hold the context7 key, and is not seen from git worktrees, so it is
  not done.
