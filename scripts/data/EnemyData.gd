class_name EnemyData
extends RefCounted

var id: String
var name: String
var hp: int
var max_hp: int
var block: int
var intent_type: String
var intent_value: int
var statuses: Array
var intent_sequence: Array
var intent_index: int = 0


func _init(
	p_id: String = "",
	p_name: String = "",
	p_hp: int = 1,
	p_max_hp: int = 1,
	p_block: int = 0,
	p_intent_type: String = "unknown",
	p_intent_value: int = 0,
	p_statuses: Array = [],
	p_intent_sequence: Array = []
) -> void:
	id = p_id
	name = p_name
	hp = p_hp
	max_hp = p_max_hp
	block = p_block
	intent_type = p_intent_type
	intent_value = p_intent_value
	statuses = p_statuses
	intent_sequence = p_intent_sequence
	if intent_sequence.is_empty():
		intent_sequence = [{"type": intent_type, "value": intent_value}]
	_apply_intent_from_sequence()


func advance_intent() -> void:
	if intent_sequence.is_empty():
		return
	intent_index = (intent_index + 1) % intent_sequence.size()
	_apply_intent_from_sequence()


func _apply_intent_from_sequence() -> void:
	if intent_sequence.is_empty():
		return
	var intent: Dictionary = intent_sequence[intent_index]
	intent_type = str(intent.get("type", intent_type))
	intent_value = int(intent.get("value", intent_value))
