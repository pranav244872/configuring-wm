# hermes — model providers

`hermes-agent-bin` 0.22.2-1 (AUR via paru, installed 2026-10-15). Config lives
in `~/.hermes/config.yaml` (`model.provider`, `model.default`, `model.base_url`)
plus `~/.hermes/.env`; `hermes doctor` has an **OpenCode Go** probe.

Back to [notes index](README.md) - [package management](../package-management.md)

## Native `opencode-go` provider

Hermes ships an `opencode-go` provider (`hermes_cli/providers.py`), so
opencode's model gateway works in it **without any spoofing or proxy**:

- key env var `OPENCODE_GO_API_KEY`, base URL override `OPENCODE_GO_BASE_URL`
- `agent/opencode_affinity.py` sends `x-opencode-session` on **every** request —
  opencode's Go endpoint rejects requests without it — plus its own user agent,
  which is exactly what opencode's docs ask third-party agents to do
- opencode's docs list **Hermes as a validated client** for the Go subscription
- `/model` and `-m/--model` switch models, same UX as opencode's picker
- custom providers do live `GET <base_url>/models` discovery

## What does not work

opencode's **free tier** (`https://opencode.ai/inference/v1`) returns
`FreeTierError` for anything outside the opencode client. Verified directly
against six models: `big-pickle`, `space-bunny-free`,
`deepseek-v4.1-flash-free`, `nemotron-3.5-lightning-free`,
`mimo-v2.6-flash-free`, `cat-jam-free`. `/models` listing is public (HTTP 200),
which is why the models look available until you call them.

The free models (`cat-jam-free`, `step-5-preview-free`,
`longcat-2.5-preview-free`) are reachable through **Go**
(`https://opencode.ai/inference/go/v1`) instead, which needs a $10/mo
subscription.

Last verified: 2026-10-15
