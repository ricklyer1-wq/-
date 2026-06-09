extends Control

const RewardManagerScript = preload("res://scripts/reward/RewardManager.gd")
const ChapterDatabaseScript = preload("res://scripts/chapter/ChapterDatabase.gd")
const CardViewScene = preload("res://scenes/battle/CardView.tscn")
const MAP_SCENE_PATH := "res://scenes/map/MapScene.tscn"
const CHAPTER_ENDING_SCENE_PATH := "res://scenes/ending/ChapterEndingScene.tscn"
const SKIP_GOLD := 10
const UI_PRIMARY_TEXT := Color("#F2EBDD")
const UI_SECONDARY_TEXT := Color("#CFC8BD")
const UI_ENERGY_TEXT := Color("#E3C76A")
const UI_PANEL_BG := Color(0.063, 0.078, 0.102, 0.58)
const UI_PANEL_BORDER := Color("#7C8D93")
const UI_TEXT_SHADOW := Color(0.0, 0.0, 0.0, 0.75)

var _reward_manager = RewardManagerScript.new()
var _chapter_db = ChapterDatabaseScript.new()
var _cards_list: VBoxContainer
var _status_label: Label
var _reward_options: Array[CardData] = []
var _is_resolving := false


func _ready() -> void:
	_build_ui()
	_chapter_db.load_from_file()
	_ensure_run_state()
	print("[Chapter01Test] enter reward")
	_load_or_generate_rewards()
	_render_rewards()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#10141a")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var safe := MarginContainer.new()
	safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 24)
	safe.add_theme_constant_override("margin_top", 28)
	safe.add_theme_constant_override("margin_right", 24)
	safe.add_theme_constant_override("margin_bottom", 24)
	add_child(safe)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	safe.add_child(root)

	var title := Label.new()
	title.text = "戰鬥勝利"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	_apply_readable_label(title, UI_ENERGY_TEXT)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "選擇一張法訣"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 32)
	_apply_readable_label(subtitle, UI_SECONDARY_TEXT)
	root.add_child(subtitle)

	_status_label = Label.new()
	_status_label.custom_minimum_size = Vector2(0, 54)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 24)
	_apply_readable_label(_status_label, UI_SECONDARY_TEXT)
	root.add_child(_status_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_cards_list = VBoxContainer.new()
	_cards_list.add_theme_constant_override("separation", 18)
	_cards_list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	scroll.add_child(_cards_list)

	var skip_button := Button.new()
	skip_button.text = "跳過：獲得 10 靈石"
	skip_button.custom_minimum_size = Vector2(0, 92)
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.add_theme_font_size_override("font_size", 32)
	skip_button.add_theme_color_override("font_color", UI_PRIMARY_TEXT)
	skip_button.add_theme_color_override("font_hover_color", UI_ENERGY_TEXT)
	skip_button.add_theme_color_override("font_shadow_color", UI_TEXT_SHADOW)
	skip_button.add_theme_constant_override("shadow_offset_x", 2)
	skip_button.add_theme_constant_override("shadow_offset_y", 2)
	skip_button.add_theme_stylebox_override("normal", _button_style(UI_PANEL_BG))
	skip_button.add_theme_stylebox_override("hover", _button_style(Color(0.080, 0.105, 0.122, 0.68)))
	skip_button.add_theme_stylebox_override("pressed", _button_style(Color(0.050, 0.063, 0.082, 0.76)))
	skip_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	skip_button.pressed.connect(_on_skip_pressed)
	root.add_child(skip_button)


func _ensure_run_state() -> void:
	if RunManager.state.selected_cultivator_id.is_empty():
		RunManager.start_new_run("fire_cultivator")
	if RunManager.state.current_chapter_id.is_empty():
		RunManager.state.current_chapter_id = _chapter_db.get_chapter_id()
	if RunManager.state.current_node_id.is_empty():
		RunManager.state.current_node_id = _chapter_db.get_start_node_id()
	if not RunManager.state.flags.has("pending_reward_type"):
		RunManager.state.flags["pending_reward_type"] = _reward_type_for_current_node()


func _load_or_generate_rewards() -> void:
	var state = RunManager.state
	var reward_type := str(state.flags.get("pending_reward_type", _reward_type_for_current_node()))
	var pending: Dictionary = state.pending_card_reward
	var option_ids := _to_string_array(pending.get("options", []))

	if option_ids.is_empty():
		_reward_options = _reward_manager.generate_card_reward(state, reward_type)
		var generated_ids: Array[String] = []
		for card in _reward_options:
			generated_ids.append(card.id)
		state.pending_card_reward = {
			"reward_type": reward_type,
			"options": generated_ids,
		}
	else:
		_reward_options.clear()
		for card_id in option_ids:
			var record := GameData.get_card_by_id(card_id)
			if not record.is_empty():
				_reward_options.append(_card_data_from_record(record))
		_status_label.text = "已載入暫存獎勵。"


func _render_rewards() -> void:
	for child in _cards_list.get_children():
		child.queue_free()

	if _reward_options.is_empty():
		_status_label.text = "沒有可用的卡牌獎勵。"
		return

	_status_label.text = "目前節點：%s / 牌組：%d 張 / 靈石：%d" % [
		RunManager.state.current_node_id,
		RunManager.state.deck.size(),
		RunManager.state.gold,
	]

	for card in _reward_options:
		var card_view = CardViewScene.instantiate()
		card_view.card_clicked.connect(_on_card_picked)
		card_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_cards_list.add_child(card_view)
		card_view.setup(card, false, "reward_display")


func _on_card_picked(card_data: CardData) -> void:
	if _is_resolving or card_data == null:
		return
	_is_resolving = true
	RunManager.state.deck.append(card_data.id)
	RunManager.state.last_reward_choice = card_data.id
	print("[Reward] picked card=%s" % card_data.id)
	print("[Reward] deck size=%d" % RunManager.state.deck.size())
	_complete_current_node_and_return()


func _on_skip_pressed() -> void:
	if _is_resolving:
		return
	_is_resolving = true
	RunManager.state.gold += SKIP_GOLD
	RunManager.state.last_reward_choice = "skip"
	print("[Reward] skipped reward gold +%d" % SKIP_GOLD)
	print("[Reward] gold=%d" % RunManager.state.gold)
	_complete_current_node_and_return()


func _complete_current_node_and_return() -> void:
	var state = RunManager.state
	var completed_node_id: String = state.current_node_id
	if not completed_node_id.is_empty() and not state.completed_node_ids.has(completed_node_id):
		state.completed_node_ids.append(completed_node_id)
		print("[Reward] completed node=%s" % completed_node_id)
	if not completed_node_id.is_empty():
		print("[Chapter01Test] complete node=%s" % completed_node_id)

	var next_node_id := _chapter_db.get_next_node_id(completed_node_id)
	if next_node_id.is_empty():
		next_node_id = _chapter_db.get_first_incomplete_node_id(state.completed_node_ids)
	state.current_node_id = next_node_id
	if not next_node_id.is_empty():
		print("[Chapter01Test] unlock node=%s" % next_node_id)
	state.pending_card_reward.clear()
	state.flags.erase("pending_reward_type")
	if _chapter_db.normalize_node_type(str(_chapter_db.get_node(completed_node_id).get("type", ""))) == "boss":
		print("[Chapter01Test] enter ending")
		print("[Reward] return to ChapterEndingScene")
		get_tree().change_scene_to_file(CHAPTER_ENDING_SCENE_PATH)
	else:
		print("[Chapter01Test] return map")
		print("[Reward] return to MapScene")
		get_tree().change_scene_to_file(MAP_SCENE_PATH)


func _reward_type_for_current_node() -> String:
	var node := _chapter_db.get_node(RunManager.state.current_node_id)
	var reward_type := str(node.get("reward_type", ""))
	if not reward_type.is_empty():
		return reward_type
	match _chapter_db.normalize_node_type(str(node.get("type", ""))):
		"elite", "story_elite":
			return "elite_combat"
		"boss":
			return "boss_combat"
		_:
			return "normal_combat"


func _card_data_from_record(card: Dictionary) -> CardData:
	var element := str(card.get("element", ""))
	if element.is_empty():
		element = str(card.get("main_element", ""))
	return CardData.new(
		str(card.get("id", "")),
		str(card.get("name", "")),
		element,
		str(card.get("type", "")),
		card.get("cost", 0),
		str(card.get("description", "")),
		str(card.get("rarity", "N")),
		card.get("effects", []),
		str(card.get("target_type", "enemy"))
	)


func _to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result


func _apply_readable_label(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", UI_TEXT_SHADOW)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)


func _button_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = UI_PANEL_BORDER
	return style
