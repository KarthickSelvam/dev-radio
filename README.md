# dev-radio

Audio feedback for your development workflow. Hear your code — success dings, error buzzes, radio-style voice clips on commits, test results, and Claude Code actions.

## Install

```bash
git clone https://github.com/yourusername/dev-radio.git
cd dev-radio
./install.sh
```

That's it. Claude Code will play sounds automatically on tool completions, errors, and session events.

### Options

```bash
./install.sh --radio            # Add walkie-talkie radio effect (needs sox)
./install.sh --with-git-hooks   # Also add sounds to git commits/push/merge
./install.sh --no-claude        # Skip Claude Code integration
./install.sh --local            # Use from repo dir (don't copy to ~/.dev-radio)
```

## What it does

| Event | Sound |
|-------|-------|
| Claude Code finishes a task | success |
| Bash command fails | fail |
| File edited | neutral |
| Permission prompt | neutral |
| Git commit (feat/fix) | success |
| Git commit (wip/other) | neutral |
| Git merge | success |

Sounds are played asynchronously — they never block your workflow.

## How it works

dev-radio uses [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) — the native event system built into Claude Code. The installer adds hook entries to `~/.claude/settings.json` that trigger sound playback on events like `PostToolUse`, `Stop`, and `Notification`.

No shell wrappers. No aliases. Just native hooks.

## Sound categories

Sounds live in `~/.dev-radio/sounds/` in four folders:

- **success/** — completions, confirmations, victories
- **fail/** — errors, problems, warnings
- **neutral/** — status updates, acknowledgements
- **misc/** — fun sounds, robot voice clips

The repo ships with 115 ready-to-use sound files including radio-processed voice clips. The installer can also generate additional sounds using your system's text-to-speech. Drop your own `.aiff`, `.wav`, or `.mp3` files into any category — they'll be picked up automatically.

## Radio effect

Add a walkie-talkie / military radio filter to voice clips:

```bash
# During install
./install.sh --radio

# Or after install
~/.dev-radio/scripts/add-radio-effect.sh
```

Requires [sox](https://sox.sourceforge.net/) (`brew install sox` / `apt install sox`). Applies bandpass filter + compression + reverb for authentic radio sound.

## Platform support

| | macOS | Linux |
|---|---|---|
| Audio playback | afplay | paplay, pw-play, aplay, mpv, ffplay |
| TTS generation | say | espeak-ng, espeak |
| Notifications | osascript | notify-send |
| Radio effects | sox | sox |

## Git hooks

```bash
# Install globally (new repos get hooks automatically)
./install.sh --with-git-hooks

# Install to a specific repo
cd your-repo
~/.dev-radio/install-git-hooks.sh
```

Hooks fire on commits, pushes, merges, and branch switches.

## Customize

### Add your own sounds

Drop audio files into the category folders:

```bash
cp my-victory-sound.mp3 ~/.dev-radio/sounds/success/
cp error-buzz.wav ~/.dev-radio/sounds/fail/
```

### Generate voice clips

```bash
# macOS
say -v "Daniel" -o ~/.dev-radio/sounds/success/my-clip.aiff "Well done"
say -v "Zarvox" -o ~/.dev-radio/sounds/misc/robot.aiff "Beep boop"

# Linux
espeak-ng -w ~/.dev-radio/sounds/success/my-clip.wav "Well done"
```

### Adjust radio bias

By default, radio-processed versions play 80% of the time. Change it:

```bash
~/.dev-radio/lib/play.sh success --radio-bias 50   # 50/50
~/.dev-radio/lib/play.sh success --radio-bias 0    # never radio
~/.dev-radio/lib/play.sh success --radio-bias 100  # always radio
```

## Uninstall

```bash
~/.dev-radio/uninstall.sh              # Full removal
~/.dev-radio/uninstall.sh --keep-sounds  # Keep your sound files
```

## Project structure

```
dev-radio/
├── install.sh                  # Installer
├── uninstall.sh                # Uninstaller
├── lib/
│   ├── platform.sh             # Cross-platform audio/TTS detection
│   ├── play.sh                 # Random sound player
│   └── events.sh               # Event logger + player + notifier
├── hooks/
│   ├── claude-code.sh          # Claude Code hooks handler
│   └── git/                    # Git hook templates
├── install-git-hooks.sh        # Install hooks to a specific repo
├── sounds/
│   ├── success/                # 115 sounds ship with the repo
│   ├── fail/
│   ├── neutral/
│   └── misc/
├── scripts/
│   ├── generate-sounds.sh      # TTS sound generator
│   ├── add-radio-effect.sh     # Sox radio filter
│   └── demo.sh                 # Demo all sounds
└── examples/
    └── claude-code-hooks.json  # Full hooks config example
```

## License

MIT
