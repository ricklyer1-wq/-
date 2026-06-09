class_name CardView
extends Button

signal card_clicked(card_data: CardData)
signal card_touch_drag_started(card_view: Control)
signal card_touch_drag_moved(card_view: Control, global_position: Vector2)
signal card_touch_drag_ended(card_view: Control, global_position: Vector2)
signal touch_card_dropped(card_data: CardData, source_view: Control, drop_position: Vector2)

const CARD_IMAGE_TEMPLATE = "res://assets/cards/%s.png"
const PLACEHOLDER_CARD_IMAGE = "res://assets/cards/_placeholder.png"
const CARD_FRAME_NORMAL = "res://assets/ui/battle/card_frame_normal.png"
const CARD_FRAME_SELECTED = "res://assets/ui/battle/card_frame_selected.png"

const ELEMENT_COLORS = {
	"fire": Color("#d95532"),
	"wood": Color("#2f9b72"),
	"water": Color("#2f7fbd"),
	"metal": Color("#d6bd68"),
	"earth": Color("#a98244"),
	"soul": Color("#7b5bbd"),
	"neutral": Color("#dfd6c3"),
}

const ELEMENT_LABELS = {
	"fire": "火",
	"wood": "木",
	"water": "水",
	"metal": "金",
	"earth": "土",
	"soul": "神魂",
	"neutral": "通用",
}

const TYPE_LABELS = {
	"attack": "攻擊",
	"skill": "技能",
	"power": "能力",
	"status": "狀態",
}

const RARITY_COLORS = {
	"BASIC": Color("#c8cdd4"),
	"N": Color("#e2e2da"),
	"R": Color("#71b0ec"),
	"SR": Color("#be80e7"),
	"SSR": Color("#f6c353"),
	"TOKEN": Color("#8bdcac"),
	"STATUS": Color("#d96060"),
}

const UI_PRIMARY_TEXT := Color("#F2EBDD")
const UI_SECONDARY_TEXT := Color("#CFC8BD")
const UI_MUTED_TEXT := Color("#AFA79B")
const UI_ENERGY_TEXT := Color("#E3C76A")
const UI_CARD_BG := Color("#141414")
const UI_CARD_INNER_BG := Color(0.035, 0.036, 0.042, 0.88)
const UI_CARD_GOLD := Color("#BDA56A")
const UI_CARD_DARK_GOLD := Color("#6E5A36")
const UI_CARD_PURPLE := Color("#A56DFF")
const UI_PANEL_BG := Color(0.063, 0.078, 0.102, 0.58)
const UI_PANEL_BORDER := Color("#7C8D93")
const UI_TEXT_SHADOW := Color(0.0, 0.0, 0.0, 0.78)
const UI_TITLE_TEXT := Color(0.95, 0.90, 0.78, 1.0)
const UI_DESC_TEXT := Color(0.92, 0.88, 0.78, 1.0)
const UI_COST_TEXT := Color(1.0, 0.9, 0.45, 1.0)
const UI_TEXT_OUTLINE := Color(0.0, 0.0, 0.0, 0.9)
const UI_COST_OUTLINE := Color(0.0, 0.0, 0.0, 1.0)

var card_data: CardData
var is_large_view := false
var display_mode := "battle_hand"
var battle_layout_scale := 1.0
var is_selected := false
var is_combo_hint_enabled := false

var _cost_label: Label
var _element_label: Label
var _name_label: Label
var _type_label: Label
var _description_label: Label
var _image_panel: Control
var _image_rect: TextureRect
var _frame_rect: TextureRect
var _highlight_overlay: Panel
var _active_touch_index := -1
var _is_touch_dragging := false
var _touch_start_position := Vector2.ZERO
var _touch_drag_grab_offset := Vector2.ZERO
var _original_position := Vector2.ZERO
var _original_z_index := 0
var _was_combo_hint_enabled_before_drag := false
var _last_logged_layout_size := Vector2.ZERO


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	flat = true
	pressed.connect(_on_pressed)
	_build_ui()
	_apply_style()


func setup(p_card_data: CardData, p_is_large: bool = false, p_display_mode: String = "") -> void:
	card_data = p_card_data
	is_large_view = p_is_large
	display_mode = p_display_mode if not p_display_mode.is_empty() else ("large_preview" if is_large_view else "battle_hand")
	match display_mode:
		"reward_display":
			custom_minimum_size = Vector2(640, 780)
		"large_preview":
			custom_minimum_size = Vector2(500, 760)
		_:
			custom_minimum_size = Vector2(200, 320)
	size = custom_minimum_size
	if not is_node_ready():
		await ready
	print("[CardViewLayout] setup card_id=%s name=%s" % [card_data.id, card_data.name])
	_refresh()


func set_selected(value: bool) -> void:
	is_selected = value
	_apply_style()


func set_combo_hint_enabled(enabled: bool) -> void:
	set_combo_hint(enabled)


func set_combo_hint(enabled: bool) -> void:
	var card_id := card_data.id if card_data != null else ""
	print("[ComboHint] set_combo_hint ", card_id, " enabled=", enabled)
	if is_combo_hint_enabled == enabled:
		return
	is_combo_hint_enabled = enabled
	_apply_style()


func set_battle_layout_scale(value: float) -> void:
	if display_mode != "battle_hand":
		return
	battle_layout_scale = clampf(value, 0.78, 1.0)
	custom_minimum_size = Vector2(200, 320) * battle_layout_scale
	size = custom_minimum_size
	_apply_battle_scaled_metrics()
	_layout_battle_card()


func play_use_effect() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.14)
	tween.tween_property(self, "modulate:a", 0.25, 0.14)


func _on_pressed() -> void:
	if card_data != null:
		card_clicked.emit(card_data)


func _gui_input(event: InputEvent) -> void:
	if card_data == null or is_large_view:
		return
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _active_touch_index != -1:
			return
		var touch_global_position := event.position
		_active_touch_index = event.index
		_is_touch_dragging = false
		_touch_start_position = touch_global_position
		_touch_drag_grab_offset = touch_global_position - global_position
		_original_position = position
		_original_z_index = z_index
		_was_combo_hint_enabled_before_drag = is_combo_hint_enabled
		print("[TouchDrag] touch start card=", card_data.id, " position=", touch_global_position)
		accept_event()
	else:
		if event.index != _active_touch_index:
			return
		var touch_global_position := event.position
		if _is_touch_dragging:
			print("[TouchDrag] touch end card=", card_data.id, " position=", touch_global_position)
			card_touch_drag_ended.emit(self, touch_global_position)
			touch_card_dropped.emit(card_data, self, touch_global_position)
			_reset_touch_drag()
			accept_event()
		_active_touch_index = -1
		_is_touch_dragging = false
		accept_event()


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index != _active_touch_index:
		return
	var drag_global_position := event.position
	var drag_offset := drag_global_position - _touch_start_position
	if not _is_touch_dragging:
		if drag_offset.length() < 12.0:
			return
		_is_touch_dragging = true
		z_index = 100
		modulate = Color(1, 1, 1, 0.72)
		card_touch_drag_started.emit(self)
		print("[TouchDrag] drag started card=", card_data.id)
	global_position = drag_global_position - _touch_drag_grab_offset
	card_touch_drag_moved.emit(self, drag_global_position)
	accept_event()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if card_data == null or is_large_view:
		return null
	var preview := _make_drag_preview()
	set_drag_preview(preview)
	modulate = Color(1, 1, 1, 0.55)
	return {
		"type": "battle_card",
		"card": card_data,
		"view": self,
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate = Color.WHITE
	elif what == NOTIFICATION_PREDELETE:
		_active_touch_index = -1
		_is_touch_dragging = false
	elif what == NOTIFICATION_RESIZED:
		_layout_battle_card()


func _reset_touch_drag() -> void:
	position = _original_position
	z_index = _original_z_index
	modulate = Color.WHITE
	is_combo_hint_enabled = _was_combo_hint_enabled_before_drag
	_apply_style()


func _make_drag_preview() -> Control:
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(120, 160)
	preview.texture = _load_card_texture(card_data.id)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.modulate = Color(1, 1, 1, 0.88)
	return preview


func _build_ui() -> void:
	_cost_label = Label.new()
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_card_text_label(_cost_label, UI_COST_TEXT, UI_COST_OUTLINE)
	_cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cost_label.z_index = 30
	add_child(_cost_label)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name_label.clip_text = true
	_apply_card_text_label(_name_label, UI_TITLE_TEXT, UI_TEXT_OUTLINE)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.z_index = 30
	add_child(_name_label)

	_element_label = Label.new()
	_element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_element_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_readable_label(_element_label, UI_SECONDARY_TEXT)
	_element_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_element_label.visible = false
	add_child(_element_label)

	_type_label = Label.new()
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_readable_label(_type_label, UI_SECONDARY_TEXT)
	_type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_type_label.visible = false
	_type_label.z_index = 40
	add_child(_type_label)

	_image_panel = Control.new()
	_image_panel.name = "ArtClip"
	_image_panel.clip_contents = true
	_image_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image_panel.z_index = 10
	add_child(_image_panel)

	_image_rect = TextureRect.new()
	_image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_image_panel.add_child(_image_rect)

	_description_label = Label.new()
	_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.clip_text = true
	_apply_card_text_label(_description_label, UI_DESC_TEXT, UI_TEXT_OUTLINE)
	_description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_description_label.z_index = 30
	add_child(_description_label)

	_highlight_overlay = Panel.new()
	_highlight_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_highlight_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_highlight_overlay.visible = false
	_highlight_overlay.z_index = 40
	add_child(_highlight_overlay)

	_frame_rect = TextureRect.new()
	_frame_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_frame_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_rect.z_index = 20
	add_child(_frame_rect)
	_layout_battle_card()


func _refresh() -> void:
	if card_data == null:
		return

	var element_label: String = str(ELEMENT_LABELS.get(card_data.element, card_data.element))

	_cost_label.text = _format_cost(card_data.cost)
	_element_label.text = element_label
	_name_label.text = card_data.name
	_type_label.text = ""
	_description_label.text = card_data.description
	_image_rect.texture = _load_card_texture(card_data.id)

	_cost_label.add_theme_font_size_override("font_size", _cost_font_size_for_mode())
	_element_label.add_theme_font_size_override("font_size", _element_font_size_for_mode())
	_name_label.add_theme_font_size_override("font_size", _name_font_size_for_mode())
	_type_label.add_theme_font_size_override("font_size", _type_font_size_for_mode())
	_description_label.add_theme_font_size_override("font_size", _description_font_size_for_mode())
	_description_label.max_lines_visible = 8 if display_mode == "reward_display" else (7 if is_large_view else 2)
	_apply_battle_scaled_metrics()
	_layout_battle_card()
	_apply_style()
	_apply_battle_text_visibility()
	_log_card_text_state()


func _card_image_path(card_id: String) -> String:
	var image_path := CARD_IMAGE_TEMPLATE % card_id
	if ResourceLoader.exists(image_path) or FileAccess.file_exists(image_path):
		return image_path
	push_warning("[AndroidBattle] missing card image id=%s path=%s" % [card_id, image_path])
	return PLACEHOLDER_CARD_IMAGE


func _load_card_texture(card_id: String) -> Texture2D:
	var image_path := _card_image_path(card_id)
	if ResourceLoader.exists(image_path):
		var texture := load(image_path)
		if texture is Texture2D:
			return texture
	if image_path != PLACEHOLDER_CARD_IMAGE:
		push_warning("[AndroidBattle] card image load failed id=%s path=%s" % [card_id, image_path])
	if ResourceLoader.exists(PLACEHOLDER_CARD_IMAGE):
		var placeholder := load(PLACEHOLDER_CARD_IMAGE)
		if placeholder is Texture2D:
			return placeholder
	return _solid_card_texture()


func _solid_card_texture() -> Texture2D:
	var image := Image.create(32, 48, false, Image.FORMAT_RGBA8)
	image.fill(Color("#3B4650"))
	return ImageTexture.create_from_image(image)


func _apply_style() -> void:
	var base_color := Color("#dfd6c3")
	if card_data != null:
		base_color = ELEMENT_COLORS.get(card_data.element, base_color)

	var bg := StyleBoxFlat.new()
	var tint := base_color.darkened(0.35)
	bg.bg_color = tint.lerp(UI_CARD_BG, 0.78)
	bg.corner_radius_top_left = 16
	bg.corner_radius_top_right = 16
	bg.corner_radius_bottom_left = 22
	bg.corner_radius_bottom_right = 22
	bg.border_width_left = 4
	bg.border_width_top = 4
	bg.border_width_right = 4
	bg.border_width_bottom = 4
	var rarity_color := _rarity_color()
	if is_combo_hint_enabled:
		bg.border_color = UI_CARD_PURPLE
		bg.shadow_color = Color(0.55, 0.24, 1.0, 0.80)
		bg.shadow_size = 22
	else:
		bg.border_color = UI_CARD_GOLD.lerp(rarity_color, 0.28)
		bg.shadow_color = Color(0.0, 0.0, 0.0, 0.72)
		bg.shadow_size = 10
	bg.content_margin_left = 10
	bg.content_margin_top = 10
	bg.content_margin_right = 10
	bg.content_margin_bottom = 12
	add_theme_stylebox_override("normal", bg)
	add_theme_stylebox_override("hover", bg)
	add_theme_stylebox_override("pressed", bg)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	scale = Vector2.ONE
	if _highlight_overlay != null:
		_highlight_overlay.visible = is_combo_hint_enabled
		_highlight_overlay.add_theme_stylebox_override("panel", _combo_highlight_style())
		_highlight_overlay.z_index = 40
	if _frame_rect != null:
		_frame_rect.texture = _load_frame_texture(CARD_FRAME_SELECTED if is_combo_hint_enabled else CARD_FRAME_NORMAL)
		_frame_rect.visible = display_mode == "battle_hand"
		_frame_rect.z_index = 20

	if _element_label != null:
		_cost_label.add_theme_stylebox_override("normal", _cost_badge_style(is_combo_hint_enabled))
		_apply_readable_label(_element_label, UI_ENERGY_TEXT if is_combo_hint_enabled else UI_SECONDARY_TEXT)
		_apply_card_text_label(_name_label, UI_TITLE_TEXT, UI_TEXT_OUTLINE)
		_apply_readable_label(_type_label, UI_SECONDARY_TEXT)
		_apply_card_text_label(_description_label, UI_DESC_TEXT, UI_TEXT_OUTLINE)
		_apply_card_text_label(_cost_label, UI_COST_TEXT, UI_COST_OUTLINE)
		_apply_battle_text_visibility()


func _load_frame_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var texture := load(path)
		if texture is Texture2D:
			return texture
	return null


func _layout_battle_card() -> void:
	if _cost_label == null:
		return
	var card_size := size
	if card_size.x < 1.0 or card_size.y < 1.0:
		card_size = custom_minimum_size
	var card_w := card_size.x
	var card_h := card_size.y

	_set_rect(_cost_label, Vector2(card_w * 0.022, card_h * 0.012), Vector2(card_w * 0.17, card_h * 0.106))
	_set_rect(_name_label, Vector2(card_w * 0.19, card_h * 0.046), Vector2(card_w * 0.68, card_h * 0.078))
	_set_rect(_type_label, Vector2.ZERO, Vector2.ZERO)
	_set_rect(_image_panel, Vector2(card_w * 0.086, card_h * 0.126), Vector2(card_w * 0.828, card_h * 0.562))
	_set_rect(_description_label, Vector2(card_w * 0.075, card_h * 0.715), Vector2(card_w * 0.85, card_h * 0.214))
	_apply_battle_text_visibility()
	if _frame_rect != null:
		_set_rect(_frame_rect, Vector2.ZERO, card_size)
	if _highlight_overlay != null:
		_set_rect(_highlight_overlay, Vector2.ZERO, card_size)
	if _image_rect != null:
		_set_rect(_image_rect, Vector2.ZERO, _image_panel.size)

	var card_id := card_data.id if card_data != null else "none"
	if card_size != _last_logged_layout_size:
		_last_logged_layout_size = card_size
		print("[CardViewLayout] card_id=%s size=(%d,%d) art_rect=(%d,%d,%d,%d)" % [card_id, int(card_w), int(card_h), int(_image_panel.position.x), int(_image_panel.position.y), int(_image_panel.size.x), int(_image_panel.size.y)])
		print("[CardViewLayout] title_rect=(%d,%d,%d,%d)" % [int(_name_label.position.x), int(_name_label.position.y), int(_name_label.size.x), int(_name_label.size.y)])
		print("[CardViewLayout] desc_rect=(%d,%d,%d,%d)" % [int(_description_label.position.x), int(_description_label.position.y), int(_description_label.size.x), int(_description_label.size.y)])
		print("[CardViewLayout] card=%s art_height=%d desc_height=%d" % [card_id, int(_image_panel.size.y), int(_description_label.size.y)])


func _set_rect(control: Control, position_value: Vector2, size_value: Vector2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = position_value
	control.size = size_value
	control.custom_minimum_size = size_value


func _inner_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.18)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	return style


func _cost_badge_style(is_lit: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.047, 0.055, 0.94)
	style.corner_radius_top_left = 34
	style.corner_radius_top_right = 34
	style.corner_radius_bottom_left = 34
	style.corner_radius_bottom_right = 34
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = UI_CARD_PURPLE if is_lit else UI_CARD_GOLD
	style.shadow_color = Color(0.55, 0.24, 1.0, 0.55) if is_lit else Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 12 if is_lit else 6
	return style


func _apply_readable_label(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", UI_TEXT_SHADOW)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)


func _apply_card_text_label(label: Label, color: Color, outline_color: Color) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", outline_color)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_shadow_color", UI_TEXT_SHADOW)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.visible = true
	label.modulate = Color.WHITE
	label.self_modulate = Color.WHITE


func _apply_battle_text_visibility() -> void:
	if _cost_label == null:
		return
	_cost_label.visible = true
	_cost_label.modulate = Color.WHITE
	_cost_label.self_modulate = Color.WHITE
	_cost_label.z_index = 30
	_name_label.visible = true
	_name_label.modulate = Color.WHITE
	_name_label.self_modulate = Color.WHITE
	_name_label.z_index = 30
	_description_label.visible = true
	_description_label.modulate = Color.WHITE
	_description_label.self_modulate = Color.WHITE
	_description_label.z_index = 30
	if _element_label != null:
		_element_label.visible = false
		_element_label.text = ""
	if _type_label != null:
		_type_label.visible = false
		_type_label.text = ""
	if _frame_rect != null:
		_frame_rect.z_index = 20
	if _highlight_overlay != null:
		_highlight_overlay.z_index = 40


func _log_card_text_state() -> void:
	if card_data == null or _cost_label == null:
		return
	print("[CardText] name=%s title_visible=%s title_text=%s title_rect=(%d,%d,%d,%d)" % [card_data.name, str(_name_label.visible), _name_label.text, int(_name_label.position.x), int(_name_label.position.y), int(_name_label.size.x), int(_name_label.size.y)])
	print("[CardText] desc_visible=%s desc_text=%s desc_rect=(%d,%d,%d,%d)" % [str(_description_label.visible), _description_label.text, int(_description_label.position.x), int(_description_label.position.y), int(_description_label.size.x), int(_description_label.size.y)])
	print("[CardText] cost_visible=%s cost_text=%s cost_rect=(%d,%d,%d,%d)" % [str(_cost_label.visible), _cost_label.text, int(_cost_label.position.x), int(_cost_label.position.y), int(_cost_label.size.x), int(_cost_label.size.y)])
	print("[CardText] frame_z=%d title_z=%d desc_z=%d cost_z=%d" % [int(_frame_rect.z_index if _frame_rect != null else -1), int(_name_label.z_index), int(_description_label.z_index), int(_cost_label.z_index)])


func _image_height_for_mode() -> int:
	match display_mode:
		"reward_display":
			return 330
		"large_preview":
			return 360
		_:
			return _scaled_battle_int(300, 180, 300)


func _cost_font_size_for_mode() -> int:
	match display_mode:
		"reward_display":
			return 56
		"large_preview":
			return 44
		_:
			return _scaled_battle_int(22, 16, 22)


func _element_font_size_for_mode() -> int:
	match display_mode:
		"reward_display":
			return 38
		"large_preview":
			return 32
		_:
			return _scaled_battle_int(22, 14, 22)


func _name_font_size_for_mode() -> int:
	match display_mode:
		"reward_display":
			return 48
		"large_preview":
			return 42
		_:
			return _scaled_battle_int(19, 15, 19)


func _type_font_size_for_mode() -> int:
	match display_mode:
		"reward_display":
			return 34
		"large_preview":
			return 30
		_:
			return _scaled_battle_int(10, 9, 11)


func _description_font_size_for_mode() -> int:
	match display_mode:
		"reward_display":
			return 32
		"large_preview":
			return 29
		_:
			return _scaled_battle_int(14, 11, 14)


func _apply_battle_scaled_metrics() -> void:
	if display_mode != "battle_hand" or _cost_label == null:
		return
	_cost_label.add_theme_font_size_override("font_size", _cost_font_size_for_mode())
	_name_label.add_theme_font_size_override("font_size", _name_font_size_for_mode())
	_description_label.add_theme_font_size_override("font_size", _description_font_size_for_mode())
	_cost_label.custom_minimum_size = Vector2(42, 42) * battle_layout_scale


func _format_cost(value: Variant) -> String:
	var number := float(value)
	if is_equal_approx(number, roundf(number)):
		return str(int(roundf(number)))
	return str(number)


func _scaled_battle_int(base: int, minimum: int, maximum: int) -> int:
	if display_mode != "battle_hand":
		return base
	return clampi(int(round(float(base) * battle_layout_scale)), minimum, maximum)


func _combo_highlight_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.42, 0.18, 1.0, 0.16)
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24
	style.border_width_left = 7
	style.border_width_top = 7
	style.border_width_right = 7
	style.border_width_bottom = 7
	style.border_color = UI_CARD_PURPLE
	style.shadow_color = Color(0.55, 0.24, 1.0, 0.72)
	style.shadow_size = 20
	return style


func _rarity_color() -> Color:
	if card_data == null:
		return Color("#22252b")
	var card_record := GameData.get_card_by_id(card_data.id)
	var rarity := str(card_record.get("rarity", "N"))
	return RARITY_COLORS.get(rarity, Color("#22252b"))


func _is_light_color(color: Color) -> bool:
	return color.get_luminance() > 0.58
