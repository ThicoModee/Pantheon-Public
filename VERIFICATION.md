# Release verification

Checked on Windows with AutoHotkey v2, installed WebView2, Node.js and an isolated headless Edge profile. These are local source/package checks, not a public deployment or full Roblox gameplay certification.

## Passed

- 19 Node tests covering FindText encoding/decoding, bounded regions, developer preferences, action/template creation, safe settings rendering, bundled icons, empty defaults, release cleanup, internal worker and source/session guards.
- Browser smoke test: empty dashboard, Import beside Refresh, developer-mode navigation, empty authoring state, new blank macro, icon preview, coordinate selection dispatch, key action, settings authoring, save/export/import, dashboard icon restoration and start/pause/resume/stop controls. No browser exceptions. The native interface retains hidden browser scrollbars and desktop styling.
- AutoHotkey host/dependency load check.
- Packages fixture: author/import/supply configs, isolated user settings, fixed worker, no overwrite, JSON limits, action/path/unknown-field rejection, bundled icon persistence and external icon rejection, local overrides, unique macro identities.
- Framework fixture: settings-driven clicks and branches, ordered priorities, numeric references, key presses, stop, retries, AND/OR image checks, loop deadlines, cancellation and input cleanup.
- Desktop fixture: independent pin, reference client dimensions, geometry/style/topmost restoration, native worker snapshots, unrelated-window rejection, command allowlist and session token validation.
- Capture fixture: visible and hidden pinned capture, window restoration, black-frame rejection, FindText compatibility, bounded regions and developer gate.
- Actual modifier cleanup on release/pause, including Shift and Control.
- Separate-process mounted input fixture: mouse hit testing, foreground keyboard input, frame-free geometry and restored game window.
- Native WebView2 title-bar fixture: header drag region, non-drag window buttons, maximize and restore geometry.
- Release ZIP integrity and explicit exclusion of personal data, tests, scripts, captures and generated output. One top-level launcher; empty supplied macro directory.

## Scope and limitations

No outdated macro or sample game definition ships. New macros start with an empty Main sequence and no targets or settings. Test-only definitions use synthetic data and are excluded from the download.

There is no complete gameplay macro to validate against a live game in this release. Creators must test their own coordinates, captures, stage-selection mappings and recovery paths. No full game navigation or multi-monitor/DPI gameplay claim is made from fixtures.

Restricted definitions block arbitrary executable/file/network callbacks and external icons. Existing page-source, session, window and input checks remain intact. Users still need to review community actions before running them.

No commits, merges, pushes, staging or publishing were performed.

## Shared placement restoration

Native shared-play fixtures cover creator map merging, per-game shared storage, stage dropdown map mapping, player Shared setup precedence, Start/Place/Upgrade playback, key overrides, explicit missing-map errors, camera zoom order and mouse-button cleanup. Browser checks cover sidebar Developer tools, map/key authoring, screenshot import, point creation, Start Game coordinate picking, canonical save and global key controls. These checks do not certify live camera alignment, available currency or successful purchases in any particular game.

## Editor interaction update

Native editor fixtures verify single-key persistence and legacy value compatibility, action isolation, named steps, valid map groups, shared parent screenshots with separate child timelines, and invalid key/parent/name rejection. Browser tests exercise key recording and modifier rejection, setting collapse state, root and nested pointer dragging with horizontal locking and Escape cancellation, arrow ordering, per-slot colours/counts, place-only screenshot clicks, match dialogs, child-map groups and dashboard key overrides.

## Linked placed-unit actions

Seventeen Node tests and the native linked-placement fixture verify instance labels, moved coordinates, separate instances of one slot, legacy migration, sold/missing references, manual-only games, remembered targeting/auto-upgrade cycles and No change. Browser checks exercise all match tabs, reference dropdowns after point movement, optional auto controls, compact slot buttons, right-aligned dashboard actions, setting backgrounds, padding and corrected text. Existing native worker/session and package checks remain passing. Live game input/cycle alignment is not inferred from fixtures.

For 1.0-beta.1, native regression checks also cover match-result win/defeat recording, runtime startup and completion, timed mouse clicks, minimum-version rejection and beta ordering, plus taskbar visibility/restoration when switching applications. The clean tester archive includes Raids definition data and excludes personal settings and placement plans.
