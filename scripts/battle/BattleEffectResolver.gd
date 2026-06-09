class_name BattleEffectResolver
extends RefCounted

const SUPPORTED_OPS := {
	"deal_damage": true,
	"deal_true_damage": true,
	"deal_damage_all": true,
	"gain_block": true,
	"draw_cards": true,
	"gain_energy": true,
	"apply_status": true,
	"remove_status": true,
	"remove_self_status": true,
	"lose_hp": true,
	"heal": true,
	"discard_cards": true,
	"exhaust": true,
	"trigger_burn_all": true,
}

var battle: Node


func _init(p_battle: Node) -> void:
	battle = p_battle


func resolve_card(card: CardData, target_enemy: EnemyData) -> Array[String]:
	var card_record: Dictionary = GameData.get_card_by_id(card.id)
	var effects: Array = card_record.get("effects", [])
	var lines: Array[String] = []

	for effect in effects:
		if not _condition_passes(effect, card, target_enemy):
			continue

		var op := str(effect.get("op", ""))
		if not SUPPORTED_OPS.has(op):
			lines.append("尚未支援效果：%s" % op)
			continue

		match op:
			"deal_damage":
				_resolve_damage(effect, target_enemy, false, lines)
			"deal_true_damage":
				_resolve_damage(effect, target_enemy, true, lines)
			"deal_damage_all":
				_resolve_damage_all(effect, false, lines)
			"gain_block":
				var amount := _amount(effect)
				battle.add_player_block(amount)
				lines.append("你獲得 %d 護盾。" % amount)
			"draw_cards":
				var amount := _amount(effect)
				battle.draw_cards(amount)
				lines.append("抽 %d 張牌。" % amount)
			"gain_energy":
				var amount := _amount(effect)
				battle.add_player_energy(amount)
				lines.append("你獲得 %d 靈力。" % amount)
			"apply_status":
				_resolve_apply_status(effect, target_enemy, lines)
			"remove_status":
				_resolve_remove_status(effect, target_enemy, false, lines)
			"remove_self_status":
				_resolve_remove_status(effect, target_enemy, true, lines)
			"lose_hp":
				var amount := _amount(effect)
				var lost: int = battle.lose_player_hp(amount)
				lines.append("你失去 %d 生命。" % lost)
			"heal":
				var amount := _amount(effect)
				var healed: int = battle.heal_player(amount)
				lines.append("你回復 %d 生命。" % healed)
			"discard_cards":
				var amount := _amount(effect)
				var discarded: int = battle.discard_cards_from_hand(amount, card)
				lines.append("棄掉 %d 張牌。" % discarded)
			"exhaust":
				pass
			"trigger_burn_all":
				var triggered: int = battle.trigger_burn_all(_amount(effect, "lose_hp_per_triggered_enemy"))
				if triggered > 0:
					lines.append("引爆 %d 名敵人的燃燒。" % triggered)
				else:
					lines.append("沒有可引爆的燃燒。")

	return lines


func _resolve_damage(effect: Dictionary, target_enemy: EnemyData, true_damage: bool, lines: Array[String]) -> void:
	var amount := _amount(effect)
	var damage: int = battle.damage_enemy(target_enemy, amount, true_damage)
	if damage > 0:
		lines.append("%s 受到 %d%s傷害。" % [target_enemy.name, damage, " 真實" if true_damage else ""])
	else:
		lines.append("%s 沒有受到傷害。" % target_enemy.name)


func _resolve_damage_all(effect: Dictionary, true_damage: bool, lines: Array[String]) -> void:
	var amount := _amount(effect)
	var hits := 0
	for enemy in battle.get_living_enemies():
		var damage: int = battle.damage_enemy(enemy, amount, true_damage)
		if damage > 0:
			hits += 1
	lines.append("全體敵人受到 %d 傷害，命中 %d 名敵人。" % [amount, hits])


func _resolve_apply_status(effect: Dictionary, target_enemy: EnemyData, lines: Array[String]) -> void:
	var status_id := _status_id(effect)
	var amount := _amount(effect)
	if status_id.is_empty() or amount <= 0:
		return

	match str(effect.get("target", "enemy")):
		"self", "player":
			battle.add_player_status(status_id, amount)
			lines.append("你獲得 %d 層%s。" % [amount, battle.status_name(status_id)])
		"enemies", "all_enemies":
			for enemy in battle.get_living_enemies():
				battle.add_enemy_status(enemy, status_id, amount)
			lines.append("所有敵人獲得 %d 層%s。" % [amount, battle.status_name(status_id)])
		_:
			battle.add_enemy_status(target_enemy, status_id, amount)
			lines.append("%s 獲得 %d 層%s。" % [target_enemy.name, amount, battle.status_name(status_id)])


func _resolve_remove_status(effect: Dictionary, target_enemy: EnemyData, force_self: bool, lines: Array[String]) -> void:
	var status_id := _status_id(effect)
	if status_id.is_empty():
		return

	var target := str(effect.get("target", "enemy"))
	if force_self or target == "self" or target == "player":
		var removed: int = battle.remove_player_status(status_id)
		lines.append("移除你身上的 %s %d 層。" % [battle.status_name(status_id), removed])
		return

	var removed_enemy: int = battle.remove_enemy_status(target_enemy, status_id)
	lines.append("移除 %s 身上的 %s %d 層。" % [target_enemy.name, battle.status_name(status_id), removed_enemy])


func _condition_passes(effect: Dictionary, card: CardData, target_enemy: EnemyData) -> bool:
	var condition := str(effect.get("condition", ""))
	if condition.is_empty() or condition == "<null>" or condition == "Null" or condition == "null":
		return true

	match condition:
		"self_has_flame_body":
			return battle.player_status_amount("flame_body") > 0
		"target_has_poison":
			return battle.enemy_status_amount(target_enemy, "poison") > 0
		"hand_has_attack":
			return battle.hand_has_type("attack")
		"first_card_this_turn":
			return battle.cards_played_this_turn() == 0
		"played_water_this_turn":
			return battle.played_element_this_turn("water")
		"target_intent_is_attack":
			return target_enemy != null and target_enemy.intent_type == "attack"
		_:
			return false


func _status_id(effect: Dictionary) -> String:
	return str(effect.get("status", effect.get("status_key", ""))).to_lower()


func _amount(effect: Dictionary, key: String = "amount") -> int:
	var raw = effect.get(key, 0)
	if raw is String and raw.to_upper() == "X":
		return battle.current_x_value()
	return int(raw)
