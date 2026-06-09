extends Control

const ShopManagerScript = preload("res://scripts/shop/ShopManager.gd")
const ChapterDatabaseScript = preload("res://scripts/chapter/ChapterDatabase.gd")
const MAP_SCENE_PATH := "res://scenes/map/MapScene.tscn"
const MIN_DECK_SIZE := 5

var _shop_manager = ShopManagerScript.new()
var _chapter_db = ChapterDatabaseScript.new()
var _offers: Array[Dictionary] = []
var _title_label: Label
var _summary_label: Label
var _status_label: Label
var _cards_box: VBoxContainer
var _services_box: VBoxContainer
var _deck_box: VBoxContainer
var _packs_box: VBoxContainer
var _is_leaving := false


func _ready() -> void:
	_shop_manager.load_configs()
	_chapter_db.load_from_file()
	_ensure_run_state()
	_build_ui()
	_enter_shop()
	_generate_offers_once()
	_refresh()


func _ensure_run_state() -> void:
	if RunManager.state.selected_cultivator_id.is_empty():
		RunManager.start_new_run("fire_cultivator")
	if RunManager.state.current_chapter_id.is_empty():
		RunManager.state.current_chapter_id = _chapter_db.get_chapter_id()
	if RunManager.state.current_node_id.is_empty():
		RunManager.state.current_node_id = "node_006"
	var node := _chapter_db.get_node(RunManager.state.current_node_id)
	if _chapter_db.normalize_node_type(str(node.get("type", ""))) != "shop":
		RunManager.state.current_node_id = "node_006"


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#14161e")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var safe := MarginContainer.new()
	safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 28)
	safe.add_theme_constant_override("margin_top", 34)
	safe.add_theme_constant_override("margin_right", 28)
	safe.add_theme_constant_override("margin_bottom", 28)
	add_child(safe)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	safe.add_child(root)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 46)
	_title_label.add_theme_color_override("font_color", Color("#fff0ba"))
	root.add_child(_title_label)

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_label.add_theme_font_size_override("font_size", 24)
	_summary_label.add_theme_color_override("font_color", Color("#d9ebce"))
	root.add_child(_summary_label)

	_status_label = Label.new()
	_status_label.custom_minimum_size = Vector2(0, 52)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 22)
	_status_label.add_theme_color_override("font_color", Color("#ffd98a"))
	root.add_child(_status_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)

	_cards_box = _add_section(content, "卡牌販售")
	_services_box = _add_section(content, "服務")
	_deck_box = _add_section(content, "移除卡牌")
	_packs_box = _add_section(content, "卡牌包偏向")

	var leave_button := Button.new()
	leave_button.text = "離開商店"
	leave_button.custom_minimum_size = Vector2(0, 94)
	leave_button.focus_mode = Control.FOCUS_NONE
	leave_button.add_theme_font_size_override("font_size", 32)
	leave_button.pressed.connect(_on_leave_pressed)
	root.add_child(leave_button)


func _enter_shop() -> void:
	print("[Shop] enter node=%s gold=%d hp=%d/%d" % [
		RunManager.state.current_node_id,
		RunManager.state.gold,
		RunManager.state.current_hp,
		RunManager.state.max_hp,
	])


func _generate_offers_once() -> void:
	if _offers.is_empty():
		_offers = _shop_manager.generate_shop_offers(RunManager.state)


func _refresh() -> void:
	_title_label.text = _shop_manager.shop_name()
	_summary_label.text = "靈石：%d / HP：%d/%d / 啟用卡牌包：%s" % [
		RunManager.state.gold,
		RunManager.state.current_hp,
		RunManager.state.max_hp,
		", ".join(RunManager.state.active_card_packs),
	]
	_render_card_offers()
	_render_services()
	_render_deck_remove()
	_render_packs()


func _render_card_offers() -> void:
	_clear_box(_cards_box)
	for offer_index in range(_offers.size()):
		var offer := _offers[offer_index]
		var card: CardData = offer.get("card", null)
		if card == null:
			continue
		var price := int(offer.get("price", 0))
		var sold := bool(offer.get("sold", false))
		var button := _make_row_button("%s [%s] %d 靈石\n%s" % [card.name, card.rarity, price, card.id])
		button.disabled = sold
		var idx: int = offer_index
		button.pressed.connect(func() -> void:
			_on_buy_offer_pressed(idx)
		)
		_cards_box.add_child(button)


func _render_services() -> void:
	_clear_box(_services_box)
	var heal_button := _make_row_button("療傷：%d 靈石，恢復 %d HP" % [_shop_manager.heal_price(), _shop_manager.heal_amount()])
	heal_button.disabled = RunManager.state.current_hp >= RunManager.state.max_hp
	heal_button.pressed.connect(_on_heal_pressed)
	_services_box.add_child(heal_button)


func _render_deck_remove() -> void:
	_clear_box(_deck_box)
	var info := Label.new()
	info.text = "移除費用：%d 靈石。牌組至少保留 %d 張。" % [_shop_manager.remove_price(), MIN_DECK_SIZE]
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 20)
	info.add_theme_color_override("font_color", Color("#d7ccb8"))
	_deck_box.add_child(info)

	var shown := 0
	var seen: Dictionary = {}
	for card_id in RunManager.state.deck:
		if seen.has(card_id):
			continue
		seen[card_id] = true
		var button := _make_row_button("移除 %s" % card_id)
		button.disabled = RunManager.state.deck.size() <= MIN_DECK_SIZE
		button.pressed.connect(func(id: String = card_id) -> void:
			_on_remove_card_pressed(id)
		)
		_deck_box.add_child(button)
		shown += 1
		if shown >= 8:
			break


func _render_packs() -> void:
	_clear_box(_packs_box)
	var max_active := _shop_manager.max_active_card_packs(RunManager.state)
	var counter := Label.new()
	counter.text = "已啟用 %d / %d 個。切換只影響後續卡牌獎勵。" % [RunManager.state.active_card_packs.size(), max_active]
	counter.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	counter.add_theme_font_size_override("font_size", 20)
	counter.add_theme_color_override("font_color", Color("#d7ccb8"))
	_packs_box.add_child(counter)

	for pack in _shop_manager.get_available_packs(RunManager.state):
		var pack_id := str(pack.get("id", ""))
		var active: bool = RunManager.state.active_card_packs.has(pack_id)
		var elements := ", ".join(_to_string_array(pack.get("elements", [])))
		var label := "%s %s\n%s / %s" % [
			"已啟用" if active else "未啟用",
			str(pack.get("display_name", pack_id)),
			pack_id,
			elements,
		]
		var button := _make_row_button(label)
		button.pressed.connect(func(id: String = pack_id) -> void:
			_on_toggle_pack_pressed(id)
		)
		_packs_box.add_child(button)


func _on_buy_offer_pressed(offer_index: int) -> void:
	if offer_index < 0 or offer_index >= _offers.size():
		return
	var offer := _offers[offer_index]
	if not _shop_manager.buy_offer(RunManager.state, offer):
		_status_label.text = "靈石不足，或商品已售出。"
	else:
		_status_label.text = "已購買 %s。" % str(offer.get("card_id", ""))
	_refresh()


func _on_heal_pressed() -> void:
	if not _shop_manager.heal(RunManager.state):
		_status_label.text = "無法療傷：靈石不足或氣血已滿。"
	else:
		_status_label.text = "療傷完成。"
	_refresh()


func _on_remove_card_pressed(card_id: String) -> void:
	if not _shop_manager.remove_card(RunManager.state, card_id):
		_status_label.text = "無法移除：靈石不足、牌組太少，或找不到卡。"
	else:
		_status_label.text = "已移除 %s。" % card_id
	_refresh()


func _on_toggle_pack_pressed(pack_id: String) -> void:
	if not _shop_manager.toggle_pack(RunManager.state, pack_id):
		_status_label.text = "本局最多啟用 %d 個卡牌包。" % _shop_manager.max_active_card_packs(RunManager.state)
	else:
		_status_label.text = "已更新卡牌包偏向。"
	_refresh()


func _on_leave_pressed() -> void:
	if _is_leaving:
		return
	_is_leaving = true
	var node_id: String = RunManager.state.current_node_id
	if not node_id.is_empty() and not RunManager.state.completed_node_ids.has(node_id):
		RunManager.state.completed_node_ids.append(node_id)
		print("[Shop] leave completed node=%s" % node_id)
	if not node_id.is_empty():
		print("[Chapter01Test] complete node=%s" % node_id)
	var next_id := _chapter_db.get_next_node_id(node_id)
	if next_id.is_empty():
		next_id = _chapter_db.get_first_incomplete_node_id(RunManager.state.completed_node_ids)
	RunManager.state.current_node_id = next_id
	if not next_id.is_empty():
		print("[Chapter01Test] unlock node=%s" % next_id)
	print("[Chapter01Test] return map")
	print("[Shop] return to MapScene")
	get_tree().change_scene_to_file(MAP_SCENE_PATH)


func _add_section(parent: VBoxContainer, title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color("#fff0ba"))
	box.add_child(label)
	return box


func _make_row_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 86)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 22)
	return button


func _clear_box(box: VBoxContainer) -> void:
	for child in box.get_children():
		if child is Label and child.get_index() == 0:
			continue
		child.queue_free()


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#232635")
	style.border_color = Color("#6b6049")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result
