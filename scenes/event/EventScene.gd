extends Control

const EventManagerScript = preload("res://scripts/event/EventManager.gd")
const ChapterDatabaseScript = preload("res://scripts/chapter/ChapterDatabase.gd")
const MAP_SCENE_PATH := "res://scenes/map/MapScene.tscn"

var _event_manager = EventManagerScript.new()
var _chapter_db = ChapterDatabaseScript.new()
var _event: Dictionary = {}
var _event_id := ""
var _title_label: Label
var _body_label: Label
var _summary_label: Label
var _choice_list: VBoxContainer
var _is_resolving := false


func _ready() -> void:
	_build_ui()
	_event_manager.load_from_file()
	_chapter_db.load_from_file()
	_ensure_run_state()
	_load_event_for_current_node()
	_render_event()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#13151b")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var safe := MarginContainer.new()
	safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 32)
	safe.add_theme_constant_override("margin_top", 44)
	safe.add_theme_constant_override("margin_right", 32)
	safe.add_theme_constant_override("margin_bottom", 36)
	add_child(safe)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 22)
	safe.add_child(root)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 52)
	_title_label.add_theme_color_override("font_color", Color("#fff1c2"))
	root.add_child(_title_label)

	_summary_label = Label.new()
	_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_label.add_theme_font_size_override("font_size", 22)
	_summary_label.add_theme_color_override("font_color", Color("#bfe6cc"))
	root.add_child(_summary_label)

	var body_panel := PanelContainer.new()
	body_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_panel.add_theme_stylebox_override("panel", _body_style())
	root.add_child(body_panel)

	var body_margin := MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 28)
	body_margin.add_theme_constant_override("margin_top", 28)
	body_margin.add_theme_constant_override("margin_right", 28)
	body_margin.add_theme_constant_override("margin_bottom", 28)
	body_panel.add_child(body_margin)

	_body_label = Label.new()
	_body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.add_theme_font_size_override("font_size", 32)
	_body_label.add_theme_color_override("font_color", Color("#eadfcb"))
	body_margin.add_child(_body_label)

	_choice_list = VBoxContainer.new()
	_choice_list.add_theme_constant_override("separation", 14)
	root.add_child(_choice_list)


func _ensure_run_state() -> void:
	if RunManager.state.selected_cultivator_id.is_empty():
		RunManager.start_new_run("fire_cultivator")
	if RunManager.state.current_chapter_id.is_empty():
		RunManager.state.current_chapter_id = _chapter_db.get_chapter_id()
	if RunManager.state.current_node_id.is_empty():
		RunManager.state.current_node_id = _chapter_db.get_start_node_id()


func _load_event_for_current_node() -> void:
	var node := _chapter_db.get_node(RunManager.state.current_node_id)
	_event_id = _event_manager.resolve_event_id(node)
	_event = _event_manager.get_event(_event_id)
	if str(_event.get("id", "")) == "fallback_unknown_event":
		_event_id = "fallback_unknown_event"
	print("[Event] load event_id=%s" % _event_id)


func _render_event() -> void:
	_title_label.text = str(_event.get("title", "未知事件"))
	_body_label.text = str(_event.get("body", "霧氣翻湧，你沒有發現任何異常。"))
	_summary_label.text = "節點：%s / HP：%d/%d / 靈石：%d" % [
		RunManager.state.current_node_id,
		RunManager.state.current_hp,
		RunManager.state.max_hp,
		RunManager.state.gold,
	]

	for child in _choice_list.get_children():
		child.queue_free()

	var choices: Array = _event.get("choices", [])
	if choices.is_empty():
		choices = [{"id": "continue", "text": "繼續前進", "result": {"type": "none"}}]

	for choice in choices.slice(0, 3):
		if choice is Dictionary:
			var button := _make_choice_button(str(choice.get("text", "繼續前進")))
			var choice_data: Dictionary = choice.duplicate(true)
			button.pressed.connect(func() -> void:
				_on_choice_pressed(choice_data)
			)
			_choice_list.add_child(button)


func _on_choice_pressed(choice: Dictionary) -> void:
	if _is_resolving:
		return
	_is_resolving = true
	_event_manager.apply_choice(RunManager.state, _event, choice)
	_complete_current_node_and_return()


func _complete_current_node_and_return() -> void:
	var node_id: String = RunManager.state.current_node_id
	if not node_id.is_empty() and not RunManager.state.completed_node_ids.has(node_id):
		RunManager.state.completed_node_ids.append(node_id)
		print("[Event] completed node=%s" % node_id)
	if not node_id.is_empty():
		print("[Chapter01Test] complete node=%s" % node_id)

	var next_id := _chapter_db.get_next_node_id(node_id)
	if next_id.is_empty():
		next_id = _chapter_db.get_first_incomplete_node_id(RunManager.state.completed_node_ids)
	RunManager.state.current_node_id = next_id
	if not next_id.is_empty():
		print("[Chapter01Test] unlock node=%s" % next_id)
	print("[Chapter01Test] return map")
	print("[Event] return to MapScene")
	get_tree().change_scene_to_file(MAP_SCENE_PATH)


func _make_choice_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 104)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 28)
	return button


func _body_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#232635")
	style.border_color = Color("#7f7357")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style
