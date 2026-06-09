extends Control

const CardViewScene = preload("res://scenes/battle/CardView.tscn")
const EnemyViewScene = preload("res://scenes/battle/EnemyView.tscn")
const ChapterDatabaseScript = preload("res://scripts/chapter/ChapterDatabase.gd")
const CARD_REWARD_SCENE_PATH := "res://scenes/reward/CardRewardScene.tscn"
const BATTLE_BACKGROUNDS_PATH := "res://data/config/battle_backgrounds_chapter_01.json"
const BATTLE_UI_PLAYER_FULL := "res://assets/ui/battle/player_full.png"
const BATTLE_UI_ENEMY_BOSS_TEMP := "res://assets/ui/battle/enemy_boss_temp.png"
const BATTLE_UI_PANEL_TOP_LOG := "res://assets/ui/battle/panel_top_log.png"
const BATTLE_UI_PANEL_PLAYER_HUD := "res://assets/ui/battle/panel_player_hud.png"
const BATTLE_UI_BUTTON_END_TURN := "res://assets/ui/battle/button_end_turn_frame.png"
const BATTLE_UI_PLAYER_AVATAR := "res://assets/ui/battle/player_avatar.png"
const BATTLE_UI_ROUND_PANEL := "res://assets/ui/battle/round_panel.png"
const BATTLE_UI_PILE_BUTTONS := "res://assets/ui/battle/pile_buttons.png"
const BATTLE_UI_PANEL_ENEMY_INFO := "res://assets/ui/battle/panel_enemy_info.png"
const BATTLE_UI_PANEL_SYSTEM_BUTTONS := "res://assets/ui/battle/panel_system_buttons.png"
const BATTLE_UI_PLAYER_HP_BAR := "res://assets/ui/battle/player_hp_bar.png"
const BATTLE_UI_PLAYER_ENERGY_BAR := "res://assets/ui/battle/player_energy_bar.png"
const BATTLE_UI_ICON_PLAYER_HP := "res://assets/ui/battle/icon_player_hp.png"
const BATTLE_UI_ICON_PLAYER_BLOCK := "res://assets/ui/battle/icon_player_block.png"
const BATTLE_UI_ICON_PLAYER_ENERGY := "res://assets/ui/battle/icon_player_energy.png"
const STATUS_ICON_DIR := "res://assets/ui/status"
const PLAYER_HP_BAR_X_START := 78.0
const PLAYER_HP_BAR_WIDTH := 426.0
const PLAYER_HP_BAR_HEIGHT := 28.0
const PLAYER_ENERGY_BAR_X_START := 55.0
const PLAYER_ENERGY_BAR_WIDTH := 596.0
const PLAYER_ENERGY_BAR_HEIGHT := 28.0

const UI_PRIMARY_TEXT := Color("#F2EBDD")
const UI_SECONDARY_TEXT := Color("#CFC8BD")
const UI_DAMAGE_TEXT := Color("#E06A6A")
const UI_SHIELD_TEXT := Color("#7FB7D8")
const UI_ENERGY_TEXT := Color("#E3C76A")
const UI_DEBUFF_TEXT := Color("#C98BE6")
const UI_INTERACTIVE_HIGHLIGHT := Color("#A8D7D1")
const UI_PANEL_BG := Color(0.063, 0.078, 0.102, 0.58)
const UI_PANEL_BORDER := Color("#7C8D93")
const UI_GOLD := Color("#C3A463")
const UI_DARK_GOLD := Color("#76613A")
const UI_PURPLE_GLOW := Color("#A56DFF")
const UI_AREA_BG := Color(0.063, 0.078, 0.102, 0.28)
const UI_AREA_BORDER := Color(0.486, 0.553, 0.576, 0.24)
const UI_TEXT_SHADOW := Color(0.0, 0.0, 0.0, 0.72)

const TEST_DECK_IDS = [
	"BAS_002", "BAS_002", "BAS_001", "BAS_003",
	"BAS_005", "BAS_007", "BAS_009", "BAS_011",
	"WOD_001", "WOD_004",
	"WAT_001", "WAT_006",
	"FIR_001", "FIR_002", "FIR_003", "FIR_005", "FIR_006",
	"SOU_001",
]

const DEBUG_BATTLE_DECK_ID := "combo_test_deck"
const DEFAULT_TEST_DECK_ID := "default_test_deck"
const COMBO_TEST_DECK_IDS = [
	"WOD_004",
	"FIR_001",
	"ERT_002",
	"GLD_003",
	"WAT_001",
	"BAS_002",
]

const DRAW_PER_TURN := 5
const BASE_ENERGY := 3
const MAX_HAND_SIZE := 10
const BURN_STATUS_ID := "burn"
const POISON_STATUS_ID := "poison"
const FLAME_BODY_STATUS_ID := "flame_body"
const VULNERABLE_STATUS_ID := "vulnerable"
const WEAK_STATUS_ID := "weak"
const ELEMENT_COMBO_NEXT := {
	"wood": "fire",
	"fire": "earth",
	"earth": "metal",
	"metal": "water",
	"water": "wood",
}

var _resolver: BattleEffectResolver
var _deck := DeckManager.new()

var _selected_card: CardData
var _selected_card_view: Control
var _hand_card_views: Array = []
var _enemy_views: Array = []

var _player_hp := 72
var _player_max_hp := 80
var _player_block := 0
var _player_energy := BASE_ENERGY
var _player_max_energy := BASE_ENERGY
var _status_manager: StatusManager

var _turn_number := 0
var _battle_over := false
var _cards_played_this_turn := 0
var _played_elements_this_turn: Dictionary = {}
var _last_played_element := ""
var _expected_next_element := ""
var _current_x_value := 0
var _enemy_turn_animating := false

var _enemy_row: HBoxContainer
var _hand_grid: GridContainer
var _hand_scroll: ScrollContainer
var _hint_label: Label
var _combat_log_label: Label
var _player_name_label: Label
var _player_status_label: Label
var _energy_label: Label
var _round_label: Label
var _left_status_label: Label
var _left_status_icons: HBoxContainer
var _player_status_icons: HBoxContainer
var _enemy_detail_name_label: Label
var _enemy_detail_avatar_rect: TextureRect
var _enemy_detail_hp_label: Label
var _enemy_detail_block_label: Label
var _enemy_detail_status_label: Label
var _enemy_detail_status_icons: HBoxContainer
var _enemy_detail_intent_label: Label
var _draw_button: Button
var _discard_button: Button
var _exhaust_button: Button
var _end_turn_button: Button
var _effects_layer: Control
var _battle_background_rect: TextureRect
var _player_art_rect: TextureRect
var _enemy_art_rect: TextureRect
var _player_avatar_rect: TextureRect
var _pile_buttons_art: TextureRect

var _player_hp_value_label: Label
var _player_block_value_label: Label
var _player_energy_value_label: Label
var _preview_layer: CanvasLayer
var _selection_overlay: PanelContainer
var _large_card_holder: MarginContainer
var _player_hud_anchor: Control
var _player_hud_frame_rect: TextureRect
var _state_buttons_anchor: Control


func _ready() -> void:
	print("[AndroidBattle] BattleScene ready")
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_status_manager = StatusManager.new(self)
	_resolver = BattleEffectResolver.new(self)
	if RunManager.state != null:
		if RunManager.state.player_hp > 0:
			_player_hp = RunManager.state.player_hp
		if RunManager.state.player_max_hp > 0:
			_player_max_hp = RunManager.state.player_max_hp
	_build_ui()
	_setup_battle_background()
	_spawn_enemies(_load_battle_enemies())
	_setup_battle_deck()
	_start_player_turn()


func _build_ui() -> void:
	_battle_background_rect = TextureRect.new()
	_battle_background_rect.name = "BackgroundLayer"
	_battle_background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_battle_background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_battle_background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_battle_background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_battle_background_rect)

	var background := ColorRect.new()
	background.color = Color(0.05, 0.045, 0.065, 0.12)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	background.gui_input.connect(_on_background_gui_input)
	add_child(background)

	_player_art_rect = _build_art_texture(BATTLE_UI_PLAYER_FULL, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_place_control(_player_art_rect, -60, 460, 620, 1360)
	add_child(_player_art_rect)

	_enemy_art_rect = _build_art_texture(BATTLE_UI_ENEMY_BOSS_TEMP, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_place_control(_enemy_art_rect, 440, 255, 980, 955)
	_enemy_art_rect.visible = false
	add_child(_enemy_art_rect)

	var header := _build_battle_header()
	_place_control(header, 28, 20, 1052, 96)
	add_child(header)

	var combat_log := _build_effect_section()
	_place_control(combat_log, 18, 92, 840, 184)
	add_child(combat_log)

	var round_panel := _build_round_status_panel()
	_place_control(round_panel, 22, 214, 112, 540)
	add_child(round_panel)

	var enemy_section := _build_enemy_section()
	_place_control(enemy_section, 455, 330, 880, 900)
	add_child(enemy_section)

	var enemy_detail := _build_enemy_detail_panel()
	_place_control(enemy_detail, 802, 330, 1060, 740)
	add_child(enemy_detail)

	var hand_section := _build_hand_section()
	_place_control(hand_section, 16, 1160, 1064, 1578)
	add_child(hand_section)

	var player_section := _build_player_section()
	_place_control(player_section, 10, 1588, 704, 1902)
	add_child(player_section)

	var state_buttons := _build_state_buttons_anchor()
	_place_control(state_buttons, 688, 1598, 1062, 1888)
	add_child(state_buttons)

	_effects_layer = Control.new()
	_effects_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_effects_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_effects_layer)

	_build_selection_overlay()


func _place_control(control: Control, left: int, top: int, right: int, bottom: int) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = left
	control.offset_top = top
	control.offset_right = right
	control.offset_bottom = bottom


func _build_art_texture(path: String, stretch_mode: TextureRect.StretchMode) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = _load_optional_texture(path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = stretch_mode
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _add_panel_art(parent: Control, path: String, modulate_alpha: float = 1.0) -> TextureRect:
	var rect := _build_art_texture(path, TextureRect.STRETCH_SCALE)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.modulate = Color(1.0, 1.0, 1.0, modulate_alpha)
	parent.add_child(rect)
	return rect


func _load_optional_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var texture := load(path)
		if texture is Texture2D:
			return texture
	push_warning("[BattleUI] missing texture path=%s" % path)
	return null


func _make_battle_info_label(font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	_apply_readable_label(label, color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _build_battle_header() -> Control:
	var panel := PanelContainer.new()
	panel.name = "BattleHeader"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var title := _make_battle_info_label(38, UI_PRIMARY_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	title.text = "覓仙劫"
	title.custom_minimum_size = Vector2(205, 0)
	row.add_child(title)

	var stage := _make_battle_info_label(28, UI_SECONDARY_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	stage.text = "幽冥秘境 · 第 5 層"
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(stage)

	var menu_panel := Control.new()
	menu_panel.custom_minimum_size = Vector2(250, 0)
	menu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(menu_panel)
	var menu_frame := _build_art_texture(BATTLE_UI_PANEL_SYSTEM_BUTTONS, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	menu_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_frame.modulate = Color(1, 1, 1, 0.96)
	menu_panel.add_child(menu_frame)
	return panel


func _build_enemy_section() -> Control:
	var section := PanelContainer.new()
	section.name = "EnemyLayer"
	section.custom_minimum_size = Vector2(0, 0)
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.mouse_filter = Control.MOUSE_FILTER_PASS
	section.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	section.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(root)

	_enemy_row = HBoxContainer.new()
	_enemy_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_enemy_row.add_theme_constant_override("separation", 8)
	_enemy_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_enemy_row.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(_enemy_row)
	return section


func _build_round_status_panel() -> Control:
	var panel := PanelContainer.new()
	panel.name = "RoundStatus"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_add_panel_art(panel, BATTLE_UI_ROUND_PANEL, 0.96)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 26)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 12)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(root)

	_round_label = Label.new()
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_round_label.add_theme_font_size_override("font_size", 46)
	_round_label.custom_minimum_size = Vector2(0, 150)
	_apply_readable_label(_round_label, UI_PRIMARY_TEXT)
	_round_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_round_label)

	_left_status_label = null
	_left_status_icons = null
	return panel


func _build_enemy_detail_panel() -> Control:
	var panel := PanelContainer.new()
	panel.name = "EnemyDetailPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_add_panel_art(panel, BATTLE_UI_PANEL_ENEMY_INFO, 0.98)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 38)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 32)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(root)

	_enemy_detail_name_label = _make_battle_info_label(29, UI_PRIMARY_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_enemy_detail_name_label)

	_enemy_detail_avatar_rect = null

	_enemy_detail_hp_label = _make_battle_info_label(25, UI_DAMAGE_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_enemy_detail_hp_label)
	_enemy_detail_block_label = _make_battle_info_label(24, UI_SHIELD_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_enemy_detail_block_label)
	_enemy_detail_status_label = _make_battle_info_label(23, UI_DEBUFF_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_enemy_detail_status_label)
	_enemy_detail_status_icons = HBoxContainer.new()
	_enemy_detail_status_icons.alignment = BoxContainer.ALIGNMENT_CENTER
	_enemy_detail_status_icons.add_theme_constant_override("separation", 8)
	_enemy_detail_status_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_enemy_detail_status_icons)
	_enemy_detail_intent_label = _make_battle_info_label(25, UI_DAMAGE_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(_enemy_detail_intent_label)
	return panel


func _build_effect_section() -> Control:
	var section := PanelContainer.new()
	section.custom_minimum_size = Vector2(0, 0)
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.mouse_filter = Control.MOUSE_FILTER_PASS
	section.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_add_panel_art(section, BATTLE_UI_PANEL_TOP_LOG, 0.96)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	section.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(root)

	var player_panel := PanelContainer.new()
	player_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	player_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	root.add_child(player_panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 14)
	panel_margin.add_theme_constant_override("margin_top", 6)
	panel_margin.add_theme_constant_override("margin_right", 14)
	panel_margin.add_theme_constant_override("margin_bottom", 6)
	panel_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	player_panel.add_child(panel_margin)

	var panel_root := VBoxContainer.new()
	panel_root.add_theme_constant_override("separation", 4)
	panel_root.mouse_filter = Control.MOUSE_FILTER_PASS
	panel_margin.add_child(panel_root)

	_combat_log_label = Label.new()
	_combat_log_label.text = "戰鬥開始。"
	_combat_log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_combat_log_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_combat_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_combat_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_combat_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_combat_log_label.add_theme_font_size_override("font_size", 24)
	_apply_readable_label(_combat_log_label, UI_PRIMARY_TEXT)
	_combat_log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_root.add_child(_combat_log_label)
	return section


func _build_player_section() -> Control:
	var section := Control.new()
	section.name = "BottomPlayerHUD"
	section.custom_minimum_size = Vector2(0, 0)
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.mouse_filter = Control.MOUSE_FILTER_PASS
	_player_hud_anchor = section

	# Restore character avatar box (Left side)
	var avatar_box := Control.new()
	_place_control(avatar_box, 0, 0, 220, 248)
	avatar_box.clip_contents = true
	avatar_box.z_index = 2
	section.add_child(avatar_box)

	_player_avatar_rect = _build_art_texture(
		BATTLE_UI_PLAYER_AVATAR,
		TextureRect.STRETCH_KEEP_ASPECT_COVERED
	)
	_place_control(_player_avatar_rect, -30, 0, 230, 248)
	_player_avatar_rect.z_index = 2
	avatar_box.add_child(_player_avatar_rect)

	# The main panel background frame (Shifted right by 112, aligned bottom at Y=55)
	_player_hud_frame_rect = _build_art_texture(BATTLE_UI_PANEL_PLAYER_HUD, TextureRect.STRETCH_SCALE)
	_place_control(_player_hud_frame_rect, 112, 55, 692, 248)
	_player_hud_frame_rect.modulate = Color(1, 1, 1, 1)
	_player_hud_frame_rect.z_index = 3
	
	# Load the shader and assign it as material
	var hud_shader := load("res://scenes/battle/player_hud.gdshader")
	if hud_shader:
		var mat := ShaderMaterial.new()
		mat.shader = hud_shader
		_player_hud_frame_rect.material = mat
	section.add_child(_player_hud_frame_rect)

	# Name label is hidden since it's already written beautifully on the texture
	_player_name_label = _make_battle_info_label(34, UI_PRIMARY_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	_player_name_label.text = "楚玄淵"
	_place_control(_player_name_label, 0, 0, 10, 10)
	_player_name_label.z_index = 4
	_player_name_label.visible = false
	_player_hud_frame_rect.add_child(_player_name_label)

	# Realm Label (e.g. "築基後期") inside the top-right purple status frame
	var realm_label := _make_battle_info_label(22, UI_PRIMARY_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	realm_label.text = "築基後期"
	_place_control(realm_label, 197, 10, 398, 49)
	realm_label.z_index = 4
	_player_hud_frame_rect.add_child(realm_label)

	# HP numeric label
	_player_hp_value_label = _make_battle_info_label(22, UI_PRIMARY_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_player_hp_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(_player_hp_value_label, 65, 71, 421, 94)
	_player_hp_value_label.z_index = 5
	_player_hud_frame_rect.add_child(_player_hp_value_label)

	# Block numeric label, overlaying on the right of the shield icon (Shield is at X=438 to 471)
	_player_block_value_label = _make_battle_info_label(24, UI_SHIELD_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	_player_block_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(_player_block_value_label, 476, 63, 536, 100)
	_player_block_value_label.z_index = 5
	_player_hud_frame_rect.add_child(_player_block_value_label)

	# Qi / Energy numeric label
	_player_energy_value_label = _make_battle_info_label(22, UI_PRIMARY_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_player_energy_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(_player_energy_value_label, 46, 114, 544, 136)
	_player_energy_value_label.z_index = 5
	_player_hud_frame_rect.add_child(_player_energy_value_label)

	# Player status label (unused but reference kept)
	_player_status_label = _make_battle_info_label(20, UI_SECONDARY_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	_place_control(_player_status_label, 0, 0, 10, 10)
	_player_status_label.z_index = 4
	_player_status_label.visible = false
	_player_hud_frame_rect.add_child(_player_status_label)

	# Player status icons - placed neatly in the empty area below the Qi bar, shifted right to avoid avatar
	_player_status_icons = HBoxContainer.new()
	_player_status_icons.alignment = BoxContainer.ALIGNMENT_BEGIN
	_player_status_icons.add_theme_constant_override("separation", 18)
	_player_status_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(_player_status_icons, 240, 142, 600, 182)
	_player_status_icons.z_index = 4
	_player_hud_frame_rect.add_child(_player_status_icons)

	# Unused energy label reference
	_energy_label = _make_battle_info_label(20, UI_ENERGY_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	_place_control(_energy_label, 250, 142, 600, 182)
	_energy_label.visible = false
	_player_hud_frame_rect.add_child(_energy_label)

	return section


func _build_state_buttons_anchor() -> Control:
	_state_buttons_anchor = Control.new()
	_state_buttons_anchor.name = "StateButtons"
	_state_buttons_anchor.mouse_filter = Control.MOUSE_FILTER_PASS

	_end_turn_button = _large_button("結束回合", Vector2(356, 96))
	_end_turn_button.add_theme_font_size_override("font_size", 36)
	_apply_framed_end_turn_button(_end_turn_button)
	_end_turn_button.pressed.connect(_on_end_turn_pressed)
	_place_control(_end_turn_button, 9, 10, 365, 106)
	_end_turn_button.z_index = 2
	_state_buttons_anchor.add_child(_end_turn_button)

	_pile_buttons_art = _build_art_texture(BATTLE_UI_PILE_BUTTONS, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_place_control(_pile_buttons_art, 0, 110, 374, 290)
	_pile_buttons_art.modulate = Color(1, 1, 1, 0.88)
	_pile_buttons_art.visible = _pile_buttons_art.texture != null
	_state_buttons_anchor.add_child(_pile_buttons_art)

	var row := _build_action_button_row()
	_place_control(row, 17, 136, 357, 228)
	row.z_index = 2
	_state_buttons_anchor.add_child(row)
	return _state_buttons_anchor





func _build_action_button_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_PASS

	_draw_button = _large_button("", Vector2(104, 92))
	_apply_transparent_pile_button(_draw_button)
	_draw_button.pressed.connect(func():
		_show_pile_dialog("抽牌堆", _deck.draw_pile)
	)
	# Draw pile count label positioned inside the top-right circular bubble frame
	var draw_label := _make_battle_info_label(22, UI_PRIMARY_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	draw_label.name = "CountLabel"
	_place_control(draw_label, 64, 4, 96, 36)
	_draw_button.add_child(draw_label)
	row.add_child(_draw_button)

	_discard_button = _large_button("", Vector2(104, 92))
	_apply_transparent_pile_button(_discard_button)
	_discard_button.pressed.connect(func():
		_show_pile_dialog("棄牌堆", _deck.discard_pile)
	)
	# Discard pile count label positioned inside the top-right circular bubble frame
	var discard_label := _make_battle_info_label(22, UI_PRIMARY_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	discard_label.name = "CountLabel"
	_place_control(discard_label, 56, 0, 88, 32)
	_discard_button.add_child(discard_label)
	row.add_child(_discard_button)

	_exhaust_button = _large_button("", Vector2(104, 92))
	_apply_transparent_pile_button(_exhaust_button)
	_exhaust_button.pressed.connect(func():
		_show_pile_dialog("消耗區", _deck.exhaust_pile)
	)
	# Exhaust pile count label positioned inside the top-right circular bubble frame
	var exhaust_label := _make_battle_info_label(22, UI_PRIMARY_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	exhaust_label.name = "CountLabel"
	_place_control(exhaust_label, 67, 2, 99, 34)
	_exhaust_button.add_child(exhaust_label)
	row.add_child(_exhaust_button)
	return row


func _build_hand_section() -> Control:
	var section := Control.new()
	section.name = "HandArea"
	section.custom_minimum_size = Vector2(0, 0)
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	section.mouse_filter = Control.MOUSE_FILTER_PASS

	var gradient_rect := TextureRect.new()
	gradient_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	gradient_rect.texture = _bottom_gradient_texture()
	gradient_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gradient_rect.stretch_mode = TextureRect.STRETCH_SCALE
	gradient_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	section.add_child(gradient_rect)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_bottom", 2)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	section.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(root)

	_hint_label = _section_title("選擇卡牌，再選擇敵人")
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 18)
	_hint_label.custom_minimum_size = Vector2(0, 24)
	root.add_child(_hint_label)

	var scroll := ScrollContainer.new()
	_hand_scroll = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(scroll)

	_hand_grid = GridContainer.new()
	_hand_grid.columns = 5
	_hand_grid.add_theme_constant_override("h_separation", 8)
	_hand_grid.add_theme_constant_override("v_separation", 10)
	_hand_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hand_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(_hand_grid)
	return section


func _build_selection_overlay() -> void:
	_preview_layer = CanvasLayer.new()
	_preview_layer.layer = 50
	add_child(_preview_layer)

	_selection_overlay = PanelContainer.new()
	_selection_overlay.custom_minimum_size = Vector2(560, 920)
	_selection_overlay.set_anchors_preset(Control.PRESET_CENTER)
	_selection_overlay.offset_left = -280
	_selection_overlay.offset_top = -460
	_selection_overlay.offset_right = 280
	_selection_overlay.offset_bottom = 460
	_selection_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_selection_overlay.z_index = 1000
	_selection_overlay.add_theme_stylebox_override("panel", _panel_style(Color(0.063, 0.078, 0.102, 0.88), UI_ENERGY_TEXT, 28))
	_preview_layer.add_child(_selection_overlay)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 34)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	_selection_overlay.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(root)

	_large_card_holder = MarginContainer.new()
	_large_card_holder.custom_minimum_size = Vector2(510, 760)
	_large_card_holder.mouse_filter = Control.MOUSE_FILTER_PASS
	_large_card_holder.z_index = 1000
	root.add_child(_large_card_holder)

	var prompt := Label.new()
	prompt.text = "拖曳到敵人，或點擊敵人使用卡牌"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 36)
	_apply_readable_label(prompt, UI_PRIMARY_TEXT)
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(prompt)

	var cancel_button := _large_button("取消", Vector2(220, 92))
	cancel_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_button.z_index = 1001
	cancel_button.pressed.connect(_clear_selection)
	root.add_child(cancel_button)
	_selection_overlay.visible = false


func _setup_battle_deck() -> void:
	_deck.max_hand_size = MAX_HAND_SIZE
	if bool(RunManager.state.flags.get("use_debug_deck", false)):
		var debug_deck_id := str(RunManager.state.flags.get("debug_deck_id", DEBUG_BATTLE_DECK_ID))
		match debug_deck_id:
			"combo_test_deck":
				_setup_combo_test_deck()
			_:
				_deck.setup(_card_data_array_from_ids(TEST_DECK_IDS))
				print("[Deck] mode=debug deck_id=%s deck_size=%d" % [debug_deck_id, TEST_DECK_IDS.size()])
		return

	var starting_ids: Array[String] = RunManager.state.deck.duplicate()
	if starting_ids.is_empty():
		RunManager.start_new_run("fire_cultivator")
		starting_ids = RunManager.state.deck.duplicate()
	if starting_ids.is_empty():
		push_warning("[Deck] missing RunState.deck; no starting cards loaded")
	_deck.setup(_card_data_array_from_ids(starting_ids))
	print("[Deck] mode=starting_deck cultivator=%s deck_size=%d" % [
		RunManager.state.selected_cultivator_id,
		starting_ids.size(),
	])


func _setup_test_deck() -> void:
	match DEBUG_BATTLE_DECK_ID:
		"combo_test_deck":
			_setup_combo_test_deck()
		_:
			_deck.setup(_card_data_array_from_ids(TEST_DECK_IDS))


func _setup_combo_test_deck() -> void:
	var starting_cards := _card_data_array_from_ids(COMBO_TEST_DECK_IDS)
	_deck.setup(starting_cards)
	var fixed_draw_pile: Array[CardData] = []
	for index in range(starting_cards.size() - 1, -1, -1):
		fixed_draw_pile.append(starting_cards[index])
	_deck.draw_pile = fixed_draw_pile
	_deck.hand.clear()
	_deck.discard_pile.clear()
	_deck.exhaust_pile.clear()
	print("[ComboHint] using debug deck=combo_test_deck cards=", COMBO_TEST_DECK_IDS)
	print("[Deck] mode=debug deck_id=combo_test_deck deck_size=%d" % COMBO_TEST_DECK_IDS.size())


func _card_data_array_from_ids(card_ids: Array) -> Array[CardData]:
	var cards: Array[CardData] = []
	for card_id in card_ids:
		var record: Dictionary = GameData.get_card_by_id(str(card_id))
		if not record.is_empty():
			cards.append(_card_data_from_record(record))
	return cards


func _start_player_turn() -> void:
	if _battle_over:
		return
	if _end_turn_button != null:
		_end_turn_button.disabled = false
	_turn_number += 1
	_cards_played_this_turn = 0
	_played_elements_this_turn.clear()
	_player_block = 0
	_player_max_energy = BASE_ENERGY
	_player_energy = BASE_ENERGY
	_last_played_element = ""
	_expected_next_element = ""

	var status_lines := _resolve_turn_start_statuses()
	var drawn := _deck.draw_cards(DRAW_PER_TURN)
	_rebuild_hand_views()
	print("[AndroidBattle] hand size=%d" % _deck.hand.size())
	_refresh_combo_hints()
	_refresh_battle_ui()
	_clear_selection()
	_set_hint("第 %d 回合：抽牌，選擇行動。" % _turn_number)
	print("[Draw] turn=%d draw_per_turn=%d hand_size=%d draw_pile=%d discard_pile=%d energy=%d" % [
		_turn_number,
		DRAW_PER_TURN,
		_deck.hand.size(),
		_deck.draw_pile.size(),
		_deck.discard_pile.size(),
		_player_energy,
	])
	var lines := ["Draw %d cards. Energy %d / %d." % [drawn, _player_energy, _player_max_energy]]
	lines.append_array(status_lines)
	_set_combat_log("\n".join(lines))
	_remove_dead_enemies()


func _spawn_enemies(enemies: Array) -> void:
	for child in _enemy_row.get_children():
		child.queue_free()
	_enemy_views.clear()

	if not enemies.is_empty() and _enemy_art_rect != null:
		var first_enemy = enemies[0]
		var path := "res://assets/ui/%s.png" % first_enemy.id
		var tex := _load_optional_texture(path)
		if tex != null:
			_enemy_art_rect.texture = tex

	for enemy in enemies:
		var enemy_view := EnemyViewScene.instantiate()
		enemy_view.custom_minimum_size = _enemy_view_size_for_count(enemies.size())
		enemy_view.setup(enemy)
		enemy_view.modulate = Color(1.0, 1.0, 1.0, 1.0)
		enemy_view.enemy_clicked.connect(_on_enemy_clicked)
		enemy_view.card_dropped.connect(_on_card_dropped_on_enemy)
		_enemy_row.add_child(enemy_view)
		_enemy_views.append(enemy_view)


func _enemy_view_size_for_count(count: int) -> Vector2:
	if count <= 1:
		return Vector2(410, 560)
	if count == 2:
		return Vector2(205, 500)
	return Vector2(136, 460)


func _rebuild_hand_views() -> void:
	for child in _hand_grid.get_children():
		child.queue_free()
	_hand_card_views.clear()

	_apply_hand_layout(_deck.hand.size())
	print("[CardViewSource] actual_source=res://scenes/battle/CardView.tscn script=res://scenes/battle/CardView.gd")
	for card in _deck.hand:
		var card_view := CardViewScene.instantiate()
		card_view.setup(card)
		if card_view.has_method("set_battle_layout_scale"):
			card_view.set_battle_layout_scale(_hand_layout_scale(_deck.hand.size()))
		card_view.card_clicked.connect(_on_card_clicked.bind(card_view))
		card_view.card_touch_drag_started.connect(_on_card_touch_drag_started)
		card_view.card_touch_drag_moved.connect(_on_card_touch_drag_moved)
		card_view.touch_card_dropped.connect(_on_card_touch_dropped)
		_hand_grid.add_child(card_view)
		_hand_card_views.append(card_view)
		print("[HandLayout] using CardView.gd card=%s size=(%d,%d)" % [card.id, int(card_view.custom_minimum_size.x), int(card_view.custom_minimum_size.y)])
	_refresh_combo_hints()


func _apply_hand_layout(count: int) -> void:
	if _hand_grid == null:
		return
	var mode := "single_row"
	var columns: int = max(1, count)
	if count <= 3:
		columns = max(1, count)
	elif count <= 5:
		columns = count
	elif count <= 7:
		mode = "two_rows"
		columns = 4
	else:
		mode = "two_rows"
		columns = 5
	_hand_grid.columns = columns
	_hand_grid.add_theme_constant_override("h_separation", _hand_layout_separation(count))
	_hand_grid.add_theme_constant_override("v_separation", 8 if count > 5 else 10)
	var scale := _hand_layout_scale(count)
	var card_size := Vector2(200, 320) * scale
	print("[HandLayout] count=%d mode=%s card_size=(%d,%d) scale=%.2f" % [count, mode, int(card_size.x), int(card_size.y), scale])


func _hand_layout_scale(count: int) -> float:
	if count <= 3:
		return 1.0
	if count <= 5:
		return 0.95
	if count <= 7:
		return 0.82
	return 0.78


func _hand_layout_separation(count: int) -> int:
	if count <= 3:
		return 16
	if count <= 5:
		return 9
	return 8


func _on_card_clicked(card: CardData, card_view: Control) -> void:
	if _battle_over:
		return
	if _selected_card == card:
		_clear_selection()
		return

	_selected_card = card
	_selected_card_view = card_view
	for view in _hand_card_views:
		view.set_selected(view == card_view)
	_set_hint("已選擇 %s，請選擇敵人目標。" % card.name)
	_show_large_card(card)


func _on_enemy_clicked(enemy: EnemyData) -> void:
	if _battle_over:
		return
	if _selected_card == null:
		_set_hint("請先選擇一張卡牌。")
		return
	_play_card_on_enemy(_selected_card, enemy, _selected_card_view)


func _on_card_dropped_on_enemy(card: CardData, enemy: EnemyData, source_view: Control) -> void:
	if _battle_over:
		return
	_play_card_on_enemy(card, enemy, source_view)


func _on_card_touch_dropped(card: CardData, source_view: Control, drop_position: Vector2) -> void:
	if _battle_over:
		return
	var enemy := _enemy_at_position(drop_position)
	var card_id := card.id if card != null else ""
	var target_id := enemy.id if enemy != null else "none"
	print("[TouchDrag] dropped card=", card_id, " position=", drop_position, " target=", target_id)
	_clear_touch_drop_targets()
	if enemy == null:
		_clear_selection()
		_refresh_combo_hints()
		return
	_play_card_on_enemy(card, enemy, source_view)


func _on_card_touch_drag_started(_card_view: Control) -> void:
	_clear_touch_drop_targets()


func _on_card_touch_drag_moved(_card_view: Control, global_position: Vector2) -> void:
	var hovered_enemy := _enemy_at_position(global_position)
	for enemy_view in _enemy_views:
		var enemy := enemy_view.enemy_data as EnemyData
		enemy_view.set_drop_target(enemy != null and enemy == hovered_enemy)


func _play_card_on_enemy(card: CardData, enemy: EnemyData, source_view: Control) -> void:
	if card == null or enemy == null or _battle_over:
		return
	if enemy.hp <= 0:
		_set_hint("%s 已經倒下。" % enemy.name)
		return

	var cost := _effective_card_cost(card)
	if _player_energy < cost:
		_set_hint("%s 需要 %d 點靈力。" % [card.name, cost])
		if source_view != null:
			_show_floating_text("靈力不足", source_view.global_position + Vector2(70, 20), UI_ENERGY_TEXT)
		return

	_current_x_value = _player_energy if _is_x_cost(card) else 0
	_player_energy -= cost
	if _is_x_cost(card):
		_player_energy = 0

	if source_view != null and source_view.has_method("play_use_effect"):
		source_view.play_use_effect()

	var lines := _resolver.resolve_card(card, enemy)
	_cards_played_this_turn += 1
	var played_element := _card_element(card)
	if not played_element.is_empty():
		_played_elements_this_turn[played_element] = true
	_update_expected_combo_element(played_element)
	_move_played_card(card)
	_clear_selection()
	_remove_dead_enemies()
	_rebuild_hand_views()
	_refresh_combo_hints()
	_refresh_battle_ui()
	_set_hint("使用 %s 攻擊 %s。" % [card.name, enemy.name])
	_set_combat_log("使用 %s\n%s" % [card.name, "\n".join(lines)])
	_current_x_value = 0


func _move_played_card(card: CardData) -> void:
	_deck.move_played_card(card, _card_has_op(card, "exhaust") or card.type == "status")


func _on_end_turn_pressed() -> void:
	if _battle_over or _enemy_turn_animating:
		return
	_enemy_turn_animating = true
	if _end_turn_button != null:
		_end_turn_button.disabled = true
	_last_played_element = ""
	_expected_next_element = ""
	_refresh_combo_hints()
	_clear_selection()
	_discard_remaining_hand()
	_rebuild_hand_views()
	_refresh_combo_hints()
	var lines: Array[String] = await _resolve_enemy_turn()
	lines.append_array(_resolve_turn_end_statuses())
	_remove_dead_enemies()
	if _battle_over:
		_enemy_turn_animating = false
		return
	_advance_enemy_intents()
	_set_combat_log("敵方回合：\n%s" % "\n".join(lines))
	_enemy_turn_animating = false
	_start_player_turn()


func _discard_remaining_hand() -> void:
	_deck.discard_hand()
	_refresh_combo_hints()


func _resolve_enemy_turn() -> Array[String]:
	var lines: Array[String] = []
	for enemy_view in _enemy_views:
		var enemy := enemy_view.enemy_data as EnemyData
		if enemy == null or enemy.hp <= 0:
			continue
		match enemy.intent_type:
			"attack":
				var attack_value := enemy.intent_value
				if enemy_status_amount(enemy, WEAK_STATUS_ID) > 0:
					attack_value = int(floor(float(attack_value) * 0.75))
				var damage := _damage_player(attack_value)
				lines.append("%s 攻擊，造成 %d 傷害。" % [enemy.name, damage])
				_show_floating_text("-%d" % damage, _player_status_label.global_position + Vector2(120, 20), UI_DAMAGE_TEXT)
				await _play_enemy_attack_effect(enemy_view, damage)
			"defend":
				enemy.block += enemy.intent_value
				lines.append("%s 獲得 %d 護盾。" % [enemy.name, enemy.intent_value])
				_show_floating_text("+%d 護盾" % enemy.intent_value, enemy_view.global_position + Vector2(90, 18), UI_SHIELD_TEXT)
			"debuff":
				var burn_amount: int = max(1, enemy.intent_value)
				_status_manager.add_player_status(BURN_STATUS_ID, burn_amount)
				lines.append("%s 施加 %d 層灼燒。" % [enemy.name, burn_amount])
				_show_floating_text("+%d 灼燒" % burn_amount, _player_status_label.global_position + Vector2(120, 20), UI_DEBUFF_TEXT)
			"buff":
				_status_manager.add_enemy_status(enemy, "strength", max(1, enemy.intent_value))
				lines.append("%s 獲得力量。" % enemy.name)
	_refresh_battle_ui()
	return lines


func _advance_enemy_intents() -> void:
	for enemy_view in _enemy_views:
		var enemy := enemy_view.enemy_data as EnemyData
		if enemy != null:
			enemy.advance_intent()


func _resolve_turn_start_statuses() -> Array[String]:
	return _status_manager.resolve_turn_start_statuses()


func _resolve_turn_end_statuses() -> Array[String]:
	return _status_manager.resolve_turn_end_statuses()


func _remove_dead_enemies() -> void:
	for index in range(_enemy_views.size() - 1, -1, -1):
		var enemy_view = _enemy_views[index]
		var enemy := enemy_view.enemy_data as EnemyData
		if enemy != null and enemy.hp <= 0:
			_show_floating_text("倒下", enemy_view.global_position + Vector2(120, 18), UI_ENERGY_TEXT)
			_enemy_views.remove_at(index)
			enemy_view.queue_free()
	if _enemy_views.is_empty():
		_win_battle()


func _win_battle() -> void:
	_battle_over = true
	_clear_selection()
	_set_hint("戰鬥勝利")
	_set_combat_log("戰鬥勝利，準備獎勵。")
	if _end_turn_button != null:
		_end_turn_button.disabled = true
	if RunManager.state != null:
		RunManager.state.player_hp = _player_hp
	_prepare_card_reward()
	call_deferred("_go_to_card_reward_scene")


func simulate_combat_victory() -> void:
	_win_battle()


func simulate_chapter_01_clear() -> void:
	RunManager.state.current_chapter_id = "chapter_01"
	RunManager.state.current_node_id = "boss_001"
	RunManager.state.flags["pending_reward_type"] = "boss_combat"
	get_tree().change_scene_to_file("res://scenes/ending/ChapterEndingScene.tscn")


func _prepare_card_reward() -> void:
	var node := RunManager.get_current_node()
	var reward_type := str(node.get("reward_type", ""))
	if reward_type.is_empty():
		match str(node.get("type", "")):
			"elite_choice", "elite_combat", "story_elite", "story_elite_combat":
				reward_type = "elite_combat"
			"boss", "boss_combat":
				reward_type = "boss_combat"
			_:
				reward_type = "normal_combat"
	RunManager.state.flags["pending_reward_type"] = reward_type
	RunManager.state.pending_card_reward.clear()
	print("[Reward] battle victory node=%s reward_type=%s" % [RunManager.state.current_node_id, reward_type])


func _go_to_card_reward_scene() -> void:
	get_tree().change_scene_to_file(CARD_REWARD_SCENE_PATH)


func draw_cards(amount: int) -> void:
	_deck.draw_cards(amount)
	_rebuild_hand_views()
	_refresh_combo_hints()
	_refresh_battle_ui()


func add_player_block(amount: int) -> void:
	_player_block += max(0, amount)
	_refresh_battle_ui()
	_show_floating_text("+%d 護盾" % amount, _player_status_label.global_position + Vector2(120, 20), UI_SHIELD_TEXT)


func add_player_energy(amount: int) -> void:
	_player_energy += max(0, amount)
	_refresh_battle_ui()
	_show_floating_text("+%d 靈力" % amount, _energy_label.global_position + Vector2(45, 10), UI_ENERGY_TEXT)


func lose_player_hp(amount: int) -> int:
	var damage: int = min(_player_hp, max(0, amount))
	_player_hp = max(0, _player_hp - damage)
	if RunManager.state != null:
		RunManager.state.player_hp = _player_hp
	_refresh_battle_ui()
	if _player_hp <= 0:
		_lose_battle()
	return damage


func heal_player(amount: int) -> int:
	var before := _player_hp
	_player_hp = min(_player_max_hp, _player_hp + max(0, amount))
	if RunManager.state != null:
		RunManager.state.player_hp = _player_hp
	_refresh_battle_ui()
	return _player_hp - before


func damage_enemy(enemy: EnemyData, amount: int, true_damage: bool) -> int:
	var damage := _damage_enemy(enemy, amount, true_damage)
	if damage > 0:
		_show_floating_text("-%d" % damage, _enemy_float_position(enemy), UI_DAMAGE_TEXT)
	return damage


func add_player_status(status_id: String, amount: int) -> void:
	_status_manager.add_player_status(status_id, amount)
	_show_floating_text("+%d %s" % [amount, status_name(status_id)], _player_status_label.global_position + Vector2(120, 20), UI_DEBUFF_TEXT)


func add_enemy_status(enemy: EnemyData, status_id: String, amount: int) -> void:
	if enemy == null:
		return
	_status_manager.add_enemy_status(enemy, status_id, amount)
	_show_floating_text("+%d %s" % [amount, status_name(status_id)], _enemy_float_position(enemy), UI_DEBUFF_TEXT)


func remove_player_status(status_id: String) -> int:
	return _status_manager.remove_player_status(status_id)


func remove_enemy_status(enemy: EnemyData, status_id: String) -> int:
	if enemy == null:
		return 0
	return _status_manager.remove_enemy_status(enemy, status_id)


func player_status_amount(status_id: String) -> int:
	return _status_manager.player_status_amount(status_id)


func enemy_status_amount(enemy: EnemyData, status_id: String) -> int:
	if enemy == null:
		return 0
	return _status_manager.enemy_status_amount(enemy, status_id)


func status_name(status_id: String) -> String:
	return _status_manager.status_name(status_id)


func get_living_enemies() -> Array[EnemyData]:
	var enemies: Array[EnemyData] = []
	for enemy_view in _enemy_views:
		var enemy := enemy_view.enemy_data as EnemyData
		if enemy != null and enemy.hp > 0:
			enemies.append(enemy)
	return enemies


func hand_has_type(card_type: String) -> bool:
	return _deck.hand_has_type(card_type)


func cards_played_this_turn() -> int:
	return _cards_played_this_turn


func played_element_this_turn(element: String) -> bool:
	return _played_elements_this_turn.has(element)


func current_x_value() -> int:
	return _current_x_value


func discard_cards_from_hand(amount: int, except_card: CardData = null) -> int:
	var discarded := _deck.discard_from_hand(amount, except_card)
	_refresh_combo_hints()
	return discarded


func trigger_burn_all(lose_hp_per_triggered_enemy: int) -> int:
	var triggered_count := 0
	for enemy in get_living_enemies():
		var burn_amount: int = enemy_status_amount(enemy, BURN_STATUS_ID)
		if burn_amount <= 0:
			continue
		var damage := _damage_enemy(enemy, burn_amount, true)
		var _removed: int = remove_enemy_status(enemy, BURN_STATUS_ID)
		triggered_count += 1
		_show_floating_text("灼燒 -%d" % damage, _enemy_float_position(enemy), UI_DEBUFF_TEXT)
	if triggered_count > 0 and lose_hp_per_triggered_enemy > 0:
		var self_damage := triggered_count * lose_hp_per_triggered_enemy
		lose_player_hp(self_damage)
		_show_floating_text("反噬 -%d" % self_damage, _player_status_label.global_position + Vector2(120, 20), UI_DAMAGE_TEXT)
	return triggered_count


func _damage_enemy(enemy: EnemyData, amount: int, true_damage: bool) -> int:
	if enemy == null or amount <= 0:
		return 0
	var remaining := amount
	if enemy_status_amount(enemy, VULNERABLE_STATUS_ID) > 0 and not true_damage:
		remaining = int(ceil(float(remaining) * 1.5))
	if not true_damage and enemy.block > 0:
		var blocked: int = min(enemy.block, remaining)
		enemy.block -= blocked
		remaining -= blocked
	if remaining > 0:
		var hp_damage: int = min(enemy.hp, remaining)
		enemy.hp = max(0, enemy.hp - remaining)
		return hp_damage
	return 0


func _damage_player(amount: int) -> int:
	var remaining: int = max(0, amount)
	if _status_manager.player_status_amount(VULNERABLE_STATUS_ID) > 0:
		remaining = int(ceil(float(remaining) * 1.5))
	if _player_block > 0:
		var blocked: int = min(_player_block, remaining)
		_player_block -= blocked
		remaining -= blocked
	if remaining > 0:
		var hp_damage := lose_player_hp(remaining)
		return hp_damage
	return 0


# (Internal status helpers _add_status, _remove_status, _tick_status, _status_amount removed and encapsulated in StatusManager)


func _card_has_op(card: CardData, op_name: String) -> bool:
	for effect in card.effects:
		if str(effect.get("op", "")) == op_name:
			return true
	return false


func _effective_card_cost(card: CardData) -> int:
	if _is_x_cost(card):
		return _player_energy
	return int(card.cost)


func _is_x_cost(card: CardData) -> bool:
	return card.cost is String and str(card.cost).to_upper() == "X"


func _lose_battle() -> void:
	if _battle_over:
		return
	_battle_over = true
	_clear_selection()
	_set_hint("戰鬥失敗")
	_set_combat_log("戰鬥失敗。")
	if _end_turn_button != null:
		_end_turn_button.disabled = true


func _refresh_battle_ui() -> void:
	for enemy_view in _enemy_views:
		enemy_view.refresh()
	_refresh_enemy_detail_panel()
	if _player_name_label != null:
		_player_name_label.text = "楚玄淵"
		_apply_readable_label(_player_name_label, UI_PRIMARY_TEXT)
	if _round_label != null:
		_round_label.text = str(max(1, _turn_number))
		_apply_readable_label(_round_label, UI_PRIMARY_TEXT)
	if _left_status_label != null:
		_left_status_label.text = _statuses_text(_status_manager.player_statuses, 4)
		_apply_readable_label(_left_status_label, UI_DEBUFF_TEXT if not _status_manager.player_statuses.is_empty() else UI_SECONDARY_TEXT)
	_refresh_status_icons(_left_status_icons, _status_manager.player_statuses, 4)
	if _player_status_label != null:
		_player_status_label.text = "狀態"
		_apply_readable_label(_player_status_label, UI_SECONDARY_TEXT)
	if _player_hp_value_label != null:
		_player_hp_value_label.text = "%d / %d" % [_player_hp, _player_max_hp]
		_apply_readable_label(_player_hp_value_label, UI_PRIMARY_TEXT)
	if _player_block_value_label != null:
		_player_block_value_label.text = str(_player_block)
		_apply_readable_label(_player_block_value_label, UI_SHIELD_TEXT)
	if _player_energy_value_label != null:
		_player_energy_value_label.text = "%d / %d" % [_player_energy, _player_max_energy]
		_apply_readable_label(_player_energy_value_label, UI_PRIMARY_TEXT)
	if _player_hud_frame_rect != null and _player_hud_frame_rect.material is ShaderMaterial:
		var mat := _player_hud_frame_rect.material as ShaderMaterial
		mat.set_shader_parameter("hp_ratio", float(_player_hp) / maxf(1.0, float(_player_max_hp)))
		mat.set_shader_parameter("qi_ratio", float(_player_energy) / maxf(1.0, float(_player_max_energy)))
	_refresh_status_icons(_player_status_icons, _status_manager.player_statuses, 3)
	if _energy_label != null:
		_energy_label.text = ""
	if _draw_button != null:
		_draw_button.text = ""
		var count_lbl = _draw_button.get_node_or_null("CountLabel")
		if count_lbl != null:
			count_lbl.text = str(_deck.draw_pile.size())
	if _discard_button != null:
		_discard_button.text = ""
		var count_lbl = _discard_button.get_node_or_null("CountLabel")
		if count_lbl != null:
			count_lbl.text = str(_deck.discard_pile.size())
	if _exhaust_button != null:
		_exhaust_button.text = ""
		var count_lbl = _exhaust_button.get_node_or_null("CountLabel")
		if count_lbl != null:
			count_lbl.text = str(_deck.exhaust_pile.size())


func _refresh_enemy_detail_panel() -> void:
	var enemy := _enemy_for_detail_panel()
	if enemy == null:
		if _enemy_detail_name_label != null:
			_enemy_detail_name_label.text = "敵人"
		if _enemy_detail_avatar_rect != null:
			_enemy_detail_avatar_rect.texture = null
		if _enemy_detail_hp_label != null:
			_enemy_detail_hp_label.text = "HP - / -"
		if _enemy_detail_block_label != null:
			_enemy_detail_block_label.text = "護甲 0"
		if _enemy_detail_status_label != null:
			_enemy_detail_status_label.text = "狀態 無"
		_refresh_status_icons(_enemy_detail_status_icons, [], 4)
		if _enemy_detail_intent_label != null:
			_enemy_detail_intent_label.text = "敵意行動 -"
		return
	if _enemy_detail_name_label != null:
		_enemy_detail_name_label.text = enemy.name
		_apply_readable_label(_enemy_detail_name_label, UI_PRIMARY_TEXT)
	if _enemy_detail_avatar_rect != null:
		var path := "res://assets/ui/%s.png" % enemy.id
		_enemy_detail_avatar_rect.texture = _load_optional_texture(path)
	if _enemy_detail_hp_label != null:
		_enemy_detail_hp_label.text = "HP %d / %d" % [enemy.hp, enemy.max_hp]
		_apply_readable_label(_enemy_detail_hp_label, UI_DAMAGE_TEXT)
	if _enemy_detail_block_label != null:
		_enemy_detail_block_label.text = "護甲 %d" % enemy.block
		_apply_readable_label(_enemy_detail_block_label, UI_SHIELD_TEXT)
	if _enemy_detail_status_label != null:
		_enemy_detail_status_label.text = "狀態"
		_apply_readable_label(_enemy_detail_status_label, UI_DEBUFF_TEXT if not enemy.statuses.is_empty() else UI_SECONDARY_TEXT)
	_refresh_status_icons(_enemy_detail_status_icons, enemy.statuses, 4)
	if _enemy_detail_intent_label != null:
		_enemy_detail_intent_label.text = "敵意行動\n%s" % _enemy_detail_intent_text(enemy.intent_type, enemy.intent_value)
		_apply_readable_label(_enemy_detail_intent_label, UI_DAMAGE_TEXT)


func _enemy_for_detail_panel() -> EnemyData:
	for enemy_view in _enemy_views:
		var enemy := enemy_view.enemy_data as EnemyData
		if enemy != null and enemy.hp > 0:
			return enemy
	return null


func _enemy_detail_intent_text(intent_type: String, value: int) -> String:
	match intent_type:
		"attack":
			return "強力攻擊 x %d" % value
		"defend":
			return "防禦 x %d" % value
		"debuff":
			return "施加灼燒 x %d" % value
		"buff":
			return "強化 x %d" % value
		_:
			return "觀望"


func _refresh_status_icons(container: HBoxContainer, statuses: Array, max_count: int = 0) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()
	if statuses.is_empty():
		if container != _player_status_icons:
			var empty_label := _make_status_amount_label("無")
			container.add_child(empty_label)
		return
	var count := 0
	for status in statuses:
		if max_count > 0 and count >= max_count:
			break
		var status_id := str(status.get("id", status.get("name", ""))).to_lower()
		var amount := int(status.get("amount", 0))
		container.add_child(_make_status_icon(status_id, amount))
		count += 1
	if max_count > 0 and statuses.size() > max_count:
		container.add_child(_make_status_amount_label("+%d" % (statuses.size() - max_count)))


func _make_status_icon(status_id: String, amount: int) -> Control:
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 2)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.gui_input.connect(_on_status_icon_gui_input.bind(status_id))
	var texture := _load_status_icon(status_id)
	if texture != null:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(38, 38)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = texture
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(icon)
	else:
		var fallback := _make_status_amount_label(status_name(status_id))
		root.add_child(fallback)
	var amount_label := _make_status_amount_label(str(amount))
	root.add_child(amount_label)
	return root


func _on_status_icon_gui_input(event: InputEvent, status_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_status_dialog(status_id)
	elif event is InputEventScreenTouch and event.pressed:
		_show_status_dialog(status_id)


func _show_status_dialog(status_id: String) -> void:
	var status_record := GameData.get_status(status_id)
	var s_name := str(status_record.get("name", status_id))
	var s_desc := str(status_record.get("description", "無詳細說明。"))
	
	var dialog := AcceptDialog.new()
	dialog.title = s_name
	dialog.dialog_text = s_desc
	add_child(dialog)
	dialog.popup_centered(Vector2i(450, 220))
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)


func _make_status_amount_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	_apply_readable_label(label, UI_PRIMARY_TEXT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _load_status_icon(status_id: String) -> Texture2D:
	var path := "%s/%s.png" % [STATUS_ICON_DIR, status_id]
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		var texture := load(path)
		if texture is Texture2D:
			return texture
	return null


func _statuses_text(statuses: Array, max_count: int = 0) -> String:
	if statuses.is_empty():
		return "無"
	var parts: Array[String] = []
	var count := 0
	for status in statuses:
		if max_count > 0 and count >= max_count:
			break
		var status_id := str(status.get("id", status.get("name", "")))
		parts.append("%s %s" % [status_name(status_id), str(status.get("amount", 0))])
		count += 1
	if max_count > 0 and statuses.size() > max_count:
		parts.append("+%d" % (statuses.size() - max_count))
	return "  ".join(parts)


func _enemy_float_position(enemy: EnemyData) -> Vector2:
	for enemy_view in _enemy_views:
		if enemy_view.enemy_data == enemy:
			return enemy_view.global_position + Vector2(120, 18)
	return Vector2(520, 320)


func _play_enemy_attack_effect(enemy_view: Control, _damage: int) -> void:
	if enemy_view == null or _effects_layer == null:
		return
	var original_position := enemy_view.position
	var enemy_center := enemy_view.global_position + enemy_view.size * 0.5
	var target_position := _enemy_attack_target_position()
	var direction := target_position - enemy_center
	if direction.length() <= 0.1:
		direction = Vector2.DOWN
	var dash_offset := direction.normalized() * 28.0
	var original_hud_position := Vector2.ZERO
	var has_hud := _player_hud_anchor != null
	if has_hud:
		original_hud_position = _player_hud_anchor.position

	_show_slash_effect(enemy_center, target_position)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(enemy_view, "position", original_position + dash_offset, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if has_hud:
		tween.tween_property(_player_hud_anchor, "modulate", Color(1.0, 0.42, 0.38, 1.0), 0.08)
		tween.tween_property(_player_hud_anchor, "position", original_hud_position + Vector2(8, 0), 0.06)
	await tween.finished

	var return_tween := create_tween()
	return_tween.set_parallel(true)
	return_tween.tween_property(enemy_view, "position", original_position, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if has_hud:
		return_tween.tween_property(_player_hud_anchor, "modulate", Color.WHITE, 0.16)
		return_tween.tween_property(_player_hud_anchor, "position", original_hud_position - Vector2(8, 0), 0.06)
		return_tween.tween_property(_player_hud_anchor, "position", original_hud_position, 0.08).set_delay(0.06)
	await return_tween.finished
	enemy_view.position = original_position
	if has_hud:
		_player_hud_anchor.position = original_hud_position
		_player_hud_anchor.modulate = Color.WHITE


func _enemy_attack_target_position() -> Vector2:
	if _player_status_label != null:
		return _player_status_label.global_position + _player_status_label.size * 0.5
	if _player_hud_anchor != null:
		return _player_hud_anchor.global_position + _player_hud_anchor.size * Vector2(0.5, 0.35)
	return get_viewport_rect().size * Vector2(0.5, 0.88)


func _show_slash_effect(from: Vector2, to: Vector2) -> void:
	if _effects_layer == null:
		return
	var delta := to - from
	var length: float = max(48.0, delta.length())
	var slash := ColorRect.new()
	slash.color = Color(1.0, 0.32, 0.08, 0.62)
	slash.size = Vector2(length, 10)
	slash.pivot_offset = slash.size * 0.5
	slash.rotation = delta.angle()
	slash.global_position = from.lerp(to, 0.5) - slash.pivot_offset
	slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_effects_layer.add_child(slash)

	var core := ColorRect.new()
	core.color = Color(1.0, 0.88, 0.52, 0.72)
	core.size = Vector2(length * 0.72, 3)
	core.position = Vector2(length * 0.14, 3.5)
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slash.add_child(core)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(slash, "modulate:a", 0.0, 0.22)
	tween.tween_property(slash, "scale", Vector2(1.08, 1.75), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(slash.queue_free)


func _show_floating_text(text: String, position: Vector2, color: Color) -> void:
	if _effects_layer == null:
		return
	var label := Label.new()
	label.text = text
	label.global_position = position
	label.add_theme_font_size_override("font_size", 38)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_effects_layer.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", position + Vector2(0, -72), 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.75).set_delay(0.12)
	tween.finished.connect(label.queue_free)


func _show_pile_dialog(title: String, pile: Array[CardData]) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "%s (%d)" % [title, pile.size()]
	dialog.dialog_text = _pile_text(pile)
	add_child(dialog)
	dialog.popup_centered(Vector2i(560, 720))
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)


func _pile_text(pile: Array[CardData]) -> String:
	if pile.is_empty():
		return "空"
	var lines: Array[String] = []
	var index := 1
	for card in pile:
		lines.append("%02d. [%s] %s / %s" % [index, str(card.cost), card.name, card.type])
		index += 1
	return "\n".join(lines)


func _set_hint(text: String) -> void:
	if _hint_label != null:
		_hint_label.text = text
		_hint_label.visible = false
	if _combat_log_label != null:
		_combat_log_label.text = text


func _set_combat_log(text: String) -> void:
	if _combat_log_label != null:
		var lines := text.split("\n", false)
		if lines.size() > 1:
			_combat_log_label.text = str(lines[lines.size() - 1])
		else:
			_combat_log_label.text = text


func _on_background_gui_input(event: InputEvent) -> void:
	if _selected_card == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_clear_selection()
	elif event is InputEventScreenTouch and event.pressed:
		_clear_selection()


func _show_large_card(card: CardData) -> void:
	for child in _large_card_holder.get_children():
		child.queue_free()
	var large_card := CardViewScene.instantiate()
	large_card.setup(card, true)
	large_card.z_index = 1000
	_large_card_holder.add_child(large_card)
	_selection_overlay.visible = true


func _clear_selection() -> void:
	_selected_card = null
	_selected_card_view = null
	for view in _hand_card_views:
		view.set_selected(false)
	if _hint_label != null and _battle_over:
		_hint_label.text = "戰鬥已結束。"
	elif _hint_label != null and _deck.is_hand_empty():
		_hint_label.text = "手牌已空，請結束回合。"
	elif _hint_label != null:
		_hint_label.text = "選擇卡牌，再選擇敵人。"
	if _selection_overlay != null:
		_selection_overlay.visible = false
	if _large_card_holder != null:
		for child in _large_card_holder.get_children():
			child.queue_free()
	_refresh_combo_hints()


func _update_expected_combo_element(played_element: String) -> void:
	if ELEMENT_COMBO_NEXT.has(played_element):
		_last_played_element = played_element
		_expected_next_element = str(ELEMENT_COMBO_NEXT[played_element])
	else:
		_last_played_element = played_element
		_expected_next_element = ""
	print("[ComboHint] last=", _last_played_element, " next=", _expected_next_element)


func _refresh_combo_hints() -> void:
	print("[ComboHint] last=", _last_played_element, " next=", _expected_next_element)
	for view in _hand_card_views:
		if view != null and view.has_method("set_combo_hint"):
			var card := view.card_data as CardData
			var element := _card_element(card)
			var should_highlight := not _expected_next_element.is_empty() and card != null and element == _expected_next_element
			var card_id := card.id if card != null else ""
			print("[ComboHint] hand card=", card_id, " element=", element, " highlight=", should_highlight)
			view.set_combo_hint(should_highlight)


func _enemy_at_position(global_point: Vector2) -> EnemyData:
	for enemy_view in _enemy_views:
		var enemy := enemy_view.enemy_data as EnemyData
		if enemy != null and enemy.hp > 0 and enemy_view.get_global_rect().has_point(global_point):
			return enemy
	return null


func _clear_touch_drop_targets() -> void:
	for enemy_view in _enemy_views:
		enemy_view.set_drop_target(false)


func _card_element(card: CardData) -> String:
	if card == null:
		return ""
	var element := str(card.element).to_lower()
	if element.is_empty():
		var main_element = card.get("main_element")
		if main_element != null:
			element = str(main_element).to_lower()
	if element.is_empty() and not card.id.is_empty():
		var record := GameData.get_card_by_id(card.id)
		element = str(record.get("main_element", record.get("element", ""))).to_lower()
	return element


func _card_data_from_record(card_record: Dictionary) -> CardData:
	return CardData.new(
		str(card_record.get("id", "")),
		str(card_record.get("name", "")),
		str(card_record.get("element", "")),
		str(card_record.get("type", "")),
		card_record.get("cost", 0),
		str(card_record.get("description", "")),
		str(card_record.get("rarity", "N")),
		card_record.get("effects", []),
		str(card_record.get("target_type", "enemy"))
	)


func _load_battle_enemies() -> Array:
	var enemies: Array = []
	var enemy_ids := _select_encounter_enemy_ids()
	print("[Encounter] selected enemies=%s" % JSON.stringify(enemy_ids))
	print("[AndroidBattle] selected enemies=%s" % JSON.stringify(enemy_ids))
	for enemy_id in enemy_ids:
		var enemy_record := GameData.get_enemy_by_id(enemy_id)
		if enemy_record.is_empty():
			push_warning("[Encounter] enemy not found id=%s" % enemy_id)
			continue
		print("[Encounter] spawn enemy=%s" % enemy_id)
		enemies.append(_enemy_data_from_record(enemy_record))
	return enemies


func _setup_battle_background() -> void:
	if _battle_background_rect == null:
		return
	var config := _as_dictionary(_load_json(BATTLE_BACKGROUNDS_PATH))
	var fallback_id := str(config.get("fallback_background", "chapter01_bg_outer_trial"))
	var node_id := str(RunManager.state.current_node_id)
	var node_backgrounds := _as_dictionary(config.get("node_backgrounds", {}))
	var bg_id := str(node_backgrounds.get(node_id, fallback_id))
	var backgrounds := _as_dictionary(config.get("backgrounds", {}))
	var bg_record := _as_dictionary(backgrounds.get(bg_id, backgrounds.get(fallback_id, {})))
	var path := str(bg_record.get("path", ""))
	var exists := _texture_resource_exists(path)
	if path.is_empty() or not exists:
		push_warning("[AndroidBattle] missing background path=%s" % path)
		push_warning("[BattleBackground] missing path=%s fallback=%s" % [path, fallback_id])
		bg_id = fallback_id
		bg_record = _as_dictionary(backgrounds.get(fallback_id, {}))
		path = str(bg_record.get("path", ""))
		exists = _texture_resource_exists(path)

	print("[AndroidBattle] background path=%s exists=%s" % [path, str(exists).to_lower()])
	print("[BattleBackground] node=%s bg=%s path=%s" % [node_id, bg_id, path])
	var texture := _load_texture_from_path(path)
	if texture != null:
		_battle_background_rect.texture = texture
		print("[BattleBackground] loaded OK")
	else:
		_battle_background_rect.texture = _solid_color_texture(Color(0.035, 0.042, 0.058, 1.0))
		push_warning("[AndroidBattle] using fallback battle background")


func _load_texture_from_path(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var texture := load(path)
		if texture is Texture2D:
			return texture
	if FileAccess.file_exists(path):
		var image := Image.new()
		var error := image.load(ProjectSettings.globalize_path(path))
		if error == OK:
			return ImageTexture.create_from_image(image)
	return null


func _texture_resource_exists(path: String) -> bool:
	if path.is_empty() or not path.begins_with("res://"):
		return false
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)


func _solid_color_texture(color: Color) -> Texture2D:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func _select_encounter_enemy_ids() -> Array[String]:
	var chapter_db = ChapterDatabaseScript.new()
	chapter_db.load_from_file()

	var current_node_id := str(RunManager.state.current_node_id)
	if current_node_id.is_empty() or chapter_db.get_node(current_node_id).is_empty():
		push_warning("[Encounter] missing current_node_id, fallback node_001")
		current_node_id = "node_001"
		RunManager.state.current_node_id = current_node_id

	var node := chapter_db.get_node(current_node_id)
	var node_type := str(node.get("type", ""))
	print("[Encounter] current_node_id=%s" % current_node_id)
	print("[AndroidBattle] current_node_id=%s" % current_node_id)
	print("[Encounter] node type=%s" % node_type)

	var explicit_enemies := _to_string_array(node.get("enemies", []))
	if not explicit_enemies.is_empty():
		return explicit_enemies

	var fixed_enemy := str(node.get("fixed_enemy", node.get("enemy_id", "")))
	if fixed_enemy.is_empty():
		fixed_enemy = str(node.get("node.enemy_id", ""))
	if not fixed_enemy.is_empty():
		return [fixed_enemy]

	var enemy_pool := _to_string_array(node.get("enemy_pool", node.get("node.enemy_pool", [])))
	if not enemy_pool.is_empty():
		var enemy_count: int = max(1, int(node.get("enemy_count", 1)))
		return enemy_pool.slice(0, min(enemy_count, enemy_pool.size()))

	if chapter_db.is_combat_type(node_type):
		push_warning("[Encounter] combat node has no enemies, fallback node_001")
		return ["wooden_training_dummy"]
	return []


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("[AndroidBattle] failed to open json path=%s" % path)
		push_error("[Battle] file not found: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[AndroidBattle] failed to open json path=%s" % path)
		push_error("[Battle] could not open file: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("[Battle] could not parse file: %s" % path)
		return {}
	return parsed


func _as_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


func _enemy_data_from_record(enemy_record: Dictionary) -> EnemyData:
	var intent_sequence: Array = enemy_record.get("intent_sequence", []).duplicate(true)
	var first_intent: Dictionary = intent_sequence[0] if not intent_sequence.is_empty() else {}
	return EnemyData.new(
		str(enemy_record.get("id", "")),
		str(enemy_record.get("name", "")),
		int(enemy_record.get("hp", enemy_record.get("max_hp", 1))),
		int(enemy_record.get("max_hp", enemy_record.get("hp", 1))),
		int(enemy_record.get("block", 0)),
		str(first_intent.get("type", enemy_record.get("intent_type", "unknown"))),
		int(first_intent.get("value", enemy_record.get("intent_value", 0))),
		enemy_record.get("statuses", []).duplicate(true),
		intent_sequence
	)


func _to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result


func _section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 34)
	_apply_readable_label(label, UI_PRIMARY_TEXT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _info_panel(text: String, font_size: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _ornate_panel_style(Color(0.02, 0.022, 0.030, 0.52), Color(0.486, 0.553, 0.576, 0.30), 14, 1))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	_apply_readable_label(label, UI_PRIMARY_TEXT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	return panel


func _large_button(text: String, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 32)
	button.add_theme_color_override("font_color", UI_PRIMARY_TEXT)
	button.add_theme_color_override("font_hover_color", UI_INTERACTIVE_HIGHLIGHT)
	button.add_theme_color_override("font_pressed_color", UI_ENERGY_TEXT)
	button.add_theme_color_override("font_shadow_color", UI_TEXT_SHADOW)
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)
	button.add_theme_stylebox_override("normal", _button_style(UI_PANEL_BG))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.080, 0.105, 0.122, 0.68)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.050, 0.063, 0.082, 0.76)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _apply_framed_end_turn_button(button: Button) -> void:
	var frame := _build_art_texture(BATTLE_UI_BUTTON_END_TURN, TextureRect.STRETCH_SCALE)
	frame.name = "EndTurnFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.show_behind_parent = true
	button.add_child(frame)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", UI_PRIMARY_TEXT)
	button.add_theme_color_override("font_hover_color", UI_ENERGY_TEXT)
	button.add_theme_color_override("font_pressed_color", UI_INTERACTIVE_HIGHLIGHT)


func _apply_transparent_pile_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	button.add_theme_color_override("font_hover_color", Color(0, 0, 0, 0))
	button.add_theme_color_override("font_pressed_color", Color(0, 0, 0, 0))


func _apply_readable_label(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", UI_TEXT_SHADOW)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)


func _bottom_gradient_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.063, 0.078, 0.102, 0.0),
		Color(0.063, 0.078, 0.102, 0.24),
		Color(0.063, 0.078, 0.102, 0.50),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	return texture


func _panel_style(bg_color: Color, border_color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	return style


func _ornate_panel_style(bg_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := _panel_style(bg_color, border_color, radius)
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 8
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style


func _button_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = UI_GOLD
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.58)
	style.shadow_size = 10
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style
