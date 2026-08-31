# Chief of Staff (Jarvis)

A local, voice-activated desktop **command center** for talking to your AI
agents. It listens (macOS speech recognition), thinks (your local CLI agents /
a file-bridge), and speaks back (macOS neural voices) — all wrapped in a
sci-fi HUD. Runs on your machine; nothing is deployed.

> Persona: "Jarvis, your Chief of Staff." Rename freely — see Configuration.

![HUD](assets/screenshot.png)

## Features

- **Voice in/out** — on-device macOS speech recognition + natural `say` voices
  (e.g. "Ava (Premium)"). Auto-submits after a short pause; a Stop button cuts
  playback mid-sentence.
- **Sci-fi HUD** — animated center dial that reacts to the voice, a neon
  light-grid background, a live clock, a transcript sidebar, and agent "rings"
  that light up on hand-off.
- **Agent routing** — map spoken phrases to your agents:
  - C-suite advisors (growth, finance, PM/backlog, security, UX, marketing).
  - An "AI Developer" that drives a local coding CLI agent.
  - A design-shop launcher (optional Open Design integration).
- **File-bridge tasks** — an optional JSON mailbox so an external automation
  (e.g. a scheduled assistant) can answer voice requests and cache results for
  instant reads. See `docs/voice-bridge-spec.md`.

## Requirements

- macOS (Apple Silicon; uses native `say`, `afplay`, and `SFSpeechRecognizer`).
- Node.js 18+ and npm.
- Xcode command line tools (to compile the tiny Swift speech helper).
- Optional: a local agent CLI for the "AI Developer"/advisor features.

## Quick start

```bash
npm install

# Build the native speech helper (one time)
swiftc -O -o native/coco-speech native/coco-speech.swift

npm start          # launch in dev
```

Package a distributable app:

```bash
npm run dist       # builds a .app + .dmg into dist/
```

On first launch, allow **Microphone** and **Speech Recognition** when macOS
prompts. Tap the mic (or say the wake word) and speak.

## Configuration

All config is via environment variables (see `.env.example`) — no personal
paths are hardcoded.

| Var | Purpose | Default |
|-----|---------|---------|
| `COS_BRIDGE_ROOT` | File-bridge folder | `~/Documents/CoS-Bridge` |
| `COS_SAY_VOICE` | macOS voice for replies | `Ava (Premium)` |
| `KIRO_CLI` | Path to your agent CLI | `~/.local/bin/kiro-cli` |
| `KIRO_CWD` | Working dir for the CLI | `~` |
| `OD_BIN` | Open Design `od` CLI (optional) | — |

To change the assistant name, wake words, or owner name, edit the constants at
the top of `app.js` (`ASSISTANT_NAME`, `WAKE_WORDS`, `OWNER_NAME`).

## How it works

- `index.html` / `styles.css` / `app.js` — the HUD UI + voice logic (renderer).
- `electron-main.js` — the Electron main process: native TTS (`say`), the
  speech-recognition helper, the file-bridge, the agent CLI relay, and the
  optional Open Design launcher (all via IPC).
- `preload.js` — the secure bridge exposing those capabilities to the UI.
- `native/coco-speech.swift` — a small `SFSpeechRecognizer` helper (compiled).

## Agents

The advisor/agent features shell out to a local agent CLI (configurable via
`KIRO_CLI`). Define your own agents and map trigger phrases in `app.js`
(`AGENT_ALIASES` and the command router in `route()`). Example agent templates
live in `docs/agents/`.

## Privacy

Everything runs locally. The file-bridge folder may contain personal data and
is git-ignored. Do not commit `*-Bridge/` folders, `.env`, or
`product-backlog.json`.

## License

MIT — see [LICENSE](LICENSE).

---

*"Jarvis" is used here only as a personal display name for a local tool.*
