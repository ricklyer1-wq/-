# Chapter 01 Demo Regression Checklist

## Debug Start
- Call `RunManager.start_chapter_01_debug_run()` from the Godot remote inspector, a temporary debug button, or the console.
- Expected log: `[Chapter01Test] start`.
- Expected state: `selected_cultivator_id=fire_cultivator`, `current_chapter_id=chapter_01`, `current_node_id=node_001`, `completed_node_ids=[]`.

## Map Entry
- Open `res://scenes/map/MapScene.tscn`.
- Expected: only the first incomplete node is available.
- Click the available node.
- Expected log: `[Chapter01Test] enter node=<node_id> type=<type>`.

## Combat / Elite / Story Elite
- For `combat`, `elite`, and `story_elite` nodes, click the node from MapScene.
- Expected: BattleScene opens.
- Win the battle manually, or call `simulate_combat_victory()` on BattleScene.
- Expected: CardRewardScene opens before returning to MapScene.
- Pick one card.
- Expected: deck size increases by 1, current node is completed, next node unlocks, and MapScene opens.
- Skip the reward in a separate run.
- Expected: gold increases by 10, current node is completed, next node unlocks, and MapScene opens.

## Event
- Advance to an event node and click it.
- Expected: EventScene opens with title, body, and choices.
- Click one choice.
- Expected: event result applies to RunState, current node completes, next node unlocks, and MapScene opens.

## Shop
- Advance to the shop node and click it.
- Expected: ShopScene opens.
- Test buying one card.
- Expected: gold decreases and deck size increases.
- Test healing if HP is below max.
- Expected: HP increases without exceeding max HP and gold decreases.
- Test removing a card if deck has more than 5 cards.
- Expected: deck size decreases and gold decreases.
- Toggle card packs.
- Expected: `active_card_packs` updates without exceeding `max_active_card_packs`.
- Click leave shop.
- Expected: shop node completes, next node unlocks, and MapScene opens.

## Rest Placeholder
- Advance to the rest node and click it.
- Expected: rest placeholder completes immediately, next node unlocks, and MapScene refreshes.

## Boss Placeholder / Ending
- Advance to `boss_001` and click it.
- Expected logs: `[Map] enter boss node boss_001`, `[Chapter01Test] enter ending`.
- Expected: ChapterEndingScene opens and shows six choice buttons.
- Click `拜入離火宗`.
- Expected: `DebugProfile.unlocked_cultivators` contains `fire_cultivator`, `DebugProfile.unlocked_card_packs` contains `pack_fire`.
- Repeat and click `成為散修`.
- Expected: profile contains `wanderer_cultivator`, `pack_five_elements`, and `pack_all_methods`; duplicate IDs are not added.
- Expected final log: `[Chapter01Test] chapter cleared`.

## Expected Flow Logs
- `[Chapter01Test] start`
- `[Chapter01Test] enter node=node_001 type=combat`
- `[Chapter01Test] enter reward`
- `[Chapter01Test] complete node=node_001`
- `[Chapter01Test] unlock node=node_002`
- `[Chapter01Test] return map`
- `[Chapter01Test] enter ending`
- `[Chapter01Test] chapter cleared`
