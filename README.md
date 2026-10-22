# PowerSpaces dock-clearance fix

The dock kept blocking part of my windows. I wanted an option to keep them clear of it, so I had AI code a fix.

**Vibe-coded:** I supplied the idea, requirements, and feedback; AI wrote the implementation. This is an unofficial modification of [PowerSpaces by Sebastian Panman de Wit](https://github.com/sebastianpdw/powerspaces), not the original app or an upstream release.

**Known annoyance:** it sometimes makes moving windows a pain. The fix automatically repositions or resizes windows to keep them out of the dock’s space, so it can fight where you are trying to drag a window. Turn off **Keep windows clear of the dock** if it gets in the way. This is a working personal experiment with rough edges.

## What the fix adds

- A **Keep windows clear of the dock** preference, disabled by default.
- An adjustable window gap (default 4 points; range 0–32 points).
- Work-area calculations for docks at any screen edge, including multiple displays.
- Accessibility-based correction of ordinary visible application windows that overlap the reserved area.
- Geometry and candidate-filter tests in the upstream project’s executable test runner.

The fix skips reservation when the dock is configured to auto-hide or the display is in fullscreen. It requires macOS Accessibility permission to move or resize other apps’ windows. It does not create a native system-wide reserved work area; it corrects windows after they overlap it.

## What is in this repository

- `powerspaces-dock-clearance.patch`: the complete change, including settings, app integration, both new Swift files, and tests.
- `reference/`: the two new Swift files for convenient reading. They are also included in the patch; do not copy them separately when applying it.
- `BASE_REVISION`: the exact upstream revision used for this patch.

This repository contains source changes only. It does not include a compiled app, personal preferences, recordings, or local build files.

## Apply and build

Requires macOS 14 or later and a Swift 6 toolchain (Xcode or compatible Command Line Tools). The patch targets upstream PowerSpaces v1.2.4 at commit `a448cbc29b9315508bcd09c9c2c63dcb0a9fdd58`. Newer upstream versions may need changes.

```sh
git clone https://github.com/AntranigB/powerspaces-dock-clearance.git
TASK_PATCH_DIR="$PWD/powerspaces-dock-clearance"
git clone https://github.com/sebastianpdw/powerspaces.git powerspaces-with-clearance
cd powerspaces-with-clearance
git checkout --detach "$(cat "$TASK_PATCH_DIR/BASE_REVISION")"
git apply --check "$TASK_PATCH_DIR/powerspaces-dock-clearance.patch"
git apply "$TASK_PATCH_DIR/powerspaces-dock-clearance.patch"
swift run spacekit-tests
swift build --product PowerspacesApp
```

See the [upstream getting-started guide](https://github.com/sebastianpdw/powerspaces/blob/main/docs/getting-started.md) for app bundling and running from source. Building this modification does not produce the original developer’s signed/notarized release. In the modified app’s preferences, enable **Keep windows clear of the dock** and adjust the window gap if needed.

## Testing and limitations

The Swift test runner passed 534 assertions with zero failures when preparing this repository on October 22, 2026. Patch application was also checked against a clean copy of the pinned upstream revision, reproducing all nine changed/new files exactly.

The development session included a manual check with Chrome windows on two displays using the default 4-point gap. Other apps and arrangements may behave differently. Automated checks test geometry/filtering and patch application; they do not prove smooth dragging in every app. The window-moving annoyance above remains unresolved.

## Attribution and license

Based on [sebastianpdw/powerspaces](https://github.com/sebastianpdw/powerspaces), copyright 2026 Sebastian Panman de Wit. Original copyright and license notices are retained. This repository distributes the modification under **GPL-3.0-only**, matching the upstream source notices; see [LICENSE](LICENSE).

Dock-clearance modification prepared by Antranig Baghdassarian with AI implementation, October 2026. This is an unofficial personal project and is not endorsed by the upstream author.
