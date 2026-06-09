class_name EnemyView
extends Button

signal enemy_clicked(enemy_data: EnemyData)
signal card_dropped(card_data: CardData, enemy_data: EnemyData, source_view: Control)

const UI_ENERGY_TEXT := Color("#E3C76A")
const UI_PURPLE_GLOW := Color("#A56DFF")

var enemy_data: EnemyData
var is_drop_target := false

var _target_overlay: Panel
var _sprite_rect: TextureRect


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	flat = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	if custom_minimum_size.x < 340:
		custom_minimum_size = Vector2(410, 560)
	pressed.connect(_on_pressed)
	_build_ui()
	_apply_style()


func setup(p_enemy_data: EnemyData) -> void:
	enemy_data = p_enemy_data
	if not is_node_ready():
		await ready
	refresh()


func refresh() -> void:
	if enemy_data != null:
		print("[EnemyView] enemy=%s transparent_target=true hp=%d intent=%s value=%d" % [
			enemy_data.id,
			enemy_data.hp,
			enemy_data.intent_type,
			enemy_data.intent_value,
		])
		if _sprite_rect != null:
			var path := "res://assets/ui/%s.png" % enemy_data.id
			if ResourceLoader.exists(path) or FileAccess.file_exists(path):
				_sprite_rect.texture = load(path)
			else:
				_sprite_rect.texture = load("res://assets/ui/enemy_placeholder.png")
	_apply_style()


func set_drop_target(value: bool) -> void:
	if is_drop_target == value:
		return
	is_drop_target = value
	_apply_style()


func _on_pressed() -> void:
	if enemy_data != null and enemy_data.hp > 0:
		enemy_clicked.emit(enemy_data)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var can_drop: bool = data is Dictionary and data.get("type", "") == "battle_card" and enemy_data != null and enemy_data.hp > 0
	set_drop_target(can_drop)
	return can_drop


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	set_drop_target(false)
	if data is Dictionary and enemy_data != null:
		card_dropped.emit(data.get("card"), enemy_data, data.get("view"))


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		set_drop_target(false)


func _build_ui() -> void:
	_sprite_rect = TextureRect.new()
	_sprite_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sprite_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sprite_rect)

	_target_overlay = Panel.new()
	_target_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_target_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_target_overlay.visible = false
	add_child(_target_overlay)


func _apply_style() -> void:
	var empty := StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", empty)
	add_theme_stylebox_override("hover", empty)
	add_theme_stylebox_override("pressed", empty)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	if _target_overlay == null:
		return
	_target_overlay.visible = is_drop_target
	if is_drop_target:
		_target_overlay.add_theme_stylebox_override("panel", _drop_target_style())


func _drop_target_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.45, 0.22, 1.0, 0.12)
	style.corner_radius_top_left = 34
	style.corner_radius_top_right = 34
	style.corner_radius_bottom_left = 34
	style.corner_radius_bottom_right = 34
	style.border_width_left = 5
	style.border_width_top = 5
	style.border_width_right = 5
	style.border_width_bottom = 5
	style.border_color = UI_ENERGY_TEXT.lerp(UI_PURPLE_GLOW, 0.45)
	style.shadow_color = Color(0.56, 0.26, 1.0, 0.62)
	style.shadow_size = 18
	return style
