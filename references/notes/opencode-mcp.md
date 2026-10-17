# opencode MCP — traps, and the agentmemory experiment

Reusable lessons about wiring **any** MCP server into opencode, plus the record
of the agentmemory install we tried and removed on 2026-10-15.

Back to [notes index](README.md) - [docs index](../README.md)

## Trap: restarting the TUI does NOT reconnect MCP

Cost a restart to find. opencode runs a **background server**
(`opencode serve --service`, parented to init) that the TUI connects to.
**That server owns the MCP connections, not the TUI.** Restarting the TUI
re-reads nothing — the long-lived daemon keeps the config and connections it
loaded at *its* start.

Tell-tale sign: `ps` shows an `opencode serve --service` process much older than
your TUI, and the log gets **no new lines** after you restart, because the
daemon is the one logging.

```bash
ps -eo pid,lstart,args | grep "[o]pencode serve"   # note the start time
opencode mcp list                                   # ✗ <server> failed: …
opencode service restart                            # the actual fix
opencode mcp list                                   # ✓ connected
```

`opencode service status|start|stop|get` also exist. Passing `--standalone` to
the TUI bypasses the background service entirely — useful for isolating "is it
my config or the shared daemon?".

## Trap: `npx`-based MCP servers time out on first connect

An MCP entry of `["npx", "-y", "<pkg>"]` is a *different* npx invocation from
whatever else you ran. The first spawn downloads the package and its whole
dependency tree, which can exceed opencode's MCP connect timeout:

```
WARN msg="mcp connect failed" server=<name> status.error="Request timed out"
```

Running the *server* does not warm the *shim*. Warm it once by hand — send any
MCP stdio server an `initialize` request on stdin:

```bash
printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"probe","version":"1.0"}}}' \
  | npx -y <pkg>
```

Measured on the agentmemory shim: **~1.5 s warm**, instant answer. This is also
the fastest way to tell "the server is broken" from "opencode timed out".

For a durable fix, install the shim **locally (not `-g`)** and point the config
at the file, removing npx resolution from the connect path entirely.

## Harmless noise to ignore

`NotFound: FileSystem.access (/tmp/<something>)` — old opencode sessions recorded
with a working directory under `/tmp` that no longer exists (`/tmp` is wiped on
reboot, see [system.md](system.md)). opencode retries the MCP connect for each
stale session on every start and logs the failure. Live sessions are unaffected.

## agentmemory — tried, then removed (2026-10-15)

`rohitg00/agentmemory` (29.5k★, Apache-2.0) — a local memory server that
captures opencode sessions and injects recalled memories into prompts. Installed
via `npx`, wired globally, then **removed the same day at the user's call**
("it won't work"). Nothing remains: no config, no data, no npm cache entries.

**Why it was removed.** It worked, but the value never materialised:
- Capture was excellent and automatic, but **recall was keyword (BM25) only** —
  in keyless mode nothing is distilled into lessons, so it found *text about X*
  rather than *understanding your preferences*. That step needs an LLM key.
- Adding a key (Groq) only unlocked `CONSOLIDATION_ENABLED` and
  `GRAPH_EXTRACTION_ENABLED` in practice — `AGENTMEMORY_AUTO_COMPRESS` (the
  headline "richer summaries" feature) fired on **every** observation and
  immediately exceeded Groq's free tier.
- Neither consolidation nor graph extraction was ever observed producing
  output, so the paid-for complexity bought nothing verifiable.
- It retained a transcript of all work **indefinitely**, with no automatic
  expiry, and deleting an opencode session did **not** delete the stored
  observations — only `mem::evict` / `mem::auto-forget` / `mem::forget` ever
  did, and all manually.

**Worth remembering if it is ever revisited:** auto-injection is **off by
default** (`AGENTMEMORY_INJECT_CONTEXT`), so an out-of-the-box install records
everything and surfaces nothing. Growth measured **~1.5 KB per observation**
(2.0 MB for 1,321 observations in one 52-minute session) → roughly 1 GB/year at
a normal rate, with no automatic pruning.

Full removal took: stop the server, delete `~/.agentmemory`,
`~/.local/share/agentmemory`, the opencode MCP entry, the capture plugin and
the two slash commands, then `opencode service restart`. Reversible and clean.

Last verified: 2026-10-15
