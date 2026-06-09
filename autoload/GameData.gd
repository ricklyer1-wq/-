extends Node

const CARDS_PATH = "res://data/generated/cards.json"
const STATUSES_PATH = "res://data/generated/statuses.json"
const FACTIONS_PATH = "res://data/generated/factions.json"
const ELEMENTS_PATH = "res://data/generated/elements.json"
const DROP_POOLS_PATH = "res://data/generated/drop_pools.json"
const ENEMIES_PATH = "res://data/generated/enemies.json"
const CARD_IMAGE_TEMPLATE = "res://assets/cards/%s.png"
const PLACEHOLDER_CARD_IMAGE = "res://assets/cards/_placeholder.png"

var cards: Array = []
var enemies: Array = []
var statuses: Dictionary = {}
var factions: Dictionary = {}
var elements: Dictionary = {}
var drop_pools: Dictionary = {}
var cards_by_id: Dictionary = {}
var enemies_by_id: Dictionary = {}


func _ready() -> void:
	load_all()


func load_all() -> void:
	cards = _as_array(load_json(CARDS_PATH))
	enemies = _as_array(load_json(ENEMIES_PATH))
	statuses = _index_by_id(_as_array(load_json(STATUSES_PATH)))
	factions = _index_by_id(_as_array(load_json(FACTIONS_PATH)))
	elements = _as_dictionary(load_json(ELEMENTS_PATH))
	drop_pools = _as_dictionary(load_json(DROP_POOLS_PATH))
	cards_by_id = _index_by_id(cards)
	enemies_by_id = _index_by_id(enemies)


func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("JSON file not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open JSON file: %s" % path)
		return {}

	var json_text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(json_text)
	if parsed == null:
		push_error("Could not parse JSON file: %s" % path)
		return {}

	return parsed


func get_cards() -> Array:
	return cards


func get_enemies() -> Array:
	return enemies


func get_status(status_id: String) -> Dictionary:
	return statuses.get(status_id, {})


func get_card_by_id(card_id: String) -> Dictionary:
	return cards_by_id.get(card_id, {})


func get_enemy_by_id(enemy_id: String) -> Dictionary:
	return enemies_by_id.get(enemy_id, {})


func get_card_image_path(card_id: String) -> String:
	var image_path := CARD_IMAGE_TEMPLATE % card_id
	if FileAccess.file_exists(image_path):
		return image_path
	return PLACEHOLDER_CARD_IMAGE


func _index_by_id(items: Array) -> Dictionary:
	var indexed := {}
	for item in items:
		if item is Dictionary and item.has("id"):
			indexed[item["id"]] = item
	return indexed


func _as_array(value: Variant) -> Array:
	if value is Array:
		return value
	return []


func _as_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}
