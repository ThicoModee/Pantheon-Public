# Pantheon interface rules

Inherit the parent repository's authentication, ownership, and contributor-safety requirements.

- Never hand-draw interface icons or invent SVG paths. Select a consistent existing set from https://icon-sets.iconify.design/ and vendor the original assets and license. Current set: Lucide.
- Use Pantheon's original helmet and original per-macro image assets. Do not substitute generic symbols for the macro images.
- Keep product text direct and functional. No slogans, motivational tips, filler setup guides, or conversational advice in the interface.
- Treat this as a desktop application: custom title bar, app-owned tooltips, no browser link-status popup, browser context menu, or visible website scrollbar.
- Keep primary text and controls readable, generally 14–16px. Do not shrink routine controls into tiny labels.
- Selecting a macro opens an in-app workspace. Never launch a separate visible legacy macro window as the hub's workflow.
- Preserve and test native game-window restoration. Keep fixture tests distinct from verified live Roblox gameplay.
- Dashboard is the macro selector and selected macro workspace. Keep Settings and Controls. Placement uses screenshot points, independent teams, and ordered actions; do not reintroduce automatic/spiral placement in hub mode.
- Use native WebView2 non-client regions for title-bar dragging. Preserve hovered DOM elements during snapshot updates.
- Use full NCCALCSIZE frame removal and DWM border suppression; -Caption alone leaves a strip with the resizable frame.
- Pin Roblox as an independent top-level native window over the live view. Do not use SetParent to embed it. Preserve foreground input and restore the original window when unpinned.
- Macro/general forms must use the shared settings allowlist and original registry mappings. Keep URLs/tokens masked and out of logs/packages; connection tests run only when the user clicks their controls.

- Do not add comments to first-party code. Retain third-party license notices and attribution.
- Keep the library fixed under macros. Start and stop share the existing start key and a single dashboard button.
- Use the captured shop images and only valid placement routes for the selected macro, with relevant categories.

- Keep Pantheon.ahk as the single root launcher and internal AHK files, UI, and vendor dependencies under Lib. Clear always-on-top when the pin is hidden, unpinned, or closed.
- Keep card selection, settings, and favourite controls. Omit installed text, descriptions, and tags. Keep settings panels aligned to the same width.

- Match-step dragging stays within the list horizontally and shows the moving row and insertion slot. Only supported macros belong in the catalogue.
- Capture visible Roblox client pixels with or without a pin, suspend pin maintenance during capture, and restore the window afterward. Do not use PrintWindow for game captures or replace a saved screenshot with a black frame.
- Keep developer tools off by default, gated in the host, and compatible with the bundled FindText pattern format. Captures and tests must not click in the game or alter recognition settings automatically.
- Developer mode enables a Pantheon-icon entry under Tools in the sidebar and a dedicated workspace. Keep only the enable toggle in Settings. Native region selection uses a frozen capture overlay, supports Escape, and restores Roblox afterward.
- The new framework targets Roblox tower-defence games. Keep actions typed and validated, do not evaluate expressions or execute imported code, and preserve foreground/client bounds and input release. Keep per-run snapshots separate from local editor drafts and bundled defaults.
- Sequence editing uses readable action names and inline Then/Otherwise, retry, and loop groups. Preserve FindText previews, nested AND/OR/absence conditions, simultaneous movement and optional sprint, and bounded scrolling. Loop timeouts must interrupt held input and release every key. Stage templates are drafts requiring real captures and coordinates, never automatically assigned to a mode.
- Authored/imported macros run as validated data through the fixed internal Worker. Never generate AHK or allow script/process/file/network callbacks from definitions. Keep definition defaults separate from private saved values and per-run snapshots. Preserve strict enum spelling, JSON byte/depth limits, stable IDs and no-overwrite import rules. Stage dropdown mappings, flag checks, ordered priorities and numeric references must be validated before input.
- Coordinate picking is a per-step left-click selection with a visible native capture banner; Escape preserves the previous value. Keep actual key-up cleanup on pause, exit and failure, including when Roblox loses focus or disappears. Supplied configurations belong under macros and receive the same validation as imports.

- The release contains no legacy scripts, game-specific settings links or sample macros. New definitions begin empty. Keep only bundled icon IDs in definitions; reject external icon URLs and file paths. Release packaging excludes tests, generated output and private data.

- Shared placement maps and key overrides are typed definition data. Keep screenshots and player plans local, shared only within the same game ID. Preserve player Shared setup overrides, per-run snapshots, foreground guards and right-button cleanup during camera setup. Do not assume purchase success without game-specific evidence.

- Use key-recording buttons for global in-game controls and typed per-action key settings. Keep workspace hotkeys suspended through key release. Settings and named steps are collapsible; step dragging stays within its own list and supports cancellation. Screenshot painting creates placements only, with slot-specific colours/counts. Child maps share parent screenshots and retain separate timelines; reject cycles and orphan parents.

- Upgrade, Sell and Reconfigure use stable Place IDs, not copied coordinates. Validate ordering and sold/missing references before input. Auto upgrade is a declared game capability; manual upgrade remains supported without it. Targeting and auto state are per placement and use bounded, validated key cycles. Keep compact slot selectors and instance labels, and preserve privacy of player plans.
