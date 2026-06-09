extends Node

var unlocked_cultivators: Array[String] = []
var unlocked_card_packs: Array[String] = []
var cleared_chapters: Array[String] = []
var last_chapter_ending_choice := ""
var max_active_card_packs_bonus := 0


func unlock_cultivator(cultivator_id: String) -> void:
	if cultivator_id.is_empty():
		return
	if not unlocked_cultivators.has(cultivator_id):
		unlocked_cultivators.append(cultivator_id)
	print("[Ending] unlock cultivator=%s" % cultivator_id)


func unlock_card_pack(pack_id: String) -> void:
	if pack_id.is_empty():
		return
	if not unlocked_card_packs.has(pack_id):
		unlocked_card_packs.append(pack_id)
	print("[Ending] unlock card_pack=%s" % pack_id)


func mark_chapter_cleared(chapter_id: String) -> void:
	if chapter_id.is_empty():
		return
	if not cleared_chapters.has(chapter_id):
		cleared_chapters.append(chapter_id)
	print("[Ending] cleared chapter=%s" % chapter_id)


func apply_max_active_card_packs_bonus(value: int) -> void:
	if value <= 0:
		return
	max_active_card_packs_bonus = max(max_active_card_packs_bonus, value)
	print("[Ending] max_active_card_packs_bonus=%d" % max_active_card_packs_bonus)


func set_last_choice(choice_id: String) -> void:
	last_chapter_ending_choice = choice_id


func debug_print() -> void:
	print("[Ending] profile unlocked_cultivators=%s" % JSON.stringify(unlocked_cultivators))
	print("[Ending] profile unlocked_card_packs=%s" % JSON.stringify(unlocked_card_packs))
	print("[Ending] profile cleared_chapters=%s" % JSON.stringify(cleared_chapters))
