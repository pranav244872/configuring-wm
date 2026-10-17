# opencode websearch — provider selection and the Firecrawl keyless trap

Why every web search answered *"No search results found"* from 2026-10-15
until the fix below on 2026-10-17.

Back to [notes index](README.md) - [docs index](../README.md)

## Root cause

The remembered provider (read-only peek: `websearch:provider` in the `kv`
table of `~/.local/share/opencode/opencode.db`) was **`random`**. Random
latched onto **Firecrawl** — and Firecrawl's anonymous keyless mode is
refused:

```
Anonymous keyless access is unavailable for this request.
```

That refusal arrives as HTTP **200** with the text as a JSON-RPC *result*
(not as a 429), opencode parses it as a result set, finds zero entries and
reports "No search results found". Because it never looks like a 429,
random's failover-to-another-provider never triggers — searches stay
silently empty forever.

## Which providers work keyless (raw probes, 2026-10-17)

| Provider | Endpoint | Keyless |
|---|---|---|
| Tavily | `api.tavily.com/search` + header `X-Tavily-Access-Mode: keyless` | works |
| Exa | `mcp.exa.ai/mcp` (no key parameter) | works |
| Parallel | `search.parallel.ai/mcp` (no auth header) | works |
| TinyFish | `agent.tinyfish.ai/mcp` + header `X-TinyFish-Access-Mode: keyless` | works |
| Firecrawl | `mcp.firecrawl.dev/v2/mcp` | **refused** (needs a key) |

## Fix (applied)

Pin a working provider in `~/.config/opencode/opencode.json`:

```jsonc
"websearch": { "provider": "tavily" }
```

The running background service **re-reads the config** — the next search in
the same session used Tavily and returned results, no `opencode service
restart` needed. Swapping the one line to `exa`, `parallel` or `tinyfish`
works too. Avoid `random`: it can re-latch onto Firecrawl.

Last verified: 2026-10-17
