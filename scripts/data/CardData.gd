class_name CardData
extends RefCounted

var id: String
var name: String
var element: String
var type: String
var cost
var description: String
var rarity: String
var effects: Array
var target_type: String


func _init(
	p_id: String = "",
	p_name: String = "",
	p_element: String = "",
	p_type: String = "",
	p_cost = 0,
	p_description: String = "",
	p_rarity: String = "N",
	p_effects: Array = [],
	p_target_type: String = "enemy"
) -> void:
	id = p_id
	name = p_name
	element = p_element
	type = p_type
	cost = p_cost
	description = p_description
	rarity = p_rarity
	effects = p_effects
	target_type = p_target_type
