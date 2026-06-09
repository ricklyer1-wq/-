class_name MapNodeView
extends PanelContainer

signal node_pressed(node_id: String)

var node_id := ""
var is_available := false
var is_completed := false

var _button: Button
var _title_label: Label
var _type_label: Label
var _state_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(0, 132)
	_build_ui()


func setup(node: Dictionary, display_type: String, available: bool, completed: bool) -> void:
	node_id = str(node.get("id", ""))
	is_available = available
	is_completed = completed
	if not is_node_ready():
		await ready

	var index_text := str(node.get("index", ""))
	var display_name := str(node.get("display_name", node_id))
	_title_label.text = "%s. %s" % [index_text, display_name]
	_type_label.text = "%s / %s" % [display_type, node_id]

	if is_completed:
		_state_label.text = "已完成"
	elif is_available:
		_state_label.text = "可進入"
	else:
		_state_label.text = "未解鎖"

	_button.disabled = not is_available
	_apply_style(str(node.get("type", "")))


func _build_ui() -> void:
	_button = Button.new()
	_button.focus_mode = Control.FOCUS_NONE
	_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_button.pressed.connect(func() -> void:
		if is_available:
			node_pressed.emit(node_id)
	)
	add_child(_button)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 8)
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_box)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 30)
	_title_label.add_theme_color_override("font_color", Color("#fff9e8"))
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(_title_label)

	_type_label = Label.new()
	_type_label.add_theme_font_size_override("font_size", 22)
	_type_label.add_theme_color_override("font_color", Color("#d6cab2"))
	_type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(_type_label)

	_state_label = Label.new()
	_state_label.custom_minimum_size = Vector2(150, 0)
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_state_label.add_theme_font_size_override("font_size", 26)
	_state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_state_label)


func _apply_style(node_type: String) -> void:
	var bg_color := Color("#26242b")
	var border_color := Color("#5c5365")
	var state_color := Color("#a8a0aa")

	if is_completed:
		bg_color = Color("#303133")
		border_color = Color("#74777a")
		state_color = Color("#bfc5c2")
	elif is_available:
		bg_color = Color("#273629")
		border_color = Color("#f2cf66")
		state_color = Color("#ffe38a")
	elif node_type in ["boss", "boss_combat"]:
		bg_color = Color("#2d2024")
		border_color = Color("#8b3f52")

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 5 if is_available else 2
	style.border_width_top = 5 if is_available else 2
	style.border_width_right = 5 if is_available else 2
	style.border_width_bottom = 5 if is_available else 2
	style.border_color = border_color

	_button.add_theme_stylebox_override("normal", style)
	_button.add_theme_stylebox_override("hover", style)
	_button.add_theme_stylebox_override("pressed", style)
	_button.add_theme_stylebox_override("disabled", style)
	_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_state_label.add_theme_color_override("font_color", state_color)
