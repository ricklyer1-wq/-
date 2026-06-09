class_name ChapterDatabase
extends RefCounted

const DEFAULT_CHAPTER_PATH := "res://data/config/chapter_01.json"

var chapter: Dictionary = {}
var nodes: Array[Dictionary] = []
var nodes_by_id: Dictionary = {}


func load_from_file(path: String = DEFAULT_CHAPTER_PATH) -> bool:
	var parsed := _as_dictionary(_load_json(path))
	if parsed.is_empty():
		return false

	chapter = parsed
	nodes.clear()
	nodes_by_id.clear()
	for item in chapter.get("nodes", []):
		if item is Dictionary:
			var node: Dictionary = item.duplicate(true)
			nodes.append(node)
			nodes_by_id[str(node.get("id", ""))] = node

	nodes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("index", 0)) < int(b.get("index", 0))
	)
	return not nodes.is_empty()


func get_chapter_id() -> String:
	return str(chapter.get("id", ""))


func get_chapter_name() -> String:
	return str(chapter.get("name", ""))


func get_chapter_subtitle() -> String:
	return str(chapter.get("subtitle", ""))


func get_start_node_id() -> String:
	var start_id := str(chapter.get("start_node_id", ""))
	if not start_id.is_empty():
		return start_id
	if nodes.is_empty():
		return ""
	return str(nodes[0].get("id", ""))


func get_nodes() -> Array[Dictionary]:
	return nodes.duplicate(true)


func get_node(node_id: String) -> Dictionary:
	return _as_dictionary(nodes_by_id.get(node_id, {})).duplicate(true)


func get_next_node_id(node_id: String) -> String:
	var node := get_node(node_id)
	var next_ids: Array = node.get("next_node_ids", [])
	if not next_ids.is_empty():
		return str(next_ids[0])
	return ""


func get_first_incomplete_node_id(completed_node_ids: Array[String]) -> String:
	for node in nodes:
		var node_id := str(node.get("id", ""))
		if not completed_node_ids.has(node_id):
			return node_id
	return ""


func normalize_node_type(node_type: String) -> String:
	match node_type:
		"elite_choice":
			return "elite"
		"story_elite_combat":
			return "story_elite"
		"rest_or_upgrade":
			return "rest"
		"boss_combat":
			return "boss"
		_:
			return node_type


func is_combat_type(node_type: String) -> bool:
	return normalize_node_type(node_type) in ["combat", "elite", "story_elite", "boss"]


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Chapter file not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open chapter file: %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("Could not parse chapter file: %s" % path)
		return {}
	return parsed


func _as_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}
