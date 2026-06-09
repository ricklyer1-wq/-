class_name RunState
extends RefCounted

var selected_cultivator_id := ""
var main_element := ""
var current_chapter_id := ""
var current_node_id := ""
var completed_node_ids: Array[String] = []
var deck: Array[String] = []
var draw_pile: Array[String] = []
var discard_pile: Array[String] = []
var exhaust_pile: Array[String] = []
var current_hp := 0
var max_hp := 0
var player_hp := 0
var player_max_hp := 0
var gold := 0
var relics: Array[String] = []
var active_card_packs: Array[String] = []
var recommended_card_packs: Array[String] = []
var unlocked_card_packs_snapshot: Array[String] = []
var pending_card_reward: Dictionary = {}
var last_reward_choice := ""
var last_event_id := ""
var last_event_choice := ""
var cleared_chapter_id := ""
var last_chapter_ending_choice := ""
var flags: Dictionary = {}
var battle_return_flow := ""
var battle_return_scene := ""


func reset() -> void:
	selected_cultivator_id = ""
	main_element = ""
	current_chapter_id = ""
	current_node_id = ""
	completed_node_ids.clear()
	deck.clear()
	draw_pile.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	current_hp = 0
	max_hp = 0
	player_hp = 0
	player_max_hp = 0
	gold = 0
	relics.clear()
	active_card_packs.clear()
	recommended_card_packs.clear()
	unlocked_card_packs_snapshot.clear()
	pending_card_reward.clear()
	last_reward_choice = ""
	last_event_id = ""
	last_event_choice = ""
	cleared_chapter_id = ""
	last_chapter_ending_choice = ""
	flags.clear()
	battle_return_flow = ""
	battle_return_scene = ""


func setup_from_cultivator(cultivator: Dictionary, card_packs: Array, chapter_id: String, node_id: String) -> void:
	reset()
	selected_cultivator_id = str(cultivator.get("id", ""))
	main_element = str(cultivator.get("main_element", ""))
	current_chapter_id = chapter_id
	current_node_id = node_id
	max_hp = int(cultivator.get("starting_max_hp", cultivator.get("starting_hp", 1)))
	current_hp = int(cultivator.get("starting_hp", max_hp))
	player_max_hp = max_hp
	player_hp = current_hp
	gold = int(cultivator.get("starting_gold", 0))
	deck = _to_string_array(cultivator.get("starting_deck", []))
	print("[StartingDeck] cultivator=%s deck_size=%d" % [selected_cultivator_id, deck.size()])
	print("[StartingDeck] card_ids=%s" % JSON.stringify(deck))
	active_card_packs = _to_string_array(card_packs)
	recommended_card_packs = _to_string_array(cultivator.get("recommended_card_packs", []))
	unlocked_card_packs_snapshot = active_card_packs.duplicate()


func mark_current_node_completed() -> void:
	if current_node_id.is_empty():
		return
	if not completed_node_ids.has(current_node_id):
		completed_node_ids.append(current_node_id)


func set_battle_return(flow_state: String, scene_path: String) -> void:
	battle_return_flow = flow_state
	battle_return_scene = scene_path


func clear_battle_return() -> void:
	battle_return_flow = ""
	battle_return_scene = ""


func to_dictionary() -> Dictionary:
	return {
		"selected_cultivator_id": selected_cultivator_id,
		"main_element": main_element,
		"current_chapter_id": current_chapter_id,
		"current_node_id": current_node_id,
		"completed_node_ids": completed_node_ids.duplicate(),
		"deck": deck.duplicate(),
		"draw_pile": draw_pile.duplicate(),
		"discard_pile": discard_pile.duplicate(),
		"exhaust_pile": exhaust_pile.duplicate(),
		"current_hp": current_hp,
		"max_hp": max_hp,
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"gold": gold,
		"relics": relics.duplicate(),
		"active_card_packs": active_card_packs.duplicate(),
		"recommended_card_packs": recommended_card_packs.duplicate(),
		"unlocked_card_packs_snapshot": unlocked_card_packs_snapshot.duplicate(),
		"pending_card_reward": pending_card_reward.duplicate(true),
		"last_reward_choice": last_reward_choice,
		"last_event_id": last_event_id,
		"last_event_choice": last_event_choice,
		"cleared_chapter_id": cleared_chapter_id,
		"last_chapter_ending_choice": last_chapter_ending_choice,
		"flags": flags.duplicate(true),
		"battle_return_flow": battle_return_flow,
		"battle_return_scene": battle_return_scene,
	}


func from_dictionary(data: Dictionary) -> void:
	selected_cultivator_id = str(data.get("selected_cultivator_id", ""))
	main_element = str(data.get("main_element", ""))
	current_chapter_id = str(data.get("current_chapter_id", ""))
	current_node_id = str(data.get("current_node_id", ""))
	completed_node_ids = _to_string_array(data.get("completed_node_ids", []))
	deck = _to_string_array(data.get("deck", []))
	draw_pile = _to_string_array(data.get("draw_pile", []))
	discard_pile = _to_string_array(data.get("discard_pile", []))
	exhaust_pile = _to_string_array(data.get("exhaust_pile", []))
	current_hp = int(data.get("current_hp", data.get("player_hp", 0)))
	max_hp = int(data.get("max_hp", data.get("player_max_hp", 0)))
	player_hp = current_hp
	player_max_hp = max_hp
	gold = int(data.get("gold", 0))
	relics = _to_string_array(data.get("relics", []))
	active_card_packs = _to_string_array(data.get("active_card_packs", []))
	recommended_card_packs = _to_string_array(data.get("recommended_card_packs", []))
	unlocked_card_packs_snapshot = _to_string_array(data.get("unlocked_card_packs_snapshot", []))
	pending_card_reward = data.get("pending_card_reward", {}).duplicate(true)
	last_reward_choice = str(data.get("last_reward_choice", ""))
	last_event_id = str(data.get("last_event_id", ""))
	last_event_choice = str(data.get("last_event_choice", ""))
	cleared_chapter_id = str(data.get("cleared_chapter_id", ""))
	last_chapter_ending_choice = str(data.get("last_chapter_ending_choice", ""))
	flags = data.get("flags", {}).duplicate(true)
	battle_return_flow = str(data.get("battle_return_flow", ""))
	battle_return_scene = str(data.get("battle_return_scene", ""))


func _to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result
