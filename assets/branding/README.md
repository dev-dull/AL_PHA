# planyr — brand assets

Generated app-icon files plus the script that produces them.

## Concept

Lowercase `p` in Patrick Hand, with an accent-teal dot to its right at
the baseline — reads as "p." (monogram + marker shorthand). Sits on
cream paper (`#F5F0E8`) with a faint dot-grid texture. See
[`docs/design/logo-brief.md`](../../docs/design/logo-brief.md) for the
full rationale.

## Files

| Pattern | Purpose |
|---------|---------|
| `planyr-icon-{size}.png` | Combined mark on cream background (light theme) |
| `planyr-icon-dark-{size}.png` | Same mark on warm dark paper |
| `planyr-icon-foreground-{size}.png` | Mark only, transparent background — for Android adaptive icons |
| `planyr-icon-background-{size}.png` | Cream background only — Android adaptive background layer |

Sizes cover iOS, Android, macOS, and web needs: 1024, 512, 256, 192,
180, 167, 152, 144, 128, 120, 108, 96, 87, 80, 76, 72, 64, 60, 58, 48,
40, 32, 29, 20, 16.

## Regenerating

```sh
# One-time venv
python3 -m venv /tmp/oggen
/tmp/oggen/bin/pip install pillow requests

# Every time
/tmp/oggen/bin/python assets/branding/gen_logo.py
```

Tweak `gen_logo.py` (colors, letter size, dot placement) and re-run.
All sizes regenerate together so the mark stays consistent.

## Next steps (manual, not yet done)

The files here are the source-of-truth assets. They still need to be
wired into platform icon slots:

- **iOS:** `ios/Runner/Assets.xcassets/AppIcon.appiconset/` — replace
  the 18 PNGs and keep `Contents.json` matching
- **Android:** `android/app/src/main/res/mipmap-*/ic_launcher.png`
  (legacy) + `mipmap-anydpi-v26/ic_launcher.xml` (adaptive)
- **macOS:** `macos/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Web:** `web/icons/Icon-*.png` and `web/favicon.png`

Easiest path: add [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons)
as a dev dependency, point it at `planyr-icon-1024.png` (or the
foreground / background pair for Android adaptive), and run
`dart run flutter_launcher_icons`.
