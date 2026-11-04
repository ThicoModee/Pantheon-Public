# Authoring a macro



Enable Developer mode at the bottom of Settings, then open Tools → Developer tools in the sidebar.



## Create the macro



Choose New macro. A new definition has one empty Main sequence and no targets or settings. Set its name, game and bundled icon, choose its Starting sequence, and select Run once or Repeat main sequence. The macro gets its own dashboard entry. Definitions for authored macros use the shared runner rather than a generated AHK script.



## Pick coordinates and images



Click coordinate and Move mouse steps have a Select coordinates button. It opens an 800 by 600 frozen Roblox capture with a visible SELECT COORDINATES banner, crosshair and X/Y tooltip. Move over the intended point and left click. The coordinates are written into that step. Escape cancels without changing the step. The game window is restored afterward.



Capture target and Select region in Roblox use a CAPTURE IMAGE banner. Drag a rectangle around the icon or text. The FindText preview is generated from those pixels. Replacing a named image changes every step and setting option referencing it.



Left click selects a point while the coordinate picker is open. Outside that picker, the optional live coordinate viewer uses it to copy its readout.



## Define settings



Open Macro settings in the builder. Controls include toggles, single checkboxes, dropdowns, checkbox lists, ordered priority lists, bounded numbers, and single-key override settings. Give each control a visible name and a default.



A dropdown option may point to a captured image or saved coordinate. Pick click point captures an option's position directly; the target selector can instead use a named FindText image.



For example, make a Stage dropdown with Stage 1 and Stage 2. Pick the click point for each option, then add Click selected setting option and choose Stage. On the dashboard, selecting Stage 2 makes that step use Stage 2's mapped image or position. There is no AHK function to modify.



## Use flags and priorities



An If conditions match, Retry sequence, Repeat until, or Wait for images group can contain settings checks as well as image checks. Add setting / flag selects a control. A Farm portals toggle can be checked against Enabled, with portal actions inside Then and normal progression inside Otherwise.



Conditions support AND/OR groups, image present/absent, scalar equality/inequality, number comparisons, and list contains/does not contain.



For shop priorities, make a Priority list, add the item options, and map each option to its image or click point. Add For each selected item and choose the list. Inside it, Click selected setting option clicks the current item, followed by the purchase/check steps you define. The dashboard's selected order determines iteration order. Checkbox lists use the same mechanism for selected items.



Numeric step fields can bind to bounded Number settings. Only compatible bounds appear. A walking duration setting, for example, must stay within the walking step's permitted duration range. A run uses a validated settings snapshot; settings are not changed under an active sequence.



## Build and run the sequence



Use the ordered step list and inline groups for clicks, walking, scrolling, delays, image waits, branches and retries. Press a key taps a key; Hold a key keeps it down for a duration. Stop macro ends the run normally, including when the main sequence is configured to repeat.



Stage entry template creates a draft of the two clicks, diagonal walk, chamber retry, list scrolling, stage clicks, and load-in wait. Fill the coordinates and two required image captures. The template is a new sequence; choose it as Starting sequence in an authored macro or call it from the appropriate parent sequence.



Save macro, return to the dashboard, select the authored macro and save its settings. Open the correct Roblox game before starting. The same Start/Stop button and key apply to all macros. Focus loss, cancellation and failures release held input. Mouse and keyboard actions are guarded by the selected Roblox client and reference client bounds; scrolling also requires the pointer inside that client.



## Select an icon



Choose Icon beside Macro name. The preview shows the bundled image. The saved definition contains an `icon` identifier: `pantheon`, `dungeons`, `progressive`, `raids`, `challenges` or `winter`. This is preserved when copying, shipping and importing a configuration. Missing icons use Pantheon. External image URLs and file paths are not accepted.



## Share a configuration



Copy macro configuration exports plain JSON to the clipboard. It contains the macro definition, captured FindText patterns, settings controls, defaults, option mappings and starting sequence. It does not include the user's saved selections, private-server link, webhook URL, session token or machine paths. No AHK source, process command or arbitrary function reference can be imported.



Another user chooses Import macro on the dashboard, pastes the text, reviews the name, game, run policy and action summary, then adds it to the dashboard. The imported macro has independent settings. Import cannot overwrite an existing identity. Authoring remains behind Developer mode; installing and running a reviewed configuration does not require enabling the editor.



Definitions are restricted data, not a guarantee that somebody else's in-game actions are desirable. Review the sequences before running community configurations. The runtime does not provide an arbitrary file, network, shell, or script action.



## Ship definitions with Pantheon



Maintainers can save an exported configuration under `macros/<id>.json`, using the exported `macro-...` identity as the filename. The normal package builder includes these files. They are loaded through the same definition validation and fixed worker. Local edits are stored separately under `data/macros` so the supplied definition is preserved.



Authored definitions live in `data/macros/<id>.json`, with user values under `data/macros/settings`. Per-run definitions and settings are copied into `data/sessions`. These personal folders are excluded from releases. Text exchange needs no Pantheon-operated hosting service; short lookup codes and community discovery would require a separate design.



New image captures search the full Roblox client by default. The cropped pixels define the pattern, not its allowed location. For scrolling menus, keep the search area covering the list or use Search full client. Previously captured targets retain their saved search bounds until changed.


## Shared placements and camera

After stage loading, add Set bird’s-eye camera and Run placement setup. Creators can define maps and map dropdown options to them; players import screenshots, place units and set upgrade timing in Tools → Placement setup. See [Shared placements](SHARED_PLACEMENTS.md).

Settings and named sequence steps are collapsible blocks. Add settings at the bottom; drag step grips to reorder within a list, or use the arrow buttons. See [Editor controls](EDITOR_CONTROLS.md) for key recording, match-action dialogs, slot markers and map children.

## Match results

Add **Wait for match result** after Run placement setup. Choose different captured Victory and Defeat images and set the timeout in seconds. Add the appropriate actions inside **On victory** and **On defeat**. This single component waits for either result and executes only the matching branch. A timeout stops with an explicit error.

Use the player's After Victory setting inside On victory to choose Retry, Lobby or Next Act. After Retry or Next Act, wait for both old result images to disappear and then wait for stage readiness. After Lobby, wait for the lobby image so the surrounding match loop can finish. This component does not automatically advance the placement map or detect an unavailable Next Act button.

Sequence and placement timing fields display seconds, including fractional seconds. Existing definition files and numeric setting bindings retain millisecond values for compatibility. Delete sequence removes the selected sequence from the draft; Save macro applies the deletion. Choose a different starting sequence first if needed. Sequences referenced elsewhere cannot be deleted until their references are removed.

## Pantheon version requirements

New exports include `minPantheonVersion`, set to the exporting Pantheon version. Import review, installation and bundled loading reject configurations requiring a newer release. Beta numbers compare numerically, and a stable release is newer than its beta releases. Older configurations without this field remain supported when their definition passes validation. Older Pantheon builds reject the new metadata as an unsupported field instead of silently accepting incompatible components.

## Developer tabs and component guide

Developer tools is divided into **Macro** (identity, starting sequence and player settings), **Sequences** (workflows and steps), **Images** (FindText captures, saved points and bounded tests), **Placement** (maps, game controls and placement/upgrade feedback), **Capture** (region capture, coordinates and raw FindText tools), and **Guide** (searchable component descriptions and examples). The macro selector and bottom save bar apply across tabs. Tabs retain their scroll positions and do not discard drafts. Left/right arrow keys navigate a focused tab list.

The action picker groups common flows, mouse/keyboard actions, conditions/loops, and timing/control actions. Expanded components include an **Example** button that opens the matching guide entry. The guide also explains settings, maps and the game feedback configuration.

Four components simplify common patterns:

- **Click and wait for screen**: click Areas, wait for a unique Raids-menu image, and retry within a fixed attempt limit. If the ready image is already visible, it does not click. Timeout is per attempt, with a separate interval between attempts.
- **Scroll to selected option**: choose a dropdown setting whose options are mapped to FindText images, pick a position inside the list, and set direction, maximum scrolls and timeout. It checks before scrolling and clicks the selected image when found.
- **Click through screens**: repeat an end-screen/reward click until the Lobby button or another destination image is visible. It checks the destination before every click and stops with an error on timeout.
- **Run sequence from setting**: map each dropdown option to an existing sequence. For After Victory, map Retry to a Replay sequence, Return To Lobby to a Lobby sequence, and Next Act to a Next sequence. Those sequences can contain their availability checks and Lobby fallbacks. Every option needs a mapping; recursive sequence calls are rejected.

Existing macros are not rewritten automatically. Their original steps continue to work, so simplify and test one sequence at a time.
