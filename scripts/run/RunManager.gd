extends Node

const RunStateScript = preload("res://scripts/run/RunState.gd")
const StartingCultivatorDatabaseScript = preload("res://scripts/run/StartingCultivatorDatabase.gd")
const RUN_FLOW_PATH := "res://data/config/run_flow_v1.json"
const CHAPTER_01_PATH := "res://data/config/chapter_01.json"
const STARTING_CULTIVATORS_PATH := "res://data/config/starting_cultivators.json"
const CARD_PACKS_PATH := "res://data/config/card_reward_weights_toggleable.json"
const MAP_SCENE_PLACEHOLDER := "return_to_map"
const DEBUG_CULTIVATOR_ID := "fire_cultivator"
const DEBUG_LOG_PATH := "res://run_flow_smoke.log"

var state = RunStateScript.new()
var run_flow: Dictionary = {}
var chapter: Dictionary = {}
var starting_cultivators: Dictionary = {}
var card_pack_config: Dictionary = {}
var starting_cultivator_db = StartingCultivatorDatabaseScript.new()
var _smoke_log_lines: Array[String] = []


func _ready() -> void:
	load_configs()
	start_debug_run()


func load_configs() -> bool:
	run_flow = _as_dictionary(_load_json(RUN_FLOW_PATH))
	chapter = _as_dictionary(_load_json(CHAPTER_01_PATH))
	starting_cultivators = _as_dictionary(_load_json(STARTING_CULTIVATORS_PATH))
	var cultivators_loaded: bool = starting_cultivator_db.load_from_file(STARTING_CULTIVATORS_PATH)
	card_pack_config = _as_dictionary(_load_json(CARD_PACKS_PATH))
	return not run_flow.is_empty() and not chapter.is_empty() and cultivators_loaded and not card_pack_config.is_empty()


func start_new_run(cultivator_id: String = "", active_card_packs: Array = []):
	if run_flow.is_empty():
		load_configs()

	var requested_id := cultivator_id
	if requested_id.is_empty():
		requested_id = str(run_flow.get("default_cultivator_id", ""))

	var resolved_cultivator_id := starting_cultivator_db.get_default_cultivator_id(requested_id)
	if resolved_cultivator_id.is_empty():
		resolved_cultivator_id = starting_cultivator_db.get_default_cultivator_id(str(run_flow.get("default_cultivator_id", "")))

	if not select_starting_cultivator(resolved_cultivator_id, active_card_packs):
		push_error("Unknown cultivator id: %s" % resolved_cultivator_id)
		return state
	return state


func select_starting_cultivator(cultivator_id: String, active_card_packs: Array = []) -> bool:
	if starting_cultivator_db.cultivators_by_id.is_empty():
		load_configs()

	var cultivator := starting_cultivator_db.get_cultivator(cultivator_id)
	if cultivator.is_empty():
		push_error("Unknown starting cultivator id: %s" % cultivator_id)
		return false

	var resolved_card_packs := active_card_packs.duplicate()
	if resolved_card_packs.is_empty():
		resolved_card_packs = _default_active_card_packs_for_cultivator(cultivator)
	resolved_card_packs = _limit_active_card_packs(resolved_card_packs, cultivator_id)

	var chapter_id: String = state.current_chapter_id
	if chapter_id.is_empty():
		chapter_id = str(chapter.get("id", run_flow.get("default_chapter_id", "chapter_01")))

	var node_id: String = state.current_node_id
	if node_id.is_empty():
		node_id = str(chapter.get("start_node_id", ""))
		if node_id.is_empty():
			node_id = _first_node_id()

	state.setup_from_cultivator(cultivator, resolved_card_packs, chapter_id, node_id)
	return true


func start_debug_run():
	var log_lines: Array[String] = []
	_smoke_log_lines = log_lines
	_log_smoke(log_lines, "RunManager autoload: OK")
	var configs_loaded := load_configs()
	_log_smoke(log_lines, "run_flow_v1.json: %s" % _ok_text(not run_flow.is_empty()))
	_log_smoke(log_lines, "chapter_01.json: %s" % _ok_text(not chapter.is_empty()))
	_log_smoke(log_lines, "starting_cultivators.json: %s" % _ok_text(not starting_cultivators.is_empty()))
	_log_smoke(log_lines, "card_reward_weights_toggleable.json: %s" % _ok_text(not card_pack_config.is_empty()))
	if not configs_loaded:
		push_error("[RunFlowSmoke] Config loading failed.")
		_write_smoke_log(log_lines)
		return state

	var debug_state = start_new_run(DEBUG_CULTIVATOR_ID)
	var first_node_id := str(chapter.get("start_node_id", _first_node_id()))
	state.current_chapter_id = "chapter_01"
	set_current_node(first_node_id)
	state.selected_cultivator_id = DEBUG_CULTIVATOR_ID
	_log_smoke(log_lines, "New RunState: %s" % _ok_text(debug_state != null))
	_log_smoke(log_lines, "current chapter set to chapter_01: %s" % _ok_text(state.current_chapter_id == "chapter_01"))
	_log_smoke(log_lines, "current node set to first node: %s" % _ok_text(state.current_node_id == first_node_id and not first_node_id.is_empty()))
	_log_smoke(log_lines, "selected cultivator set to fire_cultivator: %s" % _ok_text(state.selected_cultivator_id == DEBUG_CULTIVATOR_ID))
	debug_print_run_state(log_lines)
	debug_select_starting_cultivators(log_lines)
	select_starting_cultivator(DEBUG_CULTIVATOR_ID)
	_log_smoke(log_lines, "debug run restored to fire_cultivator: %s" % _ok_text(state.selected_cultivator_id == DEBUG_CULTIVATOR_ID))
	_write_smoke_log(log_lines)
	_smoke_log_lines = []
	return state


func start_chapter_01_debug_run(use_debug_deck: bool = false):
	print("[Chapter01Test] start")
	if run_flow.is_empty() or chapter.is_empty():
		load_configs()

	start_new_run(DEBUG_CULTIVATOR_ID)
	state.current_chapter_id = "chapter_01"
	state.current_node_id = str(chapter.get("start_node_id", _first_node_id()))
	state.completed_node_ids.clear()
	state.pending_card_reward.clear()
	state.flags.erase("pending_reward_type")
	state.flags["use_debug_deck"] = use_debug_deck
	state.flags["debug_deck_id"] = "combo_test_deck" if use_debug_deck else ""
	state.cleared_chapter_id = ""
	state.last_chapter_ending_choice = ""
	state.flags.erase("chapter_01_cleared")
	state.flags.erase("last_chapter_ending_choice")

	var first_node := get_current_node()
	print("[Chapter01Test] enter node=%s type=%s" % [
		state.current_node_id,
		str(first_node.get("type", "")),
	])
	return state


func debug_select_starting_cultivators(log_lines: Array[String] = []) -> void:
	_log_smoke(log_lines, "Starting cultivator selection debug:")
	for cultivator_id in ["fire_cultivator", "earth_cultivator", "wanderer_cultivator"]:
		var selected := select_starting_cultivator(cultivator_id)
		_log_smoke(log_lines, "  select %s: %s" % [cultivator_id, _ok_text(selected)])
		if selected:
			debug_print_run_state(log_lines)

	var overflow_packs := ["pack_fire", "pack_wood_fire", "pack_fire_soul"]
	var overflow_selected := select_starting_cultivator("fire_cultivator", overflow_packs)
	_log_smoke(log_lines, "  select fire_cultivator with overflow active packs: %s" % _ok_text(overflow_selected))
	if overflow_selected:
		debug_print_run_state(log_lines)


func debug_print_run_state(log_lines: Array[String] = []) -> void:
	_log_smoke(log_lines, "RunState summary:")
	_log_smoke(log_lines, "  chapter_id=%s" % state.current_chapter_id)
	_log_smoke(log_lines, "  current_node_id=%s" % state.current_node_id)
	_log_smoke(log_lines, "  selected_cultivator_id=%s" % state.selected_cultivator_id)
	_log_smoke(log_lines, "  main_element=%s" % state.main_element)
	_log_smoke(log_lines, "  current_hp=%d" % state.current_hp)
	_log_smoke(log_lines, "  max_hp=%d" % state.max_hp)
	_log_smoke(log_lines, "  deck_size=%d" % state.deck.size())
	_log_smoke(log_lines, "  gold=%d" % state.gold)
	_log_smoke(log_lines, "  active_card_packs=%s" % str(state.active_card_packs))
	_log_smoke(log_lines, "  recommended_card_packs=%s" % str(state.recommended_card_packs))


func get_cultivator(cultivator_id: String) -> Dictionary:
	return starting_cultivator_db.get_cultivator(cultivator_id)


func get_current_node() -> Dictionary:
	return get_node_by_id(state.current_node_id)


func get_node_by_id(node_id: String) -> Dictionary:
	for node in chapter.get("nodes", []):
		if node is Dictionary and str(node.get("id", "")) == node_id:
			return node
	return {}


func set_current_node(node_id: String) -> bool:
	if get_node_by_id(node_id).is_empty():
		push_error("Unknown chapter node id: %s" % node_id)
		return false
	state.current_node_id = node_id
	return true


func complete_current_node() -> String:
	var node := get_current_node()
	if node.is_empty():
		return ""

	state.mark_current_node_completed()
	var next_node_id := _first_next_node_id(node)
	state.current_node_id = next_node_id
	return next_node_id


func go_to_scene_for_node(node_id: String, change_scene: bool = false) -> String:
	if not set_current_node(node_id):
		return ""

	var node := get_current_node()
	var handler := get_node_type_handler(str(node.get("type", "")))
	var scene_path := str(handler.get("scene", ""))
	var after_win := str(handler.get("after_win", MAP_SCENE_PLACEHOLDER))

	if _is_battle_node(node):
		state.set_battle_return(after_win, _flow_scene_for_state(after_win))
	else:
		state.clear_battle_return()

	if change_scene and not scene_path.is_empty():
		get_tree().change_scene_to_file(scene_path)
	return scene_path


func get_node_type_handler(node_type: String) -> Dictionary:
	return _as_dictionary(_as_dictionary(run_flow.get("node_type_handlers", {})).get(node_type, {}))


func record_battle_victory() -> String:
	var node := get_current_node()
	if node.is_empty() or not _is_battle_node(node):
		return ""

	var handler := get_node_type_handler(str(node.get("type", "")))
	var after_win := str(handler.get("after_win", MAP_SCENE_PLACEHOLDER))
	state.set_battle_return(after_win, _flow_scene_for_state(after_win))
	complete_current_node()
	return after_win


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Run config not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open run config: %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("Could not parse run config: %s" % path)
		return {}
	return parsed


func _first_node_id() -> String:
	var nodes: Array = chapter.get("nodes", [])
	if nodes.is_empty() or not nodes[0] is Dictionary:
		return ""
	return str(nodes[0].get("id", ""))


func _first_next_node_id(node: Dictionary) -> String:
	var next_node_ids: Array = node.get("next_node_ids", [])
	if next_node_ids.is_empty():
		return ""
	return str(next_node_ids[0])


func _is_battle_node(node: Dictionary) -> bool:
	var node_type := str(node.get("type", ""))
	return node_type in ["combat", "elite_combat", "story_elite", "boss"]


func _flow_scene_for_state(flow_state: String) -> String:
	match flow_state:
		"card_reward":
			return "res://scenes/reward/CardRewardScene.tscn"
		"chapter_boss_clear":
			return "res://scenes/ending/ChapterEndingScene.tscn"
		"run_result":
			return "res://scenes/run/ResultScene.tscn"
		"return_to_map":
			return "res://scenes/map/MapScene.tscn"
		_:
			return ""


func _as_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


func _default_active_card_packs_for_cultivator(cultivator: Dictionary) -> Array[String]:
	var recommended := _to_string_array(cultivator.get("recommended_card_packs", []))
	var max_active := _max_active_card_packs()
	if max_active <= 0:
		return []
	return recommended.slice(0, max_active)


func _limit_active_card_packs(card_packs: Array, cultivator_id: String) -> Array[String]:
	var resolved := _to_string_array(card_packs)
	var max_active := _max_active_card_packs()
	if max_active >= 0 and resolved.size() > max_active:
		var warning := "active_card_packs for %s exceeds max_active_card_packs=%d; truncating %s to %s" % [
			cultivator_id,
			max_active,
			str(resolved),
			str(resolved.slice(0, max_active)),
		]
		push_warning(warning)
		_log_smoke(_smoke_log_lines, "WARNING: %s" % warning)
		resolved = resolved.slice(0, max_active)
	return resolved


func _max_active_card_packs() -> int:
	return int(card_pack_config.get("max_active_card_packs", 2))


func _to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result


func _ok_text(is_ok: bool) -> String:
	return "OK" if is_ok else "FAIL"


func _log_smoke(log_lines: Array[String], message: String) -> void:
	var line := "[RunFlowSmoke] %s" % message
	print(line)
	if log_lines != null:
		log_lines.append(line)


func _write_smoke_log(log_lines: Array[String]) -> void:
	var file := FileAccess.open(DEBUG_LOG_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[RunFlowSmoke] Could not write smoke log: %s" % DEBUG_LOG_PATH)
		return
	file.store_string("\n".join(log_lines))
