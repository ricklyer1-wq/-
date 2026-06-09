class_name StartingCultivatorDatabase
extends RefCounted

const DEFAULT_PATH := "res://data/config/starting_cultivators.json"
const CARDS_PATH := "res://data/generated/cards.json"

var defaults: Dictionary = {}
var cultivators: Array[Dictionary] = []
var cultivators_by_id: Dictionary = {}
var missing_starting_deck_cards: Dictionary = {}


func load_from_file(path: String = DEFAULT_PATH) -> bool:
	var parsed := _as_dictionary(_load_json(path))
	if parsed.is_empty():
		return false

	defaults = _as_dictionary(parsed.get("defaults", {}))
	cultivators.clear()
	cultivators_by_id.clear()

	for item in parsed.get("cultivators", []):
		if not item is Dictionary:
			continue
		var cultivator := _normalize_cultivator(item)
		cultivators.append(cultivator)
		cultivators_by_id[cultivator["id"]] = cultivator

	validate_starting_decks()
	return true


func all() -> Array[Dictionary]:
	return cultivators.duplicate(true)


func has_cultivator(cultivator_id: String) -> bool:
	return cultivators_by_id.has(cultivator_id)


func get_cultivator(cultivator_id: String) -> Dictionary:
	return _as_dictionary(cultivators_by_id.get(cultivator_id, {})).duplicate(true)


func get_default_cultivator_id(fallback_id: String = "") -> String:
	if not fallback_id.is_empty() and has_cultivator(fallback_id):
		return fallback_id
	if not cultivators.is_empty():
		return str(cultivators[0].get("id", ""))
	return ""


func validate_starting_decks() -> bool:
	missing_starting_deck_cards.clear()
	var valid_card_ids := _load_card_id_set()
	if valid_card_ids.is_empty():
		return false

	for cultivator in cultivators:
		var missing: Array[String] = []
		for card_id in cultivator.get("starting_deck", []):
			if not valid_card_ids.has(card_id):
				missing.append(card_id)
		if not missing.is_empty():
			var cultivator_id := str(cultivator.get("id", ""))
			missing_starting_deck_cards[cultivator_id] = missing
			push_warning("Starting deck has missing cards for %s: %s" % [cultivator_id, str(missing)])

	return missing_starting_deck_cards.is_empty()


func _normalize_cultivator(source: Dictionary) -> Dictionary:
	var starting_hp := int(source.get("starting_hp", 1))
	return {
		"id": str(source.get("id", "")),
		"name": str(source.get("name", source.get("id", ""))),
		"display_element": str(source.get("display_element", source.get("main_element", ""))),
		"main_element": str(source.get("main_element", "")),
		"starting_hp": starting_hp,
		"starting_max_hp": int(source.get("starting_max_hp", starting_hp)),
		"starting_gold": int(source.get("starting_gold", defaults.get("starting_gold", 0))),
		"starting_deck": _to_string_array(source.get("starting_deck", [])),
		"recommended_card_packs": _to_string_array(source.get("recommended_card_packs", [])),
		"max_active_card_packs_bonus": int(source.get("max_active_card_packs_bonus", 0)),
	}


func _load_card_id_set() -> Dictionary:
	var card_ids := {}
	var cards: Variant = _load_json(CARDS_PATH)
	if not cards is Array:
		push_warning("Could not validate starting decks because cards.json was not an array.")
		return card_ids

	for card in cards:
		if card is Dictionary and card.has("id"):
			card_ids[str(card["id"])] = true
	return card_ids


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("JSON file not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open JSON file: %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("Could not parse JSON file: %s" % path)
		return {}
	return parsed


func _to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result


func _as_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}
