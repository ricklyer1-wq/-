extends Control

const ChapterEndingManagerScript = preload("res://scripts/ending/ChapterEndingManager.gd")
const MAP_SCENE_PATH := "res://scenes/map/MapScene.tscn"

var _ending_manager = ChapterEndingManagerScript.new()
var _choices_container: VBoxContainer
var _status_label: Label
var _is_resolving := false


func _ready() -> void:
	_build_ui()
	_ensure_run_state()
	print("[Ending] enter chapter=chapter_01")
	_ending_manager.load_from_file()
	_render_choices()


func simulate_chapter_01_clear() -> void:
	get_tree().change_scene_to_file("res://scenes/ending/ChapterEndingScene.tscn")


func _ensure_run_state() -> void:
	if RunManager.state.selected_cultivator_id.is_empty():
		RunManager.start_new_run("fire_cultivator")
	RunManager.state.current_chapter_id = "chapter_01"


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#13151d")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var safe := MarginContainer.new()
	safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe.add_theme_constant_override("margin_left", 32)
	safe.add_theme_constant_override("margin_top", 42)
	safe.add_theme_constant_override("margin_right", 32)
	safe.add_theme_constant_override("margin_bottom", 34)
	add_child(safe)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	safe.add_child(root)

	var title := Label.new()
	title.text = "第一章通關"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color("#fff0ba"))
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "靈霧染血"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 34)
	subtitle.add_theme_color_override("font_color", Color("#d8e7c5"))
	root.add_child(subtitle)

	var body_panel := PanelContainer.new()
	body_panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(body_panel)

	var body_margin := MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 22)
	body_margin.add_theme_constant_override("margin_top", 20)
	body_margin.add_theme_constant_override("margin_right", 22)
	body_margin.add_theme_constant_override("margin_bottom", 20)
	body_panel.add_child(body_margin)

	var body := Label.new()
	body.text = "五大宗門長老打破結界趕來，向你拋出橄欖枝。你也可以選擇成為散修，守住祖傳玉簡的秘密。"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 28)
	body.add_theme_color_override("font_color", Color("#eadfcb"))
	body_margin.add_child(body)

	_status_label = Label.new()
	_status_label.custom_minimum_size = Vector2(0, 52)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 22)
	_status_label.add_theme_color_override("font_color", Color("#ffd98a"))
	root.add_child(_status_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 760)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.visible = true
	root.add_child(scroll)

	_choices_container = VBoxContainer.new()
	_choices_container.name = "ChoicesContainer"
	_choices_container.visible = true
	_choices_container.custom_minimum_size = Vector2(980, 0)
	_choices_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_choices_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_choices_container.add_theme_constant_override("separation", 14)
	scroll.add_child(_choices_container)


func _render_choices() -> void:
	if _choices_container == null:
		push_error("[Ending] choices_container missing")
		return
	_choices_container.visible = true
	for child in _choices_container.get_children():
		child.queue_free()
	_status_label.text = "選擇你的歸處。"

	for choice_index in range(_ending_manager.choices.size()):
		var choice: Dictionary = _ending_manager.choices[choice_index]
		var label := _choice_label(choice)
		var choice_id := str(choice.get("id", ""))
		var text := "%s\n%s\n%s" % [
			label,
			str(choice.get("description", "")),
			_ending_manager.unlock_summary(choice),
		]
		var button := _make_choice_button(text)
		var idx: int = choice_index
		print("[Ending] build choice id=%s label=%s" % [choice_id, label])
		button.pressed.connect(func() -> void:
			_on_choice_pressed(idx)
		)
		_choices_container.add_child(button)


func _on_choice_pressed(choice_index: int) -> void:
	if _is_resolving or choice_index < 0 or choice_index >= _ending_manager.choices.size():
		return
	_is_resolving = true
	var choice: Dictionary = _ending_manager.choices[choice_index]
	_ending_manager.apply_choice(RunManager.state, DebugProfile, choice)
	_status_label.text = "已記錄選擇：%s" % str(choice.get("name", ""))
	print("[Ending] return to main/debug")
	get_tree().change_scene_to_file(MAP_SCENE_PATH)


func _make_choice_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 150)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 23)
	return button


func _choice_label(choice: Dictionary) -> String:
	for key in ["name", "title", "text", "id"]:
		var value := str(choice.get(key, ""))
		if not value.is_empty():
			return value
	return "未命名選項"


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
