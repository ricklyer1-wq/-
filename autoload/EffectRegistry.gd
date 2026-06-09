extends Node

const OPS = {
	"deal_damage": ["target", "amount"],
	"deal_true_damage": ["target", "amount"],
	"deal_damage_all": ["target", "amount"],
	"deal_true_aoe_damage": ["amount"],
	"deal_true_damage_per_status": ["status", "amount"],
	"deal_damage_vampire": ["amount"],
	"deal_damage_equal_block": [],
	"deal_damage_boost_by_status_cards": [],
	"gain_block": ["target", "amount"],
	"draw_cards": ["target", "amount"],
	"gain_energy": ["target", "amount"],
	"apply_status": ["target", "status", "amount"],
	"apply_power": ["target", "power", "amount"],
	"add_block_per_status": ["status"],
	"add_block_per_debuff": [],
	"add_buff": ["status"],
	"add_temporary_buff": ["status"],
	"add_random_rare_to_hand": [],
	"buff_soul_damage": ["amount"],
	"exhaust": ["target"],
	"exhaust_type_in_hand": [],
	"discard_cards": ["target", "amount"],
	"discard_all_type": [],
	"shuffle_card_into_draw_pile": ["card_id", "amount"],
	"add_card_to_hand": ["card_id", "amount"],
	"play_card_by_id": ["card_id"],
	"play_all_from_decks": ["card_id"],
	"summon": ["summon_id", "amount"],
	"change_intent": ["target", "intent"],
	"increase_max_hp_on_kill": ["target", "amount"],
	"consume_all_energy": [],
	"discover_from_discard": [],
	"double_current_block": [],
	"end_turn": [],
	"get_self_status": ["status"],
	"heal": ["amount"],
	"lose_hp": ["amount"],
	"multiply_status": ["status"],
	"redirect_intent_to_self": [],
	"reduce_gold": ["amount"],
	"reduce_intent_damage": ["amount"],
	"remove_status": ["status"],
	"retain_hand": [],
	"return_to_hand_on_discard": [],
	"strip_block": [],
	"trigger_burn_all": [],
	"trigger_on_turn_end_in_hand": [],
	"unplayable": [],
}


func has_op(op: String) -> bool:
	return OPS.has(op)


func get_required_params(op: String) -> Array:
	return OPS.get(op, [])


func validate_effect(effect: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not effect.has("op"):
		errors.append("Effect is missing required field: op")
		return errors

	var op := str(effect.get("op", ""))
	if not has_op(op):
		errors.append("Unknown effect op: %s" % op)
		return errors

	for param in get_required_params(op):
		if not effect.has(param):
			errors.append("Effect '%s' is missing required field: %s" % [op, param])
			continue

		var value = effect[param]
		if param == "amount" and typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
			errors.append("Effect '%s' field 'amount' must be a number." % op)
		elif param != "amount" and str(value).strip_edges().is_empty():
			errors.append("Effect '%s' field '%s' must not be empty." % [op, param])

	return errors
