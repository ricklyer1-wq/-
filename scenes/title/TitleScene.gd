extends Control

const MAP_SCENE_PATH := "res://scenes/map/MapScene.tscn"
const TITLE_BACKGROUND_PATH := "res://assets/ui/title_login_bg.png"

var _is_transitioning := false


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var background := TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture = _load_texture(TITLE_BACKGROUND_PATH)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var start_button := Button.new()
	start_button.text = "開始遊戲"
	start_button.anchor_left = 0.32
	start_button.anchor_top = 0.86
	start_button.anchor_right = 0.68
	start_button.anchor_bottom = 0.86
	start_button.offset_top = -48
	start_button.offset_bottom = 48
	start_button.focus_mode = Control.FOCUS_NONE
	start_button.add_theme_font_size_override("font_size", 34)
	start_button.add_theme_color_override("font_color", Color("#f2ebdd"))
	start_button.add_theme_color_override("font_hover_color", Color("#e3c76a"))
	start_button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.78))
	start_button.add_theme_constant_override("shadow_offset_x", 2)
	start_button.add_theme_constant_override("shadow_offset_y", 2)
	start_button.add_theme_stylebox_override("normal", _button_style(Color(0.063, 0.078, 0.102, 0.42)))
	start_button.add_theme_stylebox_override("hover", _button_style(Color(0.080, 0.105, 0.122, 0.58)))
	start_button.add_theme_stylebox_override("pressed", _button_style(Color(0.050, 0.063, 0.082, 0.68)))
	start_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	start_button.pressed.connect(_enter_game)
	add_child(start_button)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_enter_game()
	elif event is InputEventScreenTouch and event.pressed:
		_enter_game()


func _enter_game() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if RunManager.state.selected_cultivator_id.is_empty():
		RunManager.start_new_run("fire_cultivator")
	get_tree().change_scene_to_file(MAP_SCENE_PATH)


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


func _button_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.486, 0.553, 0.576, 0.38)
	return style
