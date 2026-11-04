# Shared camera and placement playback

## Connect a macro sequence

After the sequence confirms that the stage has loaded:

1. Add **Set bird’s-eye camera**. Its defaults zoom in 20 ticks, tilt down, then zoom out 20 ticks. Adjust the values to match the camera used for the map screenshot.
2. Add **Run placement setup**.
3. Choose **Player’s selected setup**, **Shared setup**, a named map, or **Map from dropdown setting**.
4. Choose whether an unconfigured map uses Shared setup or stops with an error.
5. Continue with the macro’s finish-image checks and stage-ending sequence.

Playback returns after the saved match actions. Do not put the whole placement action inside a finish-detection polling loop: that would repeat placement and Start Game inputs.

## Creator maps and stage settings

Enable Developer mode in Settings, then open **Tools → Developer tools**. In **Maps & in-game controls**, enter a map name and click **Add map**. Save the macro. These map names and stable IDs travel with the exported JSON; PNG files and the player's placements do not.

For stage-dependent placement, open the stage dropdown in **Macro settings** and assign a **Placement map** to each option. In the sequence's **Run placement setup** action, select **Map from dropdown setting** and choose that dropdown. Every option needs a map mapping before saving.

Use a consistent Game identifier across macros for the same Roblox game. Player screenshots, routes and teams are shared under `data/placements/<game>/`. Different games must use different identifiers.

## Player setup

Select a macro, then open **Tools → Placement setup**. The editor lists Shared setup and the creator's maps. Players may also add their own named routes for **Player’s selected setup** playback.

Import the creator's 800 × 600 spawn screenshot or capture Roblox with the matching camera. Image import opens a local file picker; configurations cannot download files or choose paths. Keep the same camera position and zoom when running the macro.

Choose a team and a unit slot, then click the screenshot to add a placement. Drag points to move them. Add Upgrade, Sell or Delay actions from **Add action**. Edit each action's delay and upgrade/sell repeat count. Match steps run from top to bottom; drag the grip vertically or use the movement buttons to reorder them.

Edit **Start Game** to choose the game's start button coordinates. **Select coordinates in Roblox** uses a visible frozen capture and left-click selection, even when Developer mode is off. Disable Start Game if the game starts automatically. An enabled Start Game action with untouched 0,0 coordinates stops playback with a clear error before any placement inputs.

**Use Shared setup for all maps** overrides the macro's selected map. Configure Shared setup before enabling it. Otherwise, a named map uses its own selected team, with the creator's chosen fallback. Save before starting; the run receives a separate snapshot.

Playback issues the saved inputs and uses the configured delays. It does not infer money, successful purchases, wave numbers or upgrade costs. Allow sufficient time before placements/upgrades. Creators can use their ordinary image conditions and waits around shared playback for game-specific readiness and ending logic. A universal purchase-confirmation detector is not assumed.

## Share a map image

Captured/imported screenshots are PNGs under `data/placements/<game>/<map-id>.png`. Share the desired image separately from the macro JSON. Players download that image and choose **Import** on the matching map. Do not share the entire `data` directory: it contains private preferences and logs.

## Keys

**Controls → In-game controls** defines the player's defaults: slots 1–6, R to upgrade, X to sell and Q to cancel placement.

Creators add a **Key override** setting at the bottom of Macro settings in Developer tools, select one action and record its default key. Players click that setting’s key button and press their own key. They appear in the macro's dashboard settings and override the player's global defaults for that macro only. Bindings are validated key names, not arbitrary input strings or executable code.

## Validation

Shared playback uses the same Roblox foreground/client checks, loop time limits, key cleanup and session isolation as ordinary sequences. Camera setup releases its held right mouse button on cancellation or failure. Test fixtures verify orchestration and stored data; test the camera and real placements in each target game before sharing a macro.

Map acts and Infinite routes can be added as children of a top-level map. The placement editor groups them under an expandable header; they share the parent screenshot and keep separate timelines. See [Editor controls](EDITOR_CONTROLS.md).

Upgrade, Sell and Reconfigure now reference a specific Place step and follow its current coordinate. Creators can configure targeting order and optional native auto-upgrade support; manual Upgrade presses remain available in all games. See [Placed-unit actions](PLACED_UNIT_ACTIONS.md).

## Pantheon managed upgrades (1.0-beta.2)

For games without native auto upgrading, enable **Pantheon managed upgrades** under Developer tools. This is separate from the game's native auto-upgrade capability.

Capture three FindText targets: a static anchor visible only in the selected-unit panel, the affordable button's fixed background/detail excluding its changing cost text, and Max. Pick the panel close button, then select a small static upgrade-level text or progress-bar region (at most 200 by 80 pixels). Exclude money, damage counters, animated borders, hover highlights and the game scene. Captures must be tested at the same 800 by 600 client size. Do not reuse the same capture for multiple roles.

Choose the check interval, panel response timeout, confirmation timeout, and policy. **Check units in priority order** cycles through eligible units, upgrading affordable ones. **Save for highest priority until finished** stays on the highest-priority unfinished unit until its limit or Max, including when it cannot yet be afforded. Priority 1 is highest.

In Placement setup, edit each **Place** action and set **Pantheon upgrade priority**. Off excludes that placement. **Stop after this many confirmed upgrades** counts additional purchases made by the managed upgrader, not the unit's absolute upgrade level; 0 continues until Max. Manual Upgrade actions remain available and are not included in that count.

Managed upgrading begins after the placement timeline completes and only runs inside **Wait for match result**. Older separate Wait/If result handling does not run it. A sold unit is excluded. The engine opens one unit panel, checks affordability, sends one upgrade key, and requires a stable change in the configured progress region or a Max detection. It then closes the panel before checking Victory or Defeat again. A missing panel, unconfirmed purchase, or failure to close stops with an explicit error. If a result appears during an attempt, the panel is closed before result handling takes over.

This does not read numeric money or cost values. It depends on the game's affordable appearance and a reliable progress region, and needs live game testing. Configuring and testing targets is required before enabling it for players. New exports require Pantheon 1.0-beta.2 or newer.

A small uniform FindText patch is not distinctive across the full game screen. For the affordable target, select the fixed button patch and choose **Search captured area only**. **Test selected target** uses the target’s saved search bounds; the general capture tester searches the whole client. Check that the target matches when affordable and does not match when unaffordable. Grayscale captures do not distinguish hue by itself.

Panel response timeout is a maximum wait for the panel to open or close, not a fixed delay. Static progress uses one baseline sample, then polls every 50 ms after the upgrade key and checks a changed reading again after 50 ms. Minor colour differences remain tolerated. Check interval still controls the rate of unit checks; existing saved values are preserved.

Progress sampling captures the region once and reads its pixels from memory. Successful upgrades proceed without the retry interval; unaffordable checks still use the configured interval. Unit panels close between checks so result images remain visible. Placement uses the saved coordinates directly.

## Placement feedback and waiting for money

In Developer tools, choose **Placement feedback → Configure placement feedback**. Select the unit-panel image and **Not enough money** image, then select the panel close coordinate. Placement-limit and unique-unit-conflict images are optional. Existing managed-upgrade panel settings are copied when starting the configuration, but the configurations are independent afterward. Capture the fixed part of each warning and exclude changing numbers or trailing animation.

Each Place action exposes **Wait for placement up to (seconds)**. Explicit money errors cancel placement mode, inspect the attempted point for an already placed unit, wait for the old warning to disappear and retry the same coordinate within this timeout. No path mapping or coordinate offsets are used. A panel detection confirms success. Unknown failures stop instead of placing repeatedly without evidence.

Detected placement limits or unique-unit conflicts skip that placement. Its linked Upgrade, Sell and Reconfigure actions are skipped immediately, including their delays, and it is excluded from managed upgrading. The reason is logged. Result images from Wait for match result are checked during the placement wait so the timeline can yield to result handling when the match ends. If the money timeout expires, the run stops with an explicit error and releases placement input.
