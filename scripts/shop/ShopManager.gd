class_name ShopManager
extends RefCounted

const RewardManagerScript = preload("res://scripts/reward/RewardManager.gd")
const SHOP_CONFIG_PATH := "res://data/config/shop_v1.json"
const CARD_PACK_CONFIG_PATH := "res://data/config/card_reward_weights_toggleable.json"
const REMOVE_CARD_PRICE := 75
const HEAL_PRICE := 40
const HEAL_AMOUNT := 15
const MIN_DECK_SIZE := 5

const FALLBACK_PACKS := [
	{"id": "pack_metal", "display_name": "金系卡牌包", "elements": ["metal"], "description": "提高金系卡牌獎勵傾向。"},
	{"id": "pack_wood", "display_name": "木系卡牌包", "elements": ["wood"], "description": "提高木系卡牌獎勵傾向。"},
	{"id": "pack_water", "display_name": "水系卡牌包", "elements": ["water"], "description": "提高水系卡牌獎勵傾向。"},
	{"id": "pack_fire", "display_name": "火系卡牌包", "elements": ["fire"], "description": "提高火系卡牌獎勵傾向。"},
	{"id": "pack_earth", "display_name": "土系卡牌包", "elements": ["earth"], "description": "提高土系卡牌獎勵傾向。"},
	{"id": "pack_soul", "display_name": "神魂卡牌包", "elements": ["soul"], "description": "提高神魂卡牌獎勵傾向。"},
	{"id": "pack_weapon", "display_name": "武器暗器卡牌包", "elements": ["weapon"], "description": "提高武器/暗器卡牌獎勵傾向。"},
	{"id": "pack_wood_fire", "display_name": "木火相生卡牌包", "elements": ["wood", "fire"], "description": "提高木、火相關卡牌獎勵傾向。"},
	{"id": "pack_fire_earth", "display_name": "火土相生卡牌包", "elements": ["fire", "earth"], "description": "提高火、土相關卡牌獎勵傾向。"},
	{"id": "pack_earth_metal", "display_name": "土金相生卡牌包", "elements": ["earth", "metal"], "description": "提高土、金相關卡牌獎勵傾向。"},
	{"id": "pack_metal_water", "display_name": "金水相生卡牌包", "elements": ["metal", "water"], "description": "提高金、水相關卡牌獎勵傾向。"},
	{"id": "pack_water_wood", "display_name": "水木相生卡牌包", "elements": ["water", "wood"], "description": "提高水、木相關卡牌獎勵傾向。"},
	{"id": "pack_fire_soul", "display_name": "焚魂卡牌包", "elements": ["fire", "soul"], "description": "提高火、神魂相關卡牌獎勵傾向。"},
	{"id": "pack_five_elements", "display_name": "五行混元卡牌包", "elements": ["metal", "wood", "water", "fire", "earth"], "description": "小幅提高五行卡牌獎勵傾向。"}
]

var shop_config: Dictionary = {}
var card_pack_config: Dictionary = {}
var reward_manager = RewardManagerScript.new()


func load_configs() -> void:
	shop_config = _as_dictionary(_load_json(SHOP_CONFIG_PATH))
	card_pack_config = _as_dictionary(_load_json(CARD_PACK_CONFIG_PATH))


func generate_shop_offers(run_state) -> Array[Dictionary]:
	var cards := reward_manager.generate_card_reward(run_state, "shop")
	var offers: Array[Dictionary] = []
	var index := 0
	for card in cards:
		var rarity := card.rarity
		var price := price_for_rarity(rarity)
		var offer := {
			"card": card,
			"card_id": card.id,
			"rarity": rarity,
			"price": price,
			"sold": false,
		}
		offers.append(offer)
		index += 1
		print("[Shop] offer card=%s rarity=%s price=%d" % [card.id, rarity, price])
	return offers


func price_for_rarity(rarity: String) -> int:
	match rarity:
		"N", "common":
			return int(_prices().get("common_card", 50))
		"R", "uncommon":
			return int(_prices().get("uncommon_card", 75))
		"SR", "SSR", "rare":
			return int(_prices().get("rare_card", 120))
		_:
			return int(_prices().get("common_card", 50))


func buy_offer(run_state, offer: Dictionary) -> bool:
	if bool(offer.get("sold", false)):
		return false
	var card_id := str(offer.get("card_id", ""))
	var price := int(offer.get("price", 0))
	if run_state.gold < price:
		print("[Shop] not enough gold item=%s price=%d gold=%d" % [card_id, price, run_state.gold])
		return false
	var before_gold: int = run_state.gold
	var before_deck: int = run_state.deck.size()
	run_state.gold -= price
	run_state.deck.append(card_id)
	offer["sold"] = true
	print("[Shop] buy card=%s price=%d gold %d -> %d deck_size %d -> %d" % [
		card_id,
		price,
		before_gold,
		run_state.gold,
		before_deck,
		run_state.deck.size(),
	])
	return true


func heal(run_state) -> bool:
	var price := int(_prices().get("heal_flat", HEAL_PRICE))
	var amount := int(_as_dictionary(shop_config.get("heal", {})).get("amount", HEAL_AMOUNT))
	if run_state.current_hp >= run_state.max_hp:
		print("[Shop] hp already full")
		return false
	if run_state.gold < price:
		print("[Shop] not enough gold item=heal price=%d gold=%d" % [price, run_state.gold])
		return false
	var before_hp: int = run_state.current_hp
	var before_gold: int = run_state.gold
	run_state.gold -= price
	run_state.current_hp = min(run_state.max_hp, run_state.current_hp + amount)
	run_state.player_hp = run_state.current_hp
	print("[Shop] heal price=%d hp %d -> %d gold %d -> %d" % [price, before_hp, run_state.current_hp, before_gold, run_state.gold])
	return true


func remove_card(run_state, card_id: String) -> bool:
	var price := int(_prices().get("remove_card_base", REMOVE_CARD_PRICE))
	if run_state.deck.size() <= MIN_DECK_SIZE:
		print("[Shop] cannot remove card=%s min_deck_size=%d" % [card_id, MIN_DECK_SIZE])
		return false
	if run_state.gold < price:
		print("[Shop] not enough gold item=remove_card price=%d gold=%d" % [price, run_state.gold])
		return false
	var index: int = run_state.deck.find(card_id)
	if index < 0:
		return false
	var before_deck: int = run_state.deck.size()
	var before_gold: int = run_state.gold
	run_state.gold -= price
	run_state.deck.remove_at(index)
	print("[Shop] remove card=%s price=%d gold %d -> %d deck_size %d -> %d" % [
		card_id,
		price,
		before_gold,
		run_state.gold,
		before_deck,
		run_state.deck.size(),
	])
	return true


func get_available_packs(run_state) -> Array[Dictionary]:
	var packs := _packs_from_config()
	var unlocked := _to_string_array(run_state.unlocked_card_packs_snapshot)
	if unlocked.size() < 3:
		unlocked.clear()
		for pack in packs:
			unlocked.append(str(pack.get("id", "")))
	var result: Array[Dictionary] = []
	for pack in packs:
		if unlocked.has(str(pack.get("id", ""))):
			result.append(pack)
	return result


func toggle_pack(run_state, pack_id: String) -> bool:
	var max_active := max_active_card_packs(run_state)
	if run_state.active_card_packs.has(pack_id):
		run_state.active_card_packs.erase(pack_id)
		print("[Shop] toggle pack=%s enabled=false" % pack_id)
		print("[Shop] active_card_packs=%s" % JSON.stringify(run_state.active_card_packs))
		return true
	if run_state.active_card_packs.size() >= max_active:
		print("[Shop] cannot enable pack=%s max_active_card_packs=%d" % [pack_id, max_active])
		return false
	run_state.active_card_packs.append(pack_id)
	print("[Shop] toggle pack=%s enabled=true" % pack_id)
	print("[Shop] active_card_packs=%s" % JSON.stringify(run_state.active_card_packs))
	return true


func max_active_card_packs(run_state) -> int:
	var max_active := int(card_pack_config.get("max_active_card_packs", 2))
	var rules := _as_dictionary(card_pack_config.get("card_pack_unlock_and_toggle_rules", {}))
	if rules.has("max_active_card_packs"):
		max_active = int(rules.get("max_active_card_packs", max_active))
	if str(run_state.selected_cultivator_id) == "wanderer_cultivator":
		max_active += 1
	return max_active


func shop_name() -> String:
	return str(shop_config.get("shop_name", "霧中散修攤"))


func heal_price() -> int:
	return int(_prices().get("heal_flat", HEAL_PRICE))


func heal_amount() -> int:
	return int(_as_dictionary(shop_config.get("heal", {})).get("amount", HEAL_AMOUNT))


func remove_price() -> int:
	return int(_prices().get("remove_card_base", REMOVE_CARD_PRICE))


func _packs_from_config() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var offers := _as_dictionary(card_pack_config.get("shop_card_pack_offers", {}))
	for key in ["available_single_packs", "available_dual_packs", "available_multi_packs"]:
		for item in offers.get(key, []):
			if item is Dictionary:
				result.append(_normalize_pack(item))
	if not result.is_empty():
		return result
	for item in FALLBACK_PACKS:
		result.append(_normalize_pack(item))
	return result


func _normalize_pack(pack: Dictionary) -> Dictionary:
	var id := str(pack.get("id", ""))
	var elements := _to_string_array(pack.get("elements", []))
	if elements.is_empty() and str(pack.get("element", "")) != "":
		elements.append(str(pack.get("element", "")))
	if elements.is_empty():
		elements = _elements_from_pack_id(id)
	var name := str(pack.get("display_name", pack.get("name", id)))
	return {
		"id": id,
		"display_name": name,
		"elements": elements,
		"description": str(pack.get("description", "影響後續卡牌獎勵傾向。")),
	}


func _elements_from_pack_id(pack_id: String) -> Array[String]:
	if pack_id == "pack_five_elements" or pack_id == "pack_mixed_five_elements":
		return ["metal", "wood", "water", "fire", "earth"]
	if pack_id.begins_with("pack_"):
		return _to_string_array(pack_id.trim_prefix("pack_").split("_", false))
	return [pack_id]


func _prices() -> Dictionary:
	return _as_dictionary(shop_config.get("prices", {}))


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("[Shop] config not found: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[Shop] could not open config: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("[Shop] could not parse config: %s" % path)
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
