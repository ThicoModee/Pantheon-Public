# Macro framework



Pantheon targets Roblox tower defence games. Each macro is a `pantheon-macro` version 1 JSON envelope with a stable `macro-...` identity and a validated definition. It contains no executable code.



The definition contains `version`, `name`, `game`, `mode`, `client`, `targets`, `workflows`, `entry`, and optional `settings`, `runMode`, `icon`, `maps`, and `controls`. The reference client is 800 × 600. `runMode` is `once` or `repeat`.



## Icons



`icon` is one of `pantheon`, `dungeons`, `progressive`, `raids`, `challenges`, or `winter`. The editor previews these original bundled assets and stores only the identifier. Missing icons default to `pantheon`. Unknown identifiers, paths and URLs are rejected. Choosing an icon does not install an old macro.



## Storage and execution



Supplied definitions are `macros/<id>.json`. This release contains none. Authored/imported configurations are under `data/macros/<id>.json` with a revision wrapper. Saved user values are separate under `data/macros/settings/`. Local edits preserve the supplied file.



Each run copies its validated definition and settings into `data/sessions/`, then starts the fixed `Lib/framework/Worker.ahk`. A configuration cannot choose the worker path or supply callbacks. Editing requires Developer mode and stopped state; stale revisions are rejected. Import review does not install or execute a configuration. Imports cannot overwrite an existing identity.



`Schema.ahk` validates action trees, references, enums, coordinates, key names and timing limits. `Settings.ahk` validates controls, options, user values, flag comparisons and numeric references. `Packages.ahk` bounds JSON bytes, nesting and object count before parsing.



`Runner.ahk` executes click-point, click, click-setting, move, walk, scroll, wait, delay, press, key, call, repeat, for-setting, if, retry, until, stop, camera and placements. Loops have execution/time budgets. Conditions combine image presence/absence and settings with AND/OR. Dropdown options map to named points or FindText images; priority loops follow the user's order.



`RobloxEnvironment.ahk` checks the selected Roblox client and foreground focus before input. Held keys are released on cancellation, failure, pause and exit, including after focus loss. The internal bridge checks the parent window, message signature, session token and command allowlist. The UI accepts messages only from Pantheon's local page.



Definitions cannot evaluate expressions or run shell commands, files, scripts or arbitrary network actions. Validation does not guarantee that community actions are desirable: review the steps before running. Account and ownership boundaries remain intact.



## Capture



Coordinates and FindText regions use visible Roblox client pixels with or without a pin. Frozen overlays show a capture banner and selection feedback. Left click selects a coordinate; Escape cancels. Window state is restored afterward and black frames are rejected. Replacing a named target updates every referencing step.



The application ships no legacy scripts, Raids pilot, game-specific settings aliases, sample targets or gameplay sequences. Synthetic test fixtures are excluded from release archives.


Map metadata and typed key overrides are included in the definition. Placement plans, screenshots and global key defaults stay local. The fixed worker receives validated placement and key snapshots; imported definitions cannot supply paths or executable handlers. See [Shared placements](SHARED_PLACEMENTS.md).

Key settings use type `key`, a validated single-key default and a supported `control` identifier. Map metadata can include `parent`, restricted to one top-level parent with no cycles. Sequence steps may include an optional plain-text `name`. The native schema, per-run snapshots and source/session checks remain in force.

Optional `playback` metadata declares targeting cycle order, native auto-upgrade support and priority count. Match-plan actions reference Place IDs, with native validation for missing or out-of-order references. Per-instance targeting/auto state stays inside the run. Legacy coordinate actions migrate only on an unambiguous match.
