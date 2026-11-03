# Editor controls

## Single-key overrides

In **Controls → In-game controls**, click a key button and press one key. Escape cancels. Combinations such as Ctrl+R are rejected. A modifier such as Shift can be recorded by pressing and releasing it on its own. Save the controls after editing.

In Developer tools, expand **Macro settings** and choose **Key override** from the Add setting control at the bottom. Add one setting, select the in-game action it overrides, name it and record its default key. Players record their preferred key in that setting on the macro dashboard. Each in-game action can have only one override setting.

The old bulk override control has been removed. Existing valid dropdown-based overrides are read as single-key settings; old saved key selections retain their value. Keys remain restricted data, and the host suspends workspace shortcuts while a key is being recorded.

## Setting and sequence blocks

Every setting is a separate block. Click its header to expand or collapse it. Its header shows the setting's name and type. Add setting is below the existing blocks.

Every sequence step also has an expandable header. Give it a Step name to distinguish similar actions. Names are optional plain text and are included in exported configurations. The action type remains visible alongside a custom name.

Drag the grip to move a step vertically within its current list. The moving row and insertion slot show the destination. Nested steps remain in their own branch or loop. Escape cancels the drag. The up/down arrow buttons provide the same reorder operation without dragging. Collapse state follows the step when it moves.

## Match timeline and placement points

Clicking the screenshot always adds a unit placement for the selected slot. It never switches into upgrade, sell or delay painting. Markers retain slot-specific colours. Instance labels use a number for each slot group, adding letters such as `1a`, `1b` and `1c` when the same slot has multiple placements. Slot selectors are compact numbered buttons.

Use **Add action** to open the match-step dialog. Select Place, Reconfigure, Delay, Upgrade or Sell, then configure its applicable fields and click Apply. Existing Start Game steps are edited through the same dialog. Editing or cancelling a draft does not add an action until Apply. Upgrade, Sell and Reconfigure select a placed instance instead of separate coordinates. Delay and linked actions do not add screenshot markers. See [Placed-unit actions](PLACED_UNIT_ACTIONS.md).

## Map acts and modes

Create a top-level map in Developer tools. Click **Add act / mode** on it, enter a name such as Act 1 or Infinite, then add the child. The parent selector can also be used when adding a map.

Placement setup groups these routes beneath an expandable map header. The Default route and each child retain separate teams and action timelines, while all use the parent's screenshot. Importing or capturing a screenshot on a child updates the shared map image. Stage dropdown options can map directly to the desired child route.

Hierarchy is one level deep. A child must reference an existing top-level map. Cycles, orphan children and executable fields are rejected. Screenshots and player placements remain local and are excluded from macro exports and release archives.
