class_name EventManager
extends RefCounted

const DEFAULT_EVENTS_PATH := "res://data/config/events_chapter_01.json"
const FALLBACK_EVENT := {
	"id": "fallback_unknown_event",
	"title": "未知事件",
	"body": "霧氣翻湧，你沒有發現任何異常。",
	"choices": [
		{
			"id": "continue",
			"text": "繼續前進",
			"result": {"type": "none"}
		}
	]
}
const EVENT_ID_ALIASES := {
	"five_element_terrain": "five_elements_crossing",
	"five_element_badlands": "five_elements_crossing",
	"blood_mist_arrival": "blood_mist_descends",
	"jade_slip_resonance": "jade_slip_resonance_unlock",
}

var events: Array[Dictionary] = []
var events_by_id: Dictionary = {}


func load_from_file(path: String = DEFAULT_EVENTS_PATH) -> bool:
	var parsed := _as_dictionary(_load_json(path))
	events.clear()
	events_by_id.clear()
	for item in parsed.get("events", []):
		if item is Dictionary:
			var event: Dictionary = item.duplicate(true)
			events.append(event)
			events_by_id[str(event.get("id", ""))] = event
	return not events.is_empty()


func get_event(event_id: String) -> Dictionary:
	var resolved_id := str(EVENT_ID_ALIASES.get(event_id, event_id))
	var event := _as_dictionary(events_by_id.get(resolved_id, {}))
	if event.is_empty():
		return FALLBACK_EVENT.duplicate(true)
	return event.duplicate(true)


func resolve_event_id(node: Dictionary) -> String:
	var event_id := str(node.get("event_id", ""))
	if event_id.is_empty():
		event_id = str(node.get("story_key", ""))
	if event_id.is_empty():
		event_id = "fallback_unknown_event"
	return str(EVENT_ID_ALIASES.get(event_id, event_id))


func apply_choice(run_state, event: Dictionary, choice: Dictionary) -> void:
	var event_id := str(event.get("id", ""))
	var choice_id := str(choice.get("id", ""))
	var choice_text := str(choice.get("text", choice_id))
	var result := _as_dictionary(choice.get("result", {"type": "none"}))

	run_state.last_event_id = event_id
	run_state.last_event_choice = choice_id if not choice_id.is_empty() else choice_text
	print("[Event] choice selected text=%s" % choice_text)
	_apply_result(run_state, result)


func _apply_result(run_state, result: Dictionary) -> void:
	var result_type := str(result.get("type", "none"))
	var value := int(result.get("value", result.get("amount", 0)))
	if result.has("results"):
		for item in result.get("results", []):
			if item is Dictionary:
				_apply_result(run_state, item)
		return
	match result_type:
		"gain_gold":
			_apply_cost_hp_if_needed(run_state, result)
			var before: int = run_state.gold
			run_state.gold += value
			print("[Event] result gain_gold value=%d" % value)
			print("[Event] gold %d -> %d" % [before, run_state.gold])
		"lose_gold":
			var before_gold: int = run_state.gold
			run_state.gold = max(0, run_state.gold - value)
			print("[Event] result lose_gold value=%d" % value)
			print("[Event] gold %d -> %d" % [before_gold, run_state.gold])
		"heal", "heal_player":
			var before_hp: int = run_state.current_hp
			run_state.current_hp = min(run_state.max_hp, run_state.current_hp + value)
			run_state.player_hp = run_state.current_hp
			print("[Event] result heal_player value=%d" % value)
			print("[Event] hp %d -> %d" % [before_hp, run_state.current_hp])
		"lose_hp":
			var allow_death := bool(result.get("allow_death", false))
			var before_lose: int = run_state.current_hp
			var min_hp := 0 if allow_death else 1
			run_state.current_hp = max(min_hp, run_state.current_hp - value)
			run_state.player_hp = run_state.current_hp
			print("[Event] result lose_hp value=%d" % value)
			print("[Event] hp %d -> %d" % [before_lose, run_state.current_hp])
		"gain_card":
			var card_id := str(result.get("card_id", ""))
			if not card_id.is_empty():
				var before_deck: int = run_state.deck.size()
				run_state.deck.append(card_id)
				print("[Event] result gain_card card_id=%s" % card_id)
				print("[Event] deck_size %d -> %d" % [before_deck, run_state.deck.size()])
		"remove_card_placeholder":
			print("[Event] result remove_card_placeholder")
		"enable_jade_slip_resonance":
			run_state.flags["jade_slip_resonance"] = true
			print("[Event] result enable_jade_slip_resonance")
		"enable_card_pack_for_run":
			var pack_id := str(result.get("card_pack_id", result.get("pack_id", "")))
			if not pack_id.is_empty() and not run_state.active_card_packs.has(pack_id):
				run_state.active_card_packs.append(pack_id)
			print("[Event] result enable_card_pack_for_run pack=%s" % pack_id)
		"set_flag":
			var flag := str(result.get("flag", ""))
			if flag.is_empty():
				print("[Event] unsupported result type=set_flag missing flag")
			else:
				run_state.flags[flag] = true
				if flag == "jade_slip_resonance_unlocked":
					run_state.flags["jade_slip_resonance"] = true
				print("[Event] result set_flag flag=%s" % flag)
		"none":
			print("[Event] result none")
		_:
			push_warning("[Event] unsupported result type=%s TODO" % result_type)
			print("[Event] unsupported result type=%s TODO" % result_type)


func _apply_cost_hp_if_needed(run_state, result: Dictionary) -> void:
	var cost_hp := int(result.get("cost_hp", 0))
	if cost_hp <= 0:
		return
	var before_hp: int = run_state.current_hp
	run_state.current_hp = max(1, run_state.current_hp - cost_hp)
	run_state.player_hp = run_state.current_hp
	print("[Event] result lose_hp value=%d" % cost_hp)
	print("[Event] hp %d -> %d" % [before_hp, run_state.current_hp])


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("[Event] file not found: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[Event] could not open file: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("[Event] could not parse file: %s" % path)
		return {}
	return parsed


func _as_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}
