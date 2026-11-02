# Antigravity Relay (OpenAI-compatible gateway)

Local gateway that turns the Google Antigravity IDE's Cloud Code backend into an
OpenAI-compatible API at **`http://localhost:8081`**. Source: private repo
`pranav244872/antigravity-relay`, clone at `~/del/antigravity-relay` (Docker).

Back to [notes index](README.md) - [docs index](../README.md)

## What runs where

| Piece | Location |
|---|---|
| container | `antigravity-relay` (`docker compose`, `restart: unless-stopped`) |
| port | `8081` (host) → `8081` (container) |
| credentials | `~/del/antigravity-relay/data/credentials.json` (root, `0600`, gitignored) |
| dashboard / playground | `http://localhost:8081/` |
| API base URL for clients | `http://localhost:8081/v1` (any `Authorization: Bearer …`) |

The Docker daemon is **disabled at boot** (deliberate, see
[package-management.md](../package-management.md)), so the relay only runs after
`sudo systemctl start docker` — the container then restarts with the daemon
because of its restart policy. `pranav` is not in the `docker` group; every
`docker`/`docker compose` call here uses `sudo`.

## Setup as done (2026-11-02)

```bash
sudo pacman -S --needed docker-buildx      # BuildKit cache mounts in the Dockerfile
sudo systemctl start docker
cd ~/del/antigravity-relay
sudo docker compose build                  # BuildKit
sudo docker compose up -d
curl -s http://localhost:8081/health       # {"authenticated":false,...}
```

Then authenticate once (loopback OAuth, browser must reach `localhost:8081`):

```bash
xdg-open http://localhost:8081/auth/login  # Google consent → /auth/callback
curl -s http://localhost:8081/health       # authenticated:true
```

`/auth/token` accepts a refresh token instead, `/auth/logout` clears it.

## Model policy: Flash 3.8 only

The gateway intentionally exposes **only the Gemini 3.8 Flash thinking tiers**
(local policy, 2026-11-02):

| Model ID | Thinking budget |
|---|---|
| `gemini-3.8-flash-high` | `-1` (dynamic) |
| `gemini-3.8-flash-medium` | `4096` |
| `gemini-3.8-flash-low` | `1024` |

Anything else returns `404 model_not_found`. This is narrower than the IDE's own
catalogue on purpose; the full mirror described in the repo's
`AGENT_MAINTENANCE_GUIDE.md` is the reference for discovering/adding models.

## Updating (run the repo's runbook)

The repo carries `AGENT_MAINTENANCE_GUIDE.md` — run its steps whenever the
Antigravity IDE updates or models change:

1. `ps aux | grep language_server` → the `--standalone` process, its
   `--csrf_token`, and `--override_ide_version`.
2. `ss -tlnp | grep <pid>` → the HTTPS port (UI/RPC).
3. POST `GetCascadeModelConfigData` to
   `/exa.language_server_pb.LanguageServerService/GetCascadeModelConfigData`
   with `X-Codeium-Csrf-Token` → live `clientModelConfigs` (`modelId`, label,
   `modelOrAlias.model`, `disabled`).
4. Fetch `https://127.0.0.1:<port>/main.js` and confirm the tier regex.
5. Update `models.py`, `server.py` (`RELIABLE_MODEL_IDS`), `client.py`
   (`x-client-version`), `dashboard.html`, `README.md`, guide; rebuild; smoke-test.

### IDE 2.28.1 findings (2026-11-02)

- Live UI: `gemini-3.8-flash-{high,medium,low}`, `claude-sonnet-4-6`,
  `claude-opus-4-6-thinking`, `gpt-oss-120b-medium`, plus
  `gemini-4-argon-disabled` with `"disabled": true` (Unavailable, Ultra/paid Pro
  only) — **not usable, not exposed**.
- 3.7 Flash, 3.6 Flash and 3.1 Pro were **removed from the UI**; their code
  paths were deleted from this relay.
- Standalone server flags now include `--https_server_port 0` (dynamic),
  `--app_data_dir antigravity`, `--cloud_code_endpoint
  https://daily-cloudcode-pa.googleapis.com`, `--host_bridge_*`; the RPC port in
  this session was `38029` (the language-server log's "Local:" URL), while
  `42503` was plain HTTP and `42781` the Electron devtools port.
- `x-client-version` bumped `2.22.0` → `2.28.1`.

## Verification

```bash
curl -s http://localhost:8081/v1/models | jq '.data | length'       # 3
curl -s http://localhost:8081/v1/models | jq -r '.data[].id'
# 404 for an excluded model:
curl -s http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" -H "Authorization: Bearer dummy" \
  -d '{"model":"claude-sonnet-4-6","messages":[{"role":"user","content":"hi"}]}' | jq '.detail.error.code'
```

Live results 2026-11-02: all three tiers answered `"Say 1"` in ~4 s; a math
prompt on `-high` returned `reasoning_content` (246 chars) and
`usage.reasoning_tokens` (365). Streaming deltas are exposed as
`delta.reasoning_content`.

## Traps

- `docker buildx` missing made the Dockerfile fail with *"the --mount option
  requires BuildKit"* — install `docker-buildx`, no Dockerfile change needed.
- Credentials are written by the container as **root**; read/back them up with
  `sudo`. Losing `data/credentials.json` means redoing the browser consent.
- Port `8081` is fixed in `docker-compose.yml` (`PORT` env). The cheatsheet
  overlay (Wayland branch) expects exactly this URL.
- MCP/Context7 is opt-in (`ENABLE_MCP=false` globally, or per request with
  `X-Enable-MCP: true`); the container starts `npx @upstash/context7-mcp` at
  boot, which takes ~12 s before `/health` shows ready.
- The host bridge (Electron) and the language server must be running for model
  discovery only; the relay talks to Google directly after OAuth.
