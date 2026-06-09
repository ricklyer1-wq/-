class_name RewardManager
extends RefCounted

const CONFIG_PATH := "res://data/config/card_reward_weights_toggleable.json"
const FIVE_ELEMENTS := ["metal", "wood", "water", "fire", "earth"]
const ALL_ELEMENTS := ["metal", "wood", "water", "fire", "earth", "soul", "weapon"]
const EXCLUDED_RARITIES := ["BASIC", "TOKEN", "STATUS"]
const RARITY_GROUPS := {
	"common": ["N"],
	"uncommon": ["R"],
	"rare": ["SR"],
}

var config: Dictionary = {}
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()
	config = _as_dictionary(_load_json(CONFIG_PATH))


func generate_card_reward(run_state, reward_type: String) -> Array[CardData]:
	if GameData.cards.is_empty():
		GameData.load_all()

	var resolved_reward_type := _normalize_reward_type(reward_type)
	var main_element := str(run_state.main_element) if run_state != null else ""
	var active_packs: Array[String] = _to_string_array(run_state.active_card_packs if run_state != null else [])
	var choices := _card_choices()
	var picked_ids: Array[String] = []
	var picked_cards: Array[CardData] = []

	print("[Reward] generate reward_type=%s main_element=%s active_packs=%s" % [
		resolved_reward_type,
		main_element,
		JSON.stringify(active_packs),
	])

	for slot_index in range(choices):
		var card_record := _pick_card_for_slot(resolved_reward_type, main_element, active_packs, slot_index, picked_ids)
		if card_record.is_empty():
			push_warning("[Reward] Could not generate option %d." % (slot_index + 1))
			continue
		var card_id := str(card_record.get("id", ""))
		picked_ids.append(card_id)
		picked_cards.append(_to_card_data(card_record))
		print("[Reward] option %d card=%s rarity=%s element=%s" % [
			slot_index + 1,
			card_id,
			str(card_record.get("rarity", "")),
			_card_element(card_record),
		])

	if picked_cards.size() < choices:
		push_warning("[Reward] Only generated %d/%d card rewards." % [picked_cards.size(), choices])
	return picked_cards


func _pick_card_for_slot(reward_type: String, main_element: String, active_packs: Array[String], slot_index: int, picked_ids: Array[String]) -> Dictionary:
	var pool_weights := _slot_pool_weights(reward_type, slot_index)
	pool_weights = _apply_pack_pool_bias(pool_weights, main_element, active_packs)
	var pool_type := _roll_weighted_key(pool_weights)
	var rarity_values := _roll_rarity_values(reward_type, active_packs)
	print("[Reward] rarity_roll result=%s" % (str(rarity_values[0]) if not rarity_values.is_empty() else ""))
	print("[Reward] selected pool=%s element=%s" % [pool_type, main_element])
	var fallback_order := _fallback_order()

	var pool_candidates: Array[String] = []
	pool_candidates.append(pool_type)
	for fallback in fallback_order:
		if not pool_candidates.has(fallback):
			pool_candidates.append(fallback)

	for candidate_pool in pool_candidates:
		var elements := _elements_for_pool(candidate_pool, main_element, active_packs)
		var cards := _filter_cards(elements, rarity_values, picked_ids)
		if not cards.is_empty():
			return cards[rng.randi_range(0, cards.size() - 1)]

	var all_cards := _filter_cards([], rarity_values, picked_ids)
	if not all_cards.is_empty():
		return all_cards[rng.randi_range(0, all_cards.size() - 1)]
	return {}


func _slot_pool_weights(reward_type: String, slot_index: int) -> Dictionary:
	var slot_rules := _as_dictionary(config.get("slot_rules", {}))
	if bool(slot_rules.get("enabled", false)):
		var rules: Array = slot_rules.get(reward_type, [])
		if slot_index < rules.size() and rules[slot_index] is Dictionary:
			return _as_dictionary(rules[slot_index].get("pool_weights", {})).duplicate(true)

	var by_type := _as_dictionary(config.get("pool_weights_by_reward_type", {}))
	var weights := _as_dictionary(by_type.get(reward_type, {})).duplicate(true)
	if weights.is_empty():
		weights = {
			"main_element": 45,
			"neutral": 25,
			"related_elements": 20,
			"random_non_main": 10,
		}
	return weights


func _apply_pack_pool_bias(pool_weights: Dictionary, main_element: String, active_packs: Array[String]) -> Dictionary:
	var result := pool_weights.duplicate(true)
	var pack_elements := _active_pack_elements(active_packs)
	if pack_elements.is_empty():
		return result

	if pack_elements.has(main_element):
		result["main_element"] = float(result.get("main_element", 0)) * 1.45 + 15.0
	if not _related_pack_elements(main_element, active_packs).is_empty():
		result["related_elements"] = float(result.get("related_elements", 0)) * 1.35 + 10.0
	result["neutral"] = float(result.get("neutral", 0)) * 0.9
	result["random_non_main"] = float(result.get("random_non_main", 0)) * 0.8
	return result


func _roll_rarity_values(reward_type: String, active_packs: Array[String]) -> Array:
	var rich_weights := _as_dictionary(_as_dictionary(config.get("rarity_weights_by_reward_type", {})).get(reward_type, {}))
	if not rich_weights.is_empty():
		var adjusted := rich_weights.duplicate(true)
		var group := _roll_weighted_key(adjusted)
		return _to_string_array(RARITY_GROUPS.get(group, ["N"]))

	var simple_weights := _as_dictionary(_as_dictionary(config.get("reward_weights", {})).get(reward_type, {})).duplicate(true)
	if reward_type == "boss_combat":
		return ["R", "SR", "SSR"]
	if simple_weights.is_empty():
		simple_weights = {"N": 65, "R": 30, "SR": 5}
	var rarity := _roll_weighted_key(simple_weights)
	return [rarity]


func _elements_for_pool(pool_type: String, main_element: String, active_packs: Array[String]) -> Array:
	match pool_type:
		"main_element":
			return [main_element] if not main_element.is_empty() else []
		"neutral":
			return ["neutral"]
		"related_elements":
			return _related_pack_elements(main_element, active_packs)
		"random_non_main":
			var pool: Array[String] = []
			for element in ALL_ELEMENTS:
				if element != main_element:
					pool.append(element)
			return pool
		"requested_pool":
			var requested := _active_pack_elements(active_packs)
			if main_element != "" and not requested.has(main_element):
				requested.append(main_element)
			return requested
		"all_available":
			return []
		_:
			return []


func _related_pack_elements(main_element: String, active_packs: Array[String]) -> Array:
	var result: Array[String] = []
	var relationships := _as_dictionary(config.get("element_relationships", {}))
	var relation := _as_dictionary(relationships.get(main_element, {}))
	result = _to_string_array(relation.get("related_elements", []))
	if result.is_empty():
		match main_element:
			"wood":
				result = ["fire", "water"]
			"fire":
				result = ["earth", "wood"]
			"earth":
				result = ["metal", "fire"]
			"metal":
				result = ["water", "earth", "weapon"]
			"water":
				result = ["wood", "metal", "soul"]
			"soul":
				result = ["water", "fire"]
			"weapon":
				result = ["metal", "wood"]
	var pack_elements := _active_pack_elements(active_packs)
	for element in pack_elements:
		if not result.has(element) and element != main_element:
			result.append(element)
	return result


func _filter_cards(elements: Array, rarities: Array, picked_ids: Array[String]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in GameData.get_cards():
		if not item is Dictionary:
			continue
		var card: Dictionary = item
		var card_id := str(card.get("id", ""))
		if picked_ids.has(card_id):
			continue
		if bool(card.get("npc_only", false)):
			continue
		if _has_excluded_tag(card):
			continue
		var rarity := str(card.get("rarity", "N"))
		if EXCLUDED_RARITIES.has(rarity) and not _has_reward_allowed_tag(card):
			continue
		if not rarities.is_empty() and not rarities.has(rarity):
			continue
		var element := _card_element(card)
		if not elements.is_empty() and not elements.has(element):
			continue
		result.append(card)
	return result


func _has_excluded_tag(card: Dictionary) -> bool:
	var tags := _to_string_array(card.get("tags", []))
	var defaults := _as_dictionary(config.get("reward_defaults", {}))
	var excluded := _to_string_array(defaults.get("exclude_tags", ["starter", "debug_only", "enemy_only"]))
	for tag in excluded:
		if tags.has(tag):
			return true
	return false


func _has_reward_allowed_tag(card: Dictionary) -> bool:
	return _to_string_array(card.get("tags", [])).has("reward_allowed")


func _active_pack_elements(active_packs: Array[String]) -> Array:
	var result: Array[String] = []
	for pack_id in active_packs:
		for element in _pack_elements(pack_id):
			if not result.has(element):
				result.append(element)
	return result


func _pack_elements(pack_id: String) -> Array:
	if pack_id == "pack_five_elements" or pack_id == "pack_mixed_five_elements":
		return FIVE_ELEMENTS.duplicate()
	if pack_id == "pack_all_paths":
		return ALL_ELEMENTS.duplicate()
	if pack_id.begins_with("pack_"):
		var raw := pack_id.trim_prefix("pack_")
		var pieces := raw.split("_", false)
		var result: Array[String] = []
		for piece in pieces:
			if ALL_ELEMENTS.has(piece) or piece == "neutral":
				result.append(piece)
		return result
	if ALL_ELEMENTS.has(pack_id) or pack_id == "neutral":
		return [pack_id]
	return []


func _roll_weighted_key(weights: Dictionary) -> String:
	var total := 0.0
	for key in weights.keys():
		total += max(0.0, float(weights[key]))
	if total <= 0.0:
		return str(weights.keys()[0]) if not weights.is_empty() else ""
	var cursor := rng.randf_range(0.0, total)
	for key in weights.keys():
		cursor -= max(0.0, float(weights[key]))
		if cursor <= 0.0:
			return str(key)
	return str(weights.keys()[-1])


func _card_choices() -> int:
	var defaults := _as_dictionary(config.get("reward_defaults", {}))
	return int(defaults.get("card_choices", 3))


func _fallback_order() -> Array:
	var defaults := _as_dictionary(config.get("reward_defaults", {}))
	var fallback := _to_string_array(defaults.get("fallback_order", []))
	if fallback.is_empty():
		fallback = ["requested_pool", "neutral", "main_element", "all_available"]
	return fallback


func _normalize_reward_type(reward_type: String) -> String:
	match reward_type:
		"elite", "elite_choice", "story_elite", "story_elite_combat":
			return "elite_combat"
		"boss", "boss_combat":
			return "boss_combat"
		"", "combat":
			return "normal_combat"
		_:
			return reward_type


func _to_card_data(card: Dictionary) -> CardData:
	return CardData.new(
		str(card.get("id", "")),
		str(card.get("name", "")),
		_card_element(card),
		str(card.get("type", "")),
		card.get("cost", 0),
		str(card.get("description", "")),
		str(card.get("rarity", "N")),
		card.get("effects", []),
		str(card.get("target_type", "enemy"))
	)


func _card_element(card: Dictionary) -> String:
	var element := str(card.get("element", ""))
	if element.is_empty():
		element = str(card.get("main_element", ""))
	return element


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("[Reward] Config not found: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[Reward] Could not open config: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("[Reward] Could not parse config: %s" % path)
		return {}
	return parsed


func _as_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


func _to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result
