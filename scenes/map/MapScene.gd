extends Control

const ChapterDatabaseScript = preload("res://scripts/chapter/ChapterDatabase.gd")
const BATTLE_SCENE_PATH := "res://scenes/battle/BattleScene.tscn"
const EVENT_SCENE_PATH := "res://scenes/event/EventScene.tscn"
const SHOP_SCENE_PATH := "res://scenes/shop/ShopScene.tscn"
const MAP_UI_CONFIG_PATH := "res://data/config/map_ui_v1.json"
const MAP_CHAPTER_TITLE := "第一章：墨霧染血"
const CHAPTER_PANEL_COLLAPSED_HEIGHT := 38
const CHAPTER_PANEL_EXPANDED_HEIGHT := 104

const NODE_TYPE_LABELS := {
	"combat": "戰",
	"elite_choice": "菁",
	"story_elite_combat": "強",
	"event": "事",
	"shop": "商",
	"rest_or_upgrade": "息",
	"boss_combat": "Boss",
}

const NODE_TYPE_COLORS := {
	"combat": Color("#d8c8a4"),
	"elite_choice": Color("#e8a96d"),
	"story_elite_combat": Color("#d56f75"),
	"event": Color("#a8d7d1"),
	"shop": Color("#e3c76a"),
	"rest_or_upgrade": Color("#7edb9a"),
	"boss_combat": Color("#e06a6a"),
}

var _chapter_db = ChapterDatabaseScript.new()
var _map_ui: Dictionary = {}
var _node_positions: Dictionary = {}
var _title_label: Label
var _subtitle_label: Label
var _summary_label: Label
var _boss_label: Label
var _status_label: Label
var _node_layer: Control
var _top_panel: PanelContainer
var _chapter_toggle_button: Button
var _chapter_details: VBoxContainer
var _chapter_panel_collapsed := true
var _is_transitioning := false


func _ready() -> void:
	_chapter_db.load_from_file()
	_load_map_ui()
	_build_ui()
	_ensure_run_state()
	_refresh()


func _build_ui() -> void:
	var background := TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture = _load_texture(str(_map_ui.get("background", "res://assets/maps/chapter_01_map_bg.png")))
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.018, 0.026, 0.18)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	_node_layer = Control.new()
	_node_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_node_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	_node_layer.z_index = 1
	add_child(_node_layer)

	_top_panel = PanelContainer.new()
	_top_panel.anchor_left = 0.04
	_top_panel.anchor_top = 0.02
	_top_panel.anchor_right = 0.96
	_top_panel.anchor_bottom = 0.0
	_top_panel.offset_bottom = CHAPTER_PANEL_COLLAPSED_HEIGHT
	_top_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_top_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.063, 0.078, 0.102, 0.52), Color(0.486, 0.553, 0.576, 0.38), 14))
	add_child(_top_panel)

	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 12)
	top_margin.add_theme_constant_override("margin_top", 4)
	top_margin.add_theme_constant_override("margin_right", 12)
	top_margin.add_theme_constant_override("margin_bottom", 6)
	top_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	_top_panel.add_child(top_margin)

	var top_root := VBoxContainer.new()
	top_root.add_theme_constant_override("separation", 2)
	top_root.mouse_filter = Control.MOUSE_FILTER_PASS
	top_margin.add_child(top_root)

	_chapter_toggle_button = Button.new()
	_chapter_toggle_button.custom_minimum_size = Vector2(0, 30)
	_chapter_toggle_button.focus_mode = Control.FOCUS_NONE
	_chapter_toggle_button.flat = true
	_chapter_toggle_button.add_theme_font_size_override("font_size", 20)
	_chapter_toggle_button.add_theme_color_override("font_color", Color("#f2ebdd"))
	_chapter_toggle_button.add_theme_color_override("font_hover_color", Color("#e3c76a"))
	_chapter_toggle_button.add_theme_color_override("font_pressed_color", Color("#a8d7d1"))
	_chapter_toggle_button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.78))
	_chapter_toggle_button.add_theme_constant_override("shadow_offset_x", 2)
	_chapter_toggle_button.add_theme_constant_override("shadow_offset_y", 2)
	_chapter_toggle_button.pressed.connect(_toggle_chapter_panel)
	top_root.add_child(_chapter_toggle_button)

	_chapter_details = VBoxContainer.new()
	_chapter_details.add_theme_constant_override("separation", 2)
	_chapter_details.visible = false
	top_root.add_child(_chapter_details)

	_title_label = Label.new()
	_title_label.visible = false

	_subtitle_label = Label.new()
	_subtitle_label.add_theme_font_size_override("font_size", 11)
	_apply_readable_label(_subtitle_label, Color("#cfc8bd"))
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_details.add_child(_subtitle_label)

	_summary_label = Label.new()
	_summary_label.add_theme_font_size_override("font_size", 11)
	_apply_readable_label(_summary_label, Color("#e3c76a"))
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_details.add_child(_summary_label)

	_boss_label = Label.new()
	_boss_label.add_theme_font_size_override("font_size", 11)
	_apply_readable_label(_boss_label, Color("#e06a6a"))
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_chapter_details.add_child(_boss_label)

	_status_label = Label.new()
	_status_label.anchor_left = 0.05
	_status_label.anchor_top = 0.94
	_status_label.anchor_right = 0.95
	_status_label.anchor_bottom = 0.94
	_status_label.offset_top = -42
	_status_label.offset_bottom = 18
	_status_label.add_theme_font_size_override("font_size", 24)
	_apply_readable_label(_status_label, Color("#a8d7d1"))
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status_label)

	var actions := HBoxContainer.new()
	actions.anchor_left = 0.05
	actions.anchor_top = 0.96
	actions.anchor_right = 0.95
	actions.anchor_bottom = 0.96
	actions.offset_top = -8
	actions.offset_bottom = 76
	actions.add_theme_constant_override("separation", 12)
	add_child(actions)

	var complete_button := _make_action_button("完成目前節點")
	complete_button.pressed.connect(_on_mark_current_completed)
	actions.add_child(complete_button)

	var refresh_button := _make_action_button("刷新")
	refresh_button.pressed.connect(_refresh)
	actions.add_child(refresh_button)

	var debug_start_button := _make_action_button("Debug Run")
	debug_start_button.pressed.connect(_on_start_chapter_01_debug_run_pressed)
	actions.add_child(debug_start_button)


func _load_map_ui() -> void:
	var config := _as_dictionary(_load_json(MAP_UI_CONFIG_PATH))
	var chapter_maps := _as_dictionary(config.get("chapter_maps", {}))
	var map_id := str(_chapter_db.chapter.get("map_ui_id", _chapter_db.get_chapter_id()))
	_map_ui = _as_dictionary(chapter_maps.get(map_id, {}))
	_node_positions = _as_dictionary(_map_ui.get("node_positions", {}))


func _toggle_chapter_panel() -> void:
	_chapter_panel_collapsed = not _chapter_panel_collapsed
	_update_chapter_panel()


func _update_chapter_panel() -> void:
	if _top_panel == null or _chapter_toggle_button == null:
		return
	_top_panel.offset_bottom = CHAPTER_PANEL_COLLAPSED_HEIGHT if _chapter_panel_collapsed else CHAPTER_PANEL_EXPANDED_HEIGHT
	_chapter_toggle_button.text = "%s    %s" % [MAP_CHAPTER_TITLE, "▼" if _chapter_panel_collapsed else "▲"]
	if _chapter_details != null:
		_chapter_details.visible = not _chapter_panel_collapsed


func _ensure_run_state() -> void:
	if RunManager.state.selected_cultivator_id.is_empty():
		RunManager.start_new_run("fire_cultivator")
	if RunManager.state.current_chapter_id.is_empty():
		RunManager.state.current_chapter_id = _chapter_db.get_chapter_id()
	if RunManager.state.current_node_id.is_empty():
		RunManager.state.current_node_id = _available_node_id()


func _refresh() -> void:
	_title_label.text = MAP_CHAPTER_TITLE
	_subtitle_label.text = _chapter_db.get_chapter_subtitle()
	_summary_label.text = "目標：沿山路抵達核心祭壇，擊敗血霧源頭。"
	_boss_label.text = _boss_info_text()
	_update_chapter_panel()

	for child in _node_layer.get_children():
		child.queue_free()

	var available_node_id := _available_node_id()
	if not available_node_id.is_empty() and _chapter_db.get_node(RunManager.state.current_node_id).is_empty():
		RunManager.state.current_node_id = available_node_id

	for node in _chapter_db.get_nodes():
		_node_layer.add_child(_make_map_node_button(node, available_node_id))

	_status_label.text = "目前可進入：%s" % (available_node_id if not available_node_id.is_empty() else "無，第一章已完成")


func _make_map_node_button(node: Dictionary, available_node_id: String) -> Button:
	var node_id := str(node.get("id", ""))
	var node_type := str(node.get("type", ""))
	var completed: bool = RunManager.state.completed_node_ids.has(node_id)
	var available: bool = node_id == available_node_id
	var position := _as_dictionary(_node_positions.get(node_id, {}))
	var anchor_position := _node_anchor_position(position)
	var x := anchor_position.x
	var y := anchor_position.y
	var size := _node_button_size(node_type)

	var button := Button.new()
	button.text = "%s\n%s" % [str(NODE_TYPE_LABELS.get(node_type, node_type)), str(node.get("index", ""))]
	button.tooltip_text = "%s\n%s" % [str(node.get("display_name", node_id)), _node_state_text(available, completed)]
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not available
	button.anchor_left = x
	button.anchor_top = y
	button.anchor_right = x
	button.anchor_bottom = y
	button.offset_left = -size.x * 0.5
	button.offset_top = -size.y * 0.5
	button.offset_right = size.x * 0.5
	button.offset_bottom = size.y * 0.5
	button.add_theme_font_size_override("font_size", 22 if node_type != "boss_combat" else 20)
	button.add_theme_color_override("font_color", Color("#f2ebdd"))
	button.add_theme_color_override("font_disabled_color", Color("#afa79b"))
	button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.78))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)
	button.add_theme_stylebox_override("normal", _node_style(node_type, available, completed))
	button.add_theme_stylebox_override("hover", _node_style(node_type, true, completed))
	button.add_theme_stylebox_override("pressed", _node_style(node_type, true, completed))
	button.add_theme_stylebox_override("disabled", _node_style(node_type, false, completed))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(func() -> void:
		_on_node_pressed(node_id)
	)
	return button


func _node_anchor_position(position: Dictionary) -> Vector2:
	var x := float(position.get("x", 180.0))
	var y := float(position.get("y", 320.0))
	if x <= 1.0 and y <= 1.0:
		return Vector2(x, y)
	var base_width: float = max(1.0, float(_map_ui.get("base_width", 360.0)))
	var base_height: float = max(1.0, float(_map_ui.get("base_height", 640.0)))
	return Vector2(clampf(x / base_width, 0.0, 1.0), clampf(y / base_height, 0.0, 1.0))


func _on_node_pressed(node_id: String) -> void:
	if _is_transitioning:
		return
	var node := _chapter_db.get_node(node_id)
	if node.is_empty():
		return

	RunManager.state.current_chapter_id = _chapter_db.get_chapter_id()
	RunManager.state.current_node_id = node_id

	var node_type := str(node.get("type", ""))
	var normalized := _chapter_db.normalize_node_type(node_type)
	var reward_type := str(node.get("reward_type", ""))
	if not reward_type.is_empty():
		RunManager.state.flags["pending_reward_type"] = reward_type

	_log_chapter01_enter(node_id, normalized)
	match normalized:
		"combat":
			print("[Map] enter combat node %s" % node_id)
			_is_transitioning = true
			get_tree().change_scene_to_file(BATTLE_SCENE_PATH)
		"elite":
			RunManager.state.flags["pending_reward_type"] = "elite_combat"
			print("[Map] enter elite node %s" % node_id)
			_is_transitioning = true
			get_tree().change_scene_to_file(BATTLE_SCENE_PATH)
		"story_elite":
			RunManager.state.flags["pending_reward_type"] = "elite_combat"
			print("[Map] enter story elite node %s" % node_id)
			_is_transitioning = true
			get_tree().change_scene_to_file(BATTLE_SCENE_PATH)
		"boss":
			RunManager.state.flags["pending_reward_type"] = "boss_combat"
			print("[Map] enter boss node %s" % node_id)
			_is_transitioning = true
			get_tree().change_scene_to_file(BATTLE_SCENE_PATH)
		"event":
			print("[Map] enter event %s" % node_id)
			_is_transitioning = true
			get_tree().change_scene_to_file(EVENT_SCENE_PATH)
		"shop":
			print("[Map] enter shop")
			_is_transitioning = true
			get_tree().change_scene_to_file(SHOP_SCENE_PATH)
		"rest":
			print("[Map] enter rest")
			_complete_node_and_set_next(node_id)
			print("[Chapter01Test] return map")
			_refresh()
		_:
			print("[Map] enter node %s type=%s" % [node_id, node_type])
			_complete_node_and_set_next(node_id)
			print("[Chapter01Test] return map")
			_refresh()


func _on_mark_current_completed() -> void:
	var node_id: String = RunManager.state.current_node_id
	if node_id.is_empty():
		node_id = _available_node_id()
	if node_id.is_empty():
		_status_label.text = "沒有可完成的節點。"
		return

	if not RunManager.state.completed_node_ids.has(node_id):
		RunManager.state.completed_node_ids.append(node_id)
		print("[Map] completed node %s" % node_id)
	print("[Chapter01Test] complete node=%s" % node_id)

	var next_id := _chapter_db.get_next_node_id(node_id)
	if next_id.is_empty():
		next_id = _available_node_id()
	RunManager.state.current_node_id = next_id
	if not next_id.is_empty():
		print("[Chapter01Test] unlock node=%s" % next_id)
	print("[Chapter01Test] return map")
	_refresh()


func _complete_node_and_set_next(node_id: String) -> void:
	if node_id.is_empty():
		return
	if not RunManager.state.completed_node_ids.has(node_id):
		RunManager.state.completed_node_ids.append(node_id)
		print("[Map] completed node %s" % node_id)
	print("[Chapter01Test] complete node=%s" % node_id)

	var next_id := _chapter_db.get_next_node_id(node_id)
	if next_id.is_empty():
		next_id = _available_node_id()
	RunManager.state.current_node_id = next_id
	if not next_id.is_empty():
		print("[Chapter01Test] unlock node=%s" % next_id)


func _on_start_chapter_01_debug_run_pressed() -> void:
	print("[Debug] start chapter 01 debug run")
	_is_transitioning = false
	RunManager.start_chapter_01_debug_run()
	_refresh()


func _available_node_id() -> String:
	return _chapter_db.get_first_incomplete_node_id(RunManager.state.completed_node_ids)


func _log_chapter01_enter(node_id: String, node_type: String) -> void:
	print("[Chapter01Test] enter node=%s type=%s" % [node_id, node_type])


func _run_summary_text() -> String:
	var state = RunManager.state
	return "%s / HP %d/%d / 靈石 %d / %s" % [
		state.selected_cultivator_id,
		state.current_hp,
		state.max_hp,
		state.gold,
		", ".join(state.active_card_packs),
	]


func _boss_info_text() -> String:
	var boss := _chapter_db.get_node("boss_001")
	if boss.is_empty():
		return "Boss：核心祭壇"
	return "Boss：%s" % str(boss.get("display_name", "核心祭壇"))


func _node_button_size(node_type: String) -> Vector2:
	if node_type == "boss_combat":
		return Vector2(116, 92)
	return Vector2(88, 78)


func _node_state_text(available: bool, completed: bool) -> String:
	if completed:
		return "已完成"
	if available:
		return "可進入"
	return "未解鎖"


func _node_style(node_type: String, available: bool, completed: bool) -> StyleBoxFlat:
	var type_color: Color = NODE_TYPE_COLORS.get(node_type, Color("#d8c8a4"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.063, 0.078, 0.102, 0.58)
	if completed:
		style.bg_color = Color(0.12, 0.14, 0.14, 0.50)
		type_color = Color("#bfc5c2")
	elif not available:
		style.bg_color = Color(0.055, 0.057, 0.063, 0.44)
		type_color = Color("#6f7178")
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.border_width_left = 4 if available else 2
	style.border_width_top = 4 if available else 2
	style.border_width_right = 4 if available else 2
	style.border_width_bottom = 4 if available else 2
	style.border_color = type_color
	return style


func _make_action_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 72)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 24)
	button.focus_mode = Control.FOCUS_NONE
	return button


func _panel_style(bg_color: Color, border_color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func _apply_readable_label(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.78))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var texture := load(path)
		if texture is Texture2D:
			return texture
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(ProjectSettings.globalize_path(path)) == OK:
			return ImageTexture.create_from_image(image)
	return null


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Map UI config not found: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open Map UI config: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed != null else {}


func _as_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}
