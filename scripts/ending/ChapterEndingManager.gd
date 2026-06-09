class_name ChapterEndingManager
extends RefCounted

const CONFIG_PATH := "res://data/config/chapter_01_ending_choices.json"

var config: Dictionary = {}
var choices: Array[Dictionary] = []


func load_from_file(path: String = CONFIG_PATH) -> bool:
	config = _as_dictionary(_load_json(path))
	choices.clear()
	for item in config.get("choices", []):
		if item is Dictionary:
			choices.append(item.duplicate(true))
	print("[Ending] loaded choices count=%d" % choices.size())
	return not choices.is_empty()


func chapter_id() -> String:
	return str(config.get("chapter_id", "chapter_01"))


func title() -> String:
	return str(config.get("title", "第一章通關"))


func subtitle() -> String:
	return str(config.get("subtitle", "靈霧染血"))


func body() -> String:
	return str(config.get("body", "五大宗門長老打破結界趕來，向主角拋出橄欖枝。主角也可以選擇成為散修，守住祖傳玉簡的秘密。"))


func apply_choice(run_state, profile, choice: Dictionary) -> void:
	var choice_id := str(choice.get("id", ""))
	var clear_chapter_id := chapter_id()
	print("[Ending] selected choice=%s" % choice_id)

	for cultivator_id in _choice_cultivators(choice):
		profile.unlock_cultivator(cultivator_id)
	for pack_id in _choice_card_packs(choice):
		profile.unlock_card_pack(pack_id)

	var bonus := _as_dictionary(choice.get("profile_bonus", {}))
	var max_pack_bonus := int(bonus.get("max_active_card_packs_bonus", 0))
	profile.apply_max_active_card_packs_bonus(max_pack_bonus)
	profile.mark_chapter_cleared(clear_chapter_id)
	profile.set_last_choice(choice_id)
	profile.debug_print()

	run_state.cleared_chapter_id = clear_chapter_id
	run_state.last_chapter_ending_choice = choice_id
	run_state.flags["chapter_01_cleared"] = true
	run_state.flags["last_chapter_ending_choice"] = choice_id
	print("[Chapter01Test] chapter cleared")


func unlock_summary(choice: Dictionary) -> String:
	var lines: Array[String] = []
	for cultivator_id in _choice_cultivators(choice):
		lines.append("解鎖主修：%s" % cultivator_id)
	for pack_id in _choice_card_packs(choice):
		lines.append("解鎖卡牌包：%s" % pack_id)
	var bonus := _as_dictionary(choice.get("profile_bonus", {}))
	if int(bonus.get("max_active_card_packs_bonus", 0)) > 0:
		lines.append("卡牌包啟用上限 +%d" % int(bonus.get("max_active_card_packs_bonus", 0)))
	return "\n".join(lines)


func _choice_cultivators(choice: Dictionary) -> Array[String]:
	var result := _to_string_array(choice.get("unlock_cultivators", []))
	var single := str(choice.get("unlock_cultivator", ""))
	if not single.is_empty() and not result.has(single):
		result.append(single)
	return result


func _choice_card_packs(choice: Dictionary) -> Array[String]:
	return _to_string_array(choice.get("unlock_card_packs", []))


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("[Ending] config not found: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[Ending] could not open config: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("[Ending] could not parse config: %s" % path)
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
