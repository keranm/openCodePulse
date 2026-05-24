# OpenCode Pulse

A lightweight macOS menu bar app that monitors your [OpenCode](https://opencode.ai) usage in real time — cost, tokens, active model, and provider.

**[Download at keranmckenzie.com/utilities](https://keranmckenzie.com/utilities/)**

Requires macOS 14.0 or later. Intel and Apple Silicon.

---

## What it does

OpenCode Pulse sits in your menu bar and shows a circular ring that fills as your daily budget is consumed. Click it to see a popover with:

- **Percentage used** against your configured daily budget
- **Cost today** in USD
- **Active provider and model** (e.g. `anthropic / claude-sonnet-4-6`)
- **Time until reset** (daily, from first request)
- **Progress bar** that shifts green → amber → red as usage climbs
- **Guidance text** summarising whether it's safe to start large tasks

Notifications fire when you cross configurable warning and critical thresholds, and again when the window resets.

---

## How it works

OpenCode Pulse reads directly from `~/.local/share/opencode/` — the same directory OpenCode writes to. No network requests, no account required. It auto-detects the storage format OpenCode is using:

| Format | Path |
|---|---|
| SQLite | `~/.local/share/opencode/opencode.db` |
| JSON messages | `~/.local/share/opencode/storage/message/` |
| Log files | `~/.local/share/opencode/log/` |

Cost is estimated from token counts using current public API pricing for each provider and model. The estimate will differ slightly from your actual bill — use it as a signal, not an invoice.

---

## Settings

Open **Settings** from the menu bar popover (or ⌘,).

| Setting | Description |
|---|---|
| Daily cost budget | Set a USD cap to show percentage-based usage |
| Warning threshold | Notification fires at this percentage (default 80%) |
| Critical threshold | Notification fires at this percentage (default 95%) |
| Enable notifications | Toggle all usage alerts on or off |
| Launch at login | Start automatically when you log in |

---

## Supported providers

Pricing is built in for:

- **Anthropic** — Claude Haiku, Sonnet, Opus
- **OpenAI** — GPT-4o, GPT-4o mini, GPT-4, GPT-4 Turbo, o1, o3-mini
- **Google** — Gemini 2.0 Flash, Gemini 2.0 Pro, Gemini 2.5 Pro
- **Local models** — Qwen, LLaMA, Mistral, CodeLlama (zero estimated cost)

Unknown models fall back to Sonnet pricing.

---

## Privacy

All processing is local. OpenCode Pulse never reads your prompts or conversations — only the token counts and cost metadata that OpenCode records. Nothing leaves your Mac.

---

## Building from source

Requires [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
git clone https://github.com/keranm/openCodePulse
cd openCodePulse
xcodegen generate
open OpenCodePulse.xcodeproj
```

---

## License

MIT
