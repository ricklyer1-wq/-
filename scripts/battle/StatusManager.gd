class_name StatusManager
extends RefCounted

var battle: Node # Reference to BattleScene
var player_statuses: Array = []


func _init(p_battle: Node) -> void:
	battle = p_battle
	player_statuses = [
		{"id": "flame_body", "amount": 1},
		{"id": "sword_intent", "amount": 1},
	]


func add_player_status(status_id: String, amount: int) -> void:
	_add_status(player_statuses, status_id, amount)


func add_enemy_status(enemy: EnemyData, status_id: String, amount: int) -> void:
	if enemy == null:
		return
	_add_status(enemy.statuses, status_id, amount)


func remove_player_status(status_id: String) -> int:
	return _remove_status(player_statuses, status_id)


func remove_enemy_status(enemy: EnemyData, status_id: String) -> int:
	if enemy == null:
		return 0
	return _remove_status(enemy.statuses, status_id)


func player_status_amount(status_id: String) -> int:
	return _status_amount(player_statuses, status_id)


func enemy_status_amount(enemy: EnemyData, status_id: String) -> int:
	if enemy == null:
		return 0
	return _status_amount(enemy.statuses, status_id)


func status_name(status_id: String) -> String:
	var status_record: Dictionary = GameData.get_status(status_id)
	return str(status_record.get("name", status_id))


func resolve_turn_start_statuses() -> Array[String]:
	var lines: Array[String] = []
	var burn := player_status_amount("burn")
	if burn > 0:
		var damage: int = battle.lose_player_hp(burn)
		lines.append("灼燒造成 %d 傷害。" % damage)
		_tick_status(player_statuses, "burn", 1)
	for enemy in battle.get_living_enemies():
		_tick_status(enemy.statuses, "weak", 1)
		_tick_status(enemy.statuses, "vulnerable", 1)
		_tick_status(enemy.statuses, "chilled", 1)
	_tick_status(player_statuses, "weak", 1)
	_tick_status(player_statuses, "vulnerable", 1)
	return lines


func resolve_turn_end_statuses() -> Array[String]:
	var lines: Array[String] = []
	for enemy in battle.get_living_enemies():
		var poison := enemy_status_amount(enemy, "poison")
		if poison > 0:
			var damage: int = battle.damage_enemy(enemy, poison, true)
			lines.append("%s 受到 %d 中毒傷害。" % [enemy.name, damage])
			_tick_status(enemy.statuses, "poison", 1)
		var burn := enemy_status_amount(enemy, "burn")
		if burn > 0:
			var burn_damage: int = battle.damage_enemy(enemy, burn, true)
			lines.append("%s 受到 %d 灼燒傷害。" % [enemy.name, burn_damage])
			_tick_status(enemy.statuses, "burn", 1)
	return lines


func _add_status(statuses: Array, status_id: String, amount: int) -> void:
	if status_id.is_empty() or amount <= 0:
		return
	status_id = status_id.to_lower()
	for status in statuses:
		if str(status.get("id", status.get("name", ""))).to_lower() == status_id:
			status["amount"] = int(status.get("amount", 0)) + amount
			return
	statuses.append({"id": status_id, "amount": amount})


func _remove_status(statuses: Array, status_id: String) -> int:
	status_id = status_id.to_lower()
	for index in range(statuses.size() - 1, -1, -1):
		if str(statuses[index].get("id", statuses[index].get("name", ""))).to_lower() == status_id:
			var amount := int(statuses[index].get("amount", 0))
			statuses.remove_at(index)
			return amount
	return 0


func _tick_status(statuses: Array, status_id: String, amount: int) -> void:
	status_id = status_id.to_lower()
	for index in range(statuses.size() - 1, -1, -1):
		if str(statuses[index].get("id", statuses[index].get("name", ""))).to_lower() == status_id:
			var next_amount := int(statuses[index].get("amount", 0)) - amount
			if next_amount <= 0:
				statuses.remove_at(index)
			else:
				statuses[index]["amount"] = next_amount
			return


func _status_amount(statuses: Array, status_id: String) -> int:
	status_id = status_id.to_lower()
	for status in statuses:
		if str(status.get("id", status.get("name", ""))).to_lower() == status_id:
			return int(status.get("amount", 0))
	return 0
