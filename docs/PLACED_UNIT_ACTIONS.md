# Placed-unit actions

Upgrade, Sell and Reconfigure reference a particular Place step by its stable ID. Choose the instance from **Placed unit**. Its coordinate is read from that Place step whenever the timeline is saved or played, so moving the placement also moves all its linked actions.

The numeric label follows the order in which slots first appear. For example, the first placement may be `1 · Unit 3 at (63, 334)`. If that slot is placed more than once, its instances become `1a`, `1b`, `1c`, and so on in placement order. The next distinct slot gets group 2. Labels can change when the timeline is reordered; references continue to use IDs.

Only units placed earlier in the current timeline and not already sold are offered for a new linked action. Saving rejects missing references, actions before placement, and reuse after Sell. Deleting a placement also removes its linked actions. Older coordinate-based actions are linked automatically only when their slot and coordinate identify exactly one Place step; ambiguous entries must be selected explicitly.

## Match actions

- **Place:** select the slot and coordinate, targeting priority, and—when supported—auto-upgrade priority.
- **Reconfigure:** select a placed instance, optionally change its targeting priority, and select No change, Off or an auto-upgrade priority.
- **Delay:** enter the wait in milliseconds.
- **Upgrade:** select the instance and the number of manual Upgrade Unit presses.
- **Sell:** select the instance. Playback selects its current coordinate and sends one Sell press.

Screenshot clicks add Place steps only. The compact slot buttons choose slots 1–6; coloured instance markers distinguish the placed units.

## Game capabilities and keys

In Developer tools, **Placement controls** defines the targeting cycle order. Enter the priorities in the order the game cycles through them, starting with the state of a newly placed unit. The global Change targeting priority key is configurable in Controls and can be overridden by a Key override setting.

Enable **Game supports auto upgrade** only when the game has the corresponding per-unit control. Set its number of priority levels. One level is shown as On/Off; multiple levels are shown as Priority 1, Priority 2, etc., plus Off. The cycle is Off → Priority 1 → … → Off. Configure the Auto upgrade key in Controls or a macro Key override setting.

Playback remembers targeting and auto-upgrade states independently for each placement and cycles forward only as many key presses as needed. No change preserves the remembered state. Games without native auto upgrade hide these fields, reject non-Off auto-upgrade requests and continue to support manual Upgrade steps.

The state model assumes fresh placements and the creator's configured cycle order. Manual changes in Roblox outside this timeline cannot be inferred. Purchase success, available money and upgrade costs still require game-specific image checks or suitable delays; the shared engine does not infer them from a key press.

Configurations remain validated data. They cannot supply executable code, file paths or arbitrary input syntax.
