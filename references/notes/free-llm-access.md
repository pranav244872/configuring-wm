# Getting Free LLM Access Without Paying

Verified 2026-10-15 against <https://github.com/tashfeenahmed/freellmapi>
(cloned to `/tmp/opencode/freellmapi`, MIT, actively maintained — last commit
2026-10-15). Read before suggesting any "free LLM" route.

Back to [notes index](README.md) - [docs index](../README.md)

## What freellmapi is

An aggregator that puts **34 free providers / 635 model endpoints** behind one
OpenAI-compatible `/v1`, with a router that fails over on 429 and tracks
per-key usage. It is a **serious project**: 62,089 lines of server code
(excluding tests), 43 built-in platform adapters, 40 DB migrations, and a signed
remote catalog feed. Not something to reimplement for this machine.

**It does not spoof client identity.** Checked specifically: it *reads* the
incoming User-Agent to serve the right client format; it does not forge
outbound headers. Notably its own source records that spoofing was *attempted
and reverted* because it never worked —

> *"sending the OpenCode client headers (#1204, reverted) does not change that.
> The catalog disables the free rows; the provider stays registered for keys on
> OpenCode's paid models."*

## Only 3 of 34 providers are genuinely keyless

| Provider | Anonymous limit | Caveat |
|---|---|---|
| **OVH AI Endpoints** | 2 req/min per IP per model (observed stricter) | first-party; best privacy of the three |
| **AI Horde** | anonymous sentinel key | community volunteer workers, queue-based. **No tools**, `max_tokens >= 16`, no streaming |
| **Kilo Gateway** | 200 req/hr per IP | ⚠️ **"prompts/outputs logged for training"** |

Everything else needs your own key. **The real constraint is how many keys you
have** — a failover router over one key fails exactly like the single key does.

## Keyed but genuinely free, no card

| Provider | Free tier |
|---|---|
| **Groq** | **8,000 tokens/min** (measured 2026-10-15) |
| **Cerebras** | free tier, very fast |
| **Mistral** | free tier |
| **NVIDIA NIM** | free credits |
| **GitHub Models** | free tier, needs a GitHub account |
| **HuggingFace Router** | `router.huggingface.co` free tier |
| **OpenRouter** | `:free` suffix marks zero-cost routes |
| **Google Gemini** | free tier (native adapter, not OpenAI-compat) |
| **Cohere** | free tier |
| **Cloudflare Workers AI** | needs `account_id:token` compound credential |
| **AMD Radeon Cloud** | public models free, no credits consumed |
| **SEA-LION (AI Singapore)** | Google sign-in, **no card, no region wall**, 10 RPM |
| **xKiro** | 5M tokens/day on free models |
| **LLM7** | 100 req/hr; anonymous works for basic models |
| **Requesty** | 200 req/day shared across free models |
| **NavyAI** | 150K tokens/day, 20 RPM |
| **AnyAPI** | 100K tokens/day, $0/no card |
| **Ollama Cloud** | free rows confirmed |

## Dead or avoid

| Provider | Why |
|---|---|
| **OpenCode Zen** | free roster locked to the OpenCode client since 2026-09 → 403 `FreeTierError` on every free model (verified 2026-10-15 against six of them). Paid only |
| **Reka** | no free tier for new accounts since 2026-09, prepaid required |
| **SambaNova** | free tier permanently retired (402 after the trial credit) |
| **Routeway** | requires a browser-style User-Agent (Cloudflare 1010) — i.e. UA spoofing; not something to build in |
| **ModelScope / Baidu / Volcengine / iFlytek** | Chinese real-name auth, region walls |
| **AINative Studio** | upstream's own comment: *"quota treated as unverified"* |
| **OrcaRouter** | *"intentionally unpublished limits"* — untrackable |

## The self-hosting catch

> *"several registered gateways keep their free rosters in the **hosted catalog**
> rather than shipping them to every binary"*
> *"Free installs get the monthly snapshot, so a model reaches them **30 days
> after** it joins the live feed."*

So a self-hosted free install sees a **30-day-stale catalog** and is missing the
newest free models entirely. Turn the feed off with
`CATALOG_SYNC_DISABLED=1` (the literal string `1`, not `true`) if you want zero
outbound calls; the bundled migrations seed models so it still works.

## Groq on this machine

Key was added 2026-10-15 and **the install has since been removed — the key was
exposed in a chat log and should be considered compromised and revoked.**

What the free tier actually does: **8,000 tokens/minute**. Observed failure mode
was a 429 `Rate limit reached … TPM: Limit 8000, Used 7903, Requested 983`,
which then tripped agentmemory's circuit breaker. `MAX_TOKENS` defaults to
4096, and Groq's `openai/gpt-oss-120b` is a *reasoning* model — it returns
**empty content** if `max_tokens` is small, because the budget is consumed by
reasoning tokens. Available chat models at the time: `openai/gpt-oss-120b`,
`openai/gpt-oss-20b`, `qwen/qwen3.8-27b`, `allam-2-7b`.

Last verified: 2026-10-15
