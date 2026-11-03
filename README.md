# Pantheon 1.0-beta.1

A Windows desktop launcher and visual macro editor for Roblox tower defence games. Macros are validated JSON configurations, run by a shared AutoHotkey engine.

## Run

1. Install AutoHotkey v2, 64-bit, and the Microsoft Edge WebView2 Runtime.
2. Extract the complete download into a writable folder.
3. Run **Pantheon.ahk** in the top-level folder.

This beta includes the Raids macro for testing. Configure your stage settings and placements before running it. The outdated Anime Adventures scripts have been removed. Import a configuration from the dashboard, or enable Developer mode at the bottom of Settings and open **Tools → Developer tools** and choose **New macro**.

## Create and share macros

The editor supports clicks, coordinate picking, key presses and holds, walking, scrolling, delays, FindText checks, conditions, retries, loops and reusable sequences. Create dropdowns, toggles, checkbox lists, numbers and ordered priorities to control those sequences. Tools also contains the screenshot placement editor, with teams and ordered Start Game, Place, Upgrade, Sell and Delay actions.

Choose a bundled icon in the editor. **Copy macro configuration** includes that icon, settings definitions and defaults, targets and sequences. It excludes private saved selections and connection credentials. New exports include the minimum compatible Pantheon version; importing requires that version or newer. Another user can paste it into **Import macro**, review it, and add it to their dashboard.

See [Macro authoring](docs/MACRO_AUTHORING.md) for capture, settings, stage selection and sharing instructions.

## Files

| Location | Purpose |
| --- | --- |
| `Pantheon.ahk` | Run this to start Pantheon |
| `Lib/` | Internal runtime, UI and dependencies |
| `macros/` | Supplied macro JSON files, including Raids |
| `data/` | Personal preferences, authored macros, captures and logs; created on use |
| `docs/` | Authoring and framework reference |

Keep the extracted folders together. Do not include personal files under `data/` in public downloads. Local edits to supplied definitions stay separate under `data/macros`.

## Roblox and controls

Selecting a macro opens its workspace inside Pantheon. Roblox stays an independent window pinned over the live view with normal mouse and keyboard input, using an 800 × 600 client. Unpinning or closing Pantheon restores its original geometry and clears always-on-top. The bottom-right grip resizes Pantheon.

Defaults: F1 positions Roblox, F2 starts/stops, and F4 pauses/resumes. Change them in Controls. Input requires the expected Roblox window to have focus. Losing focus stops input and releases held keys.

Developer coordinate picking uses **Left click** to select the point under the mouse. Image capture shows a visible banner and selection rectangle. Escape cancels. Captures work with or without a pin.

## Scope

Configurations automate the game's UI and movement through supported actions. They cannot supply executable code, file access, network requests or external icons. Review community sequences before running them. Roblox remains responsible for account and private-server access.

Old game-specific scripts and reconnect routines are not included. Define navigation and recovery as sequences. Shared camera and placement playback are available as sequence steps; see [Shared placements](docs/SHARED_PLACEMENTS.md). General connection and webhook preferences remain local; saving them does not add game-specific behaviour to a configuration. Test webhook sends a message only when clicked.

## Checks and packaging

Run `node --test tests/*.test.cjs`, `node tests/browser-smoke.cjs`, and the `.test.ahk` fixtures with AutoHotkey v2. Native fixtures use temporary test windows and are distinct from live gameplay testing. See [VERIFICATION.md](VERIFICATION.md).

`python scripts/package.py` builds `dist/Pantheon.zip` with runtime files, supplied definitions, documentation and required notices. Tests, scripts, private data, logs and screenshots are excluded. Archive integrity is checked locally. The packaging script does not publish releases.

Original Pantheon icons and vendored notices are retained. See [THIRD_PARTY.md](THIRD_PARTY.md).

The editors support key-recording buttons, collapsible named steps/settings, vertical drag reordering, per-slot placement markers and map acts/modes. See [Editor controls](docs/EDITOR_CONTROLS.md).

Upgrade, Sell and Reconfigure are linked to specific placement instances. Native auto upgrade is optional per game; manual upgrades remain available. See [Placed-unit actions](docs/PLACED_UNIT_ACTIONS.md).
