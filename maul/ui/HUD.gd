class_name HUD
extends Node

# ============================================================
# Signals
# ============================================================

signal tower_selected(idx: int)
signal start_wave_pressed()
signal difficulty_set(idx: int)
signal map_selected(idx: int)
signal clear_all_pressed()
signal sell_tower_pressed()
signal drag_side_changed(right: bool)

# ============================================================
# Node references
# ============================================================

var _tower_btns:     Array[Button] = []
var _tower_grid:     GridContainer
var _map_btns:       Array[Button] = []
var _selected_map:   int    = 0
var _send_early_btn: Button
var _send_btn_wrap:  Control
var _countdown_lbl:  Label
var _status_lbl:     Label
var _escaped_lbl:    Label
var _gold_lbl:       Label
var _wave_lbl:       Label
var _info_lbl:       Label
var _start_screen:   Control
var _tower_drawer:   Control
var _tower_toggle:   Button
var _ic_backdrop:        ColorRect
var _draft_overlay: Control
var _draft_cards:   Array[Button] = []
var _relic_draft_overlay: Control
var _relic_draft_cards: Array[Button] = []
var _relic_strip_hbox: HBoxContainer
var _toast_lbl: Label
var _synergy_strip_lbl: Label
var _wave_preview_lbl: Label
var _info_card:          Control
var _ic_name_lbl:        Label
var _ic_stats_lbl:       Label
var _ic_lore_lbl:        Label
var _ic_sell_price_lbl:  Label
var _ic_sell_btn:        Button
var _ic_anim_tween:      Tween
var _drag_side_btn:   Button
var _drag_right:      bool = false
var _gear_btn:        Button
var _speed_btn:       Button
var _mute_btn:        Button
var _health_bar:      ProgressBar
var _settings_panel:  Control
var _diff_btns:          Array[Button] = []
var _pending_difficulty: int = 1
var _summary_overlay: Control
var _summary_wave_lbl:    Label
var _summary_towers_lbl:  Label
var _summary_syn_lbl:     Label
var _summary_relic_lbl:   Label
var _summary_best_lbl:    Label
var _sc_best_lbl: Label

# ============================================================
# Lifecycle
# ============================================================

func _ready() -> void:
	_build_ui()
	_connect_signals()


func _connect_signals() -> void:
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.escaped_changed.connect(_on_escaped_changed)
	GameState.wave_started.connect(_on_wave_started)
	GameState.wave_completed.connect(_on_wave_completed)
	GameState.game_over_triggered.connect(_on_game_over)
	GameState.game_restarted.connect(_on_game_restarted)
	GameState.tower_inspected.connect(_on_tower_inspected)
	GameState.draft_ready.connect(_on_draft_ready)
	GameState.relic_draft_ready.connect(_on_relic_draft_ready)
	GameState.relic_acquired.connect(_on_relic_acquired)
	GameState.synergy_activated.connect(_on_synergy_activated)

# ============================================================
# Build
# ============================================================

func _build_ui() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)

	# ── Top bar ───────────────────────────────────────────────
	var top_bar := PanelContainer.new()
	var tb_style := StyleBoxFlat.new()
	tb_style.bg_color = Color(0.04, 0.06, 0.10)
	top_bar.add_theme_stylebox_override("panel", tb_style)
	top_bar.set_anchor(SIDE_LEFT,   0.0)
	top_bar.set_anchor(SIDE_RIGHT,  1.0)
	top_bar.set_anchor(SIDE_TOP,    0.0)
	top_bar.set_anchor(SIDE_BOTTOM, 0.0)
	top_bar.set_offset(SIDE_BOTTOM, 64)
	cl.add_child(top_bar)

	var outer_hbox := HBoxContainer.new()
	outer_hbox.add_theme_constant_override("separation", 0)
	top_bar.add_child(outer_hbox)

	# Vänster — sköld + MAZE TD
	var left_margin := MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left",  12)
	left_margin.add_theme_constant_override("margin_right",  8)
	outer_hbox.add_child(left_margin)

	var left_box := HBoxContainer.new()
	left_box.alignment = BoxContainer.ALIGNMENT_CENTER
	left_box.add_theme_constant_override("separation", 6)
	left_margin.add_child(left_box)

	var shield_lbl := Label.new()
	shield_lbl.text = "🛡"
	shield_lbl.add_theme_font_size_override("font_size", 28)
	shield_lbl.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0))
	left_box.add_child(shield_lbl)

	var title_lbl := Label.new()
	title_lbl.text = "MAZE\nTD"
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0))
	left_box.add_child(title_lbl)

	# Spacer
	var spacer1 := Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_hbox.add_child(spacer1)

	# Mitten — pill med guld + liv
	var pill := PanelContainer.new()
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color                       = Color(0.09, 0.11, 0.16)
	pill_style.corner_radius_top_left         = 22
	pill_style.corner_radius_top_right        = 22
	pill_style.corner_radius_bottom_left      = 22
	pill_style.corner_radius_bottom_right     = 22
	pill.add_theme_stylebox_override("panel", pill_style)
	outer_hbox.add_child(pill)

	var pill_margin := MarginContainer.new()
	pill_margin.add_theme_constant_override("margin_left",   16)
	pill_margin.add_theme_constant_override("margin_right",  16)
	pill_margin.add_theme_constant_override("margin_top",     6)
	pill_margin.add_theme_constant_override("margin_bottom",  6)
	pill.add_child(pill_margin)

	var pill_hbox := HBoxContainer.new()
	pill_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pill_hbox.add_theme_constant_override("separation", 10)
	pill_margin.add_child(pill_hbox)

	# Guld
	var coin_lbl := Label.new()
	coin_lbl.text = "$"
	coin_lbl.add_theme_font_size_override("font_size", 20)
	coin_lbl.add_theme_color_override("font_color", Color(1.0, 0.80, 0.0))
	pill_hbox.add_child(coin_lbl)

	_gold_lbl = Label.new()
	_gold_lbl.text = _format_number(GameState.gold)
	_gold_lbl.add_theme_font_size_override("font_size", 18)
	pill_hbox.add_child(_gold_lbl)

	# Avdelare
	var vsep := Panel.new()
	vsep.custom_minimum_size = Vector2(1, 26)
	var vsep_style := StyleBoxFlat.new()
	vsep_style.bg_color = Color(0.25, 0.27, 0.32)
	vsep.add_theme_stylebox_override("panel", vsep_style)
	pill_hbox.add_child(vsep)

	# Hjärta
	var heart_lbl := Label.new()
	heart_lbl.text = "♥"
	heart_lbl.add_theme_font_size_override("font_size", 16)
	heart_lbl.add_theme_color_override("font_color", Color(0.95, 0.25, 0.35))
	pill_hbox.add_child(heart_lbl)

	_health_bar = ProgressBar.new()
	_health_bar.max_value = GameState.max_escape
	_health_bar.value     = GameState.max_escape
	_health_bar.custom_minimum_size = Vector2(90, 10)
	_health_bar.show_percentage = false
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color                       = Color(0.15, 0.08, 0.08)
	bar_bg.corner_radius_top_left         = 5
	bar_bg.corner_radius_top_right        = 5
	bar_bg.corner_radius_bottom_left      = 5
	bar_bg.corner_radius_bottom_right     = 5
	_health_bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color                       = Color(0.90, 0.22, 0.28)
	bar_fill.corner_radius_top_left         = 5
	bar_fill.corner_radius_top_right        = 5
	bar_fill.corner_radius_bottom_left      = 5
	bar_fill.corner_radius_bottom_right     = 5
	_health_bar.add_theme_stylebox_override("fill", bar_fill)
	pill_hbox.add_child(_health_bar)

	_escaped_lbl = Label.new()
	_escaped_lbl.text = "%d/%d" % [GameState.max_escape, GameState.max_escape]
	_escaped_lbl.add_theme_font_size_override("font_size", 12)
	_escaped_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.75))
	pill_hbox.add_child(_escaped_lbl)

	# Spacer
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_hbox.add_child(spacer2)

	# Relic strip (visar aktiva relics som ikoner)
	_relic_strip_hbox = HBoxContainer.new()
	_relic_strip_hbox.add_theme_constant_override("separation", 4)
	_relic_strip_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	outer_hbox.add_child(_relic_strip_hbox)

	# Höger — wave-info + knappar
	var right_margin := MarginContainer.new()
	right_margin.add_theme_constant_override("margin_right", 12)
	right_margin.add_theme_constant_override("margin_left",   8)
	outer_hbox.add_child(right_margin)

	var right_box := HBoxContainer.new()
	right_box.alignment = BoxContainer.ALIGNMENT_CENTER
	right_box.add_theme_constant_override("separation", 6)
	right_margin.add_child(right_box)

	var wave_vbox := VBoxContainer.new()
	wave_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	wave_vbox.add_theme_constant_override("separation", 0)
	right_box.add_child(wave_vbox)

	var wave_sub_lbl := Label.new()
	wave_sub_lbl.text = "WAVE"
	wave_sub_lbl.add_theme_font_size_override("font_size", 9)
	wave_sub_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
	wave_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wave_vbox.add_child(wave_sub_lbl)

	_wave_lbl = Label.new()
	_wave_lbl.text = "— /\n40"
	_wave_lbl.add_theme_font_size_override("font_size", 18)
	_wave_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wave_vbox.add_child(_wave_lbl)

	_countdown_lbl = Label.new()
	_countdown_lbl.text = ""
	_countdown_lbl.add_theme_font_size_override("font_size", 9)
	_countdown_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
	_countdown_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wave_vbox.add_child(_countdown_lbl)

	_gear_btn = Button.new()
	_gear_btn.text = "⚙"
	_gear_btn.add_theme_font_size_override("font_size", 22)
	_gear_btn.flat = true
	_gear_btn.pressed.connect(_on_settings_toggle)
	right_box.add_child(_gear_btn)

	# ── Settings-panel (dold som standard, öppnas med kugghjulet) ──
	_settings_panel = PanelContainer.new()
	var sp_style := StyleBoxFlat.new()
	sp_style.bg_color                       = Color(0.06, 0.08, 0.12, 0.97)
	sp_style.corner_radius_bottom_left      = 10
	sp_style.corner_radius_bottom_right     = 10
	sp_style.border_width_top               = 0
	_settings_panel.add_theme_stylebox_override("panel", sp_style)
	_settings_panel.set_anchor(SIDE_RIGHT,  1.0)
	_settings_panel.set_anchor(SIDE_TOP,    0.0)
	_settings_panel.set_anchor(SIDE_LEFT,   1.0)
	_settings_panel.set_anchor(SIDE_BOTTOM, 0.0)
	_settings_panel.set_offset(SIDE_LEFT,   -180)
	_settings_panel.set_offset(SIDE_TOP,    64)
	_settings_panel.set_offset(SIDE_BOTTOM, 64 + 140)
	_settings_panel.visible = false
	cl.add_child(_settings_panel)

	var sp_vbox2 := VBoxContainer.new()
	sp_vbox2.add_theme_constant_override("separation", 4)
	_settings_panel.add_child(sp_vbox2)

	_speed_btn = _make_settings_row(sp_vbox2, "⚡", "2x SPEED", _on_speed_toggle)
	_mute_btn  = _make_settings_row(sp_vbox2, "🔊", "SOUND ON",  _on_mute_toggle)
	_drag_side_btn = _make_settings_row(sp_vbox2, "◄", "DRAG LEFT", _on_drag_side_toggle)

	var close_row := Button.new()
	close_row.text = "CLOSE  ✕"
	close_row.flat = true
	close_row.add_theme_font_size_override("font_size", 11)
	close_row.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
	close_row.pressed.connect(func() -> void: _settings_panel.visible = false)
	sp_vbox2.add_child(close_row)

	# ── Tower drawer (bottom, hidden by default) ──────────────
	_tower_drawer = PanelContainer.new()
	_tower_drawer.set_anchor(SIDE_LEFT,   0.0)
	_tower_drawer.set_anchor(SIDE_RIGHT,  1.0)
	_tower_drawer.set_anchor(SIDE_TOP,    1.0)
	_tower_drawer.set_anchor(SIDE_BOTTOM, 1.0)
	_tower_drawer.set_offset(SIDE_TOP,    -240)
	_tower_drawer.set_offset(SIDE_BOTTOM, -44)
	_tower_drawer.visible = false
	cl.add_child(_tower_drawer)

	var dvbox := VBoxContainer.new()
	dvbox.add_theme_constant_override("separation", 6)
	_tower_drawer.add_child(dvbox)

	_tower_grid = GridContainer.new()
	_tower_grid.columns = 2
	_tower_grid.add_theme_constant_override("h_separation", 6)
	_tower_grid.add_theme_constant_override("v_separation", 6)
	dvbox.add_child(_tower_grid)

	_info_lbl = Label.new()
	_info_lbl.text = "Tap a placed tower"
	_info_lbl.add_theme_font_size_override("font_size", 10)
	_info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dvbox.add_child(_info_lbl)

	var clear_btn := Button.new()
	clear_btn.text = "Clear all towers"
	clear_btn.pressed.connect(func() -> void: clear_all_pressed.emit())
	dvbox.add_child(clear_btn)

	# ── Toggle button (full-width strip at very bottom) ───────
	_tower_toggle = Button.new()
	_tower_toggle.text = "Towers  v"
	_tower_toggle.set_anchor(SIDE_LEFT,   0.0)
	_tower_toggle.set_anchor(SIDE_RIGHT,  1.0)
	_tower_toggle.set_anchor(SIDE_TOP,    1.0)
	_tower_toggle.set_anchor(SIDE_BOTTOM, 1.0)
	_tower_toggle.set_offset(SIDE_TOP,    -44)
	_tower_toggle.set_offset(SIDE_BOTTOM, 0)
	_tower_toggle.pressed.connect(_toggle_drawer)
	cl.add_child(_tower_toggle)

	# ── Send Wave overlay (bottom-right, synligt mellan waves) ──
	_send_btn_wrap = Control.new()
	_send_btn_wrap.set_anchor(SIDE_LEFT,   0.0)
	_send_btn_wrap.set_anchor(SIDE_RIGHT,  1.0)
	_send_btn_wrap.set_anchor(SIDE_TOP,    1.0)
	_send_btn_wrap.set_anchor(SIDE_BOTTOM, 1.0)
	_send_btn_wrap.set_offset(SIDE_TOP,    -104)
	_send_btn_wrap.set_offset(SIDE_BOTTOM, -55)
	cl.add_child(_send_btn_wrap)

	# Right-align the button strip
	var send_hbox := HBoxContainer.new()
	send_hbox.alignment = BoxContainer.ALIGNMENT_END
	send_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_send_btn_wrap.add_child(send_hbox)

	var send_margin := MarginContainer.new()
	send_margin.add_theme_constant_override("margin_right", 16)
	send_hbox.add_child(send_margin)

	_send_early_btn = Button.new()
	_send_early_btn.text = "SEND WAVE  »"
	_send_early_btn.add_theme_font_size_override("font_size", 16)
	_send_early_btn.custom_minimum_size = Vector2(162, 44)
	_send_early_btn.add_theme_color_override("font_color", Color(0.06, 0.03, 0.01))

	var _make_send_sb := func(bg: Color) -> StyleBoxFlat:
		var sb := StyleBoxFlat.new()
		sb.bg_color                       = bg
		sb.corner_radius_top_left         = 8
		sb.corner_radius_top_right        = 8
		sb.corner_radius_bottom_left      = 8
		sb.corner_radius_bottom_right     = 8
		sb.border_width_left              = 1
		sb.border_width_right             = 1
		sb.border_width_top               = 1
		sb.border_width_bottom            = 1
		sb.border_color                   = Color(1.0, 0.72, 0.28, 0.55)
		return sb

	_send_early_btn.add_theme_stylebox_override("normal",  _make_send_sb.call(Color(0.88, 0.42, 0.06)))
	_send_early_btn.add_theme_stylebox_override("hover",   _make_send_sb.call(Color(1.00, 0.54, 0.10)))
	_send_early_btn.add_theme_stylebox_override("pressed", _make_send_sb.call(Color(0.62, 0.28, 0.03)))
	_send_early_btn.pressed.connect(func() -> void: start_wave_pressed.emit())
	send_margin.add_child(_send_early_btn)

	# ── Status overlay (just below top bar) ───────────────────
	_status_lbl = Label.new()
	_status_lbl.position = Vector2(4, 56)
	_status_lbl.text     = ""
	_status_lbl.add_theme_font_size_override("font_size", 11)
	_status_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	cl.add_child(_status_lbl)
	_toast_lbl = Label.new()
	_toast_lbl.position = Vector2(0, 72)
	_toast_lbl.set_anchor(SIDE_LEFT,  0.0)
	_toast_lbl.set_anchor(SIDE_RIGHT, 1.0)
	_toast_lbl.add_theme_font_size_override("font_size", 13)
	_toast_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 0.0))
	_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(_toast_lbl)

	_wave_preview_lbl = Label.new()
	_wave_preview_lbl.set_anchor(SIDE_LEFT,   0.0)
	_wave_preview_lbl.set_anchor(SIDE_RIGHT,  1.0)
	_wave_preview_lbl.set_anchor(SIDE_TOP,    1.0)
	_wave_preview_lbl.set_anchor(SIDE_BOTTOM, 1.0)
	_wave_preview_lbl.set_offset(SIDE_TOP,    -112)
	_wave_preview_lbl.set_offset(SIDE_BOTTOM, -56)
	_wave_preview_lbl.add_theme_font_size_override("font_size", 11)
	_wave_preview_lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.75))
	_wave_preview_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_preview_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(_wave_preview_lbl)

	# Persistent synergy strip — bottom-left, shows active synergies
	_synergy_strip_lbl = Label.new()
	_synergy_strip_lbl.set_anchor(SIDE_LEFT,   0.0)
	_synergy_strip_lbl.set_anchor(SIDE_RIGHT,  0.5)
	_synergy_strip_lbl.set_anchor(SIDE_TOP,    1.0)
	_synergy_strip_lbl.set_anchor(SIDE_BOTTOM, 1.0)
	_synergy_strip_lbl.set_offset(SIDE_TOP,    -148)
	_synergy_strip_lbl.set_offset(SIDE_BOTTOM, -112)
	_synergy_strip_lbl.set_offset(SIDE_LEFT,   6)
	_synergy_strip_lbl.add_theme_font_size_override("font_size", 11)
	_synergy_strip_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.85))
	_synergy_strip_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_synergy_strip_lbl.text = ""
	cl.add_child(_synergy_strip_lbl)

	# ── Tower info card (bottom-sheet, icke-blockerande) ─────────
	_ic_backdrop = ColorRect.new()
	_ic_backdrop.color = Color(0.0, 0.0, 0.0, 0.0)
	_ic_backdrop.set_anchor(SIDE_LEFT,   0.0)
	_ic_backdrop.set_anchor(SIDE_RIGHT,  1.0)
	_ic_backdrop.set_anchor(SIDE_TOP,    0.0)
	_ic_backdrop.set_anchor(SIDE_BOTTOM, 1.0)
	_ic_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ic_backdrop.gui_input.connect(_on_ic_backdrop_input)
	cl.add_child(_ic_backdrop)

	_info_card = PanelContainer.new()
	var ic_style := StyleBoxFlat.new()
	ic_style.bg_color                       = Color(0.06, 0.08, 0.13, 0.97)
	ic_style.corner_radius_top_left         = 14
	ic_style.corner_radius_top_right        = 14
	ic_style.corner_radius_bottom_left      = 0
	ic_style.corner_radius_bottom_right     = 0
	ic_style.border_width_top               = 1
	ic_style.border_color                   = Color(0.20, 0.22, 0.30)
	_info_card.add_theme_stylebox_override("panel", ic_style)
	_info_card.set_anchor(SIDE_LEFT,   0.0)
	_info_card.set_anchor(SIDE_RIGHT,  1.0)
	_info_card.set_anchor(SIDE_TOP,    1.0)
	_info_card.set_anchor(SIDE_BOTTOM, 1.0)
	_info_card.set_offset(SIDE_TOP,    0)
	_info_card.set_offset(SIDE_BOTTOM, -44)
	_info_card.visible = false
	cl.add_child(_info_card)

	var ic_margin := MarginContainer.new()
	ic_margin.add_theme_constant_override("margin_left",   16)
	ic_margin.add_theme_constant_override("margin_right",  16)
	ic_margin.add_theme_constant_override("margin_top",    10)
	ic_margin.add_theme_constant_override("margin_bottom", 12)
	_info_card.add_child(ic_margin)

	var ic_vbox := VBoxContainer.new()
	ic_vbox.add_theme_constant_override("separation", 6)
	ic_margin.add_child(ic_vbox)

	# Drag-handtag
	var ic_handle_row := HBoxContainer.new()
	ic_handle_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ic_vbox.add_child(ic_handle_row)

	var ic_handle := Panel.new()
	ic_handle.custom_minimum_size = Vector2(40, 4)
	ic_handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ih_style := StyleBoxFlat.new()
	ih_style.bg_color                       = Color(0.30, 0.32, 0.40)
	ih_style.corner_radius_top_left         = 2
	ih_style.corner_radius_top_right        = 2
	ih_style.corner_radius_bottom_left      = 2
	ih_style.corner_radius_bottom_right     = 2
	ic_handle.add_theme_stylebox_override("panel", ih_style)
	ic_handle_row.add_child(ic_handle)

	# Namnrad + stäng-knapp
	var ic_name_row := HBoxContainer.new()
	ic_name_row.add_theme_constant_override("separation", 0)
	ic_vbox.add_child(ic_name_row)

	_ic_name_lbl = Label.new()
	_ic_name_lbl.add_theme_font_size_override("font_size", 20)
	_ic_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ic_name_row.add_child(_ic_name_lbl)

	var ic_close_btn := Button.new()
	ic_close_btn.text = "✕"
	ic_close_btn.flat = true
	ic_close_btn.add_theme_font_size_override("font_size", 18)
	ic_close_btn.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
	ic_close_btn.pressed.connect(_hide_info_card)
	ic_name_row.add_child(ic_close_btn)

	# Stats
	_ic_stats_lbl = Label.new()
	_ic_stats_lbl.add_theme_font_size_override("font_size", 13)
	_ic_stats_lbl.add_theme_color_override("font_color", Color(0.78, 0.80, 0.88))
	_ic_stats_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	ic_vbox.add_child(_ic_stats_lbl)

	# Lore
	_ic_lore_lbl = Label.new()
	_ic_lore_lbl.add_theme_font_size_override("font_size", 12)
	_ic_lore_lbl.add_theme_color_override("font_color", Color(0.52, 0.50, 0.60))
	_ic_lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ic_lore_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ic_vbox.add_child(_ic_lore_lbl)

	var ic_sep := HSeparator.new()
	var sep_sb := StyleBoxFlat.new()
	sep_sb.bg_color = Color(0.15, 0.17, 0.24)
	ic_sep.add_theme_stylebox_override("separator", sep_sb)
	ic_vbox.add_child(ic_sep)

	# Säljrad
	var ic_sell_row := HBoxContainer.new()
	ic_sell_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ic_sell_row.add_theme_constant_override("separation", 16)
	ic_vbox.add_child(ic_sell_row)

	_ic_sell_price_lbl = Label.new()
	_ic_sell_price_lbl.add_theme_font_size_override("font_size", 15)
	_ic_sell_price_lbl.add_theme_color_override("font_color", Color(1.0, 0.80, 0.0))
	_ic_sell_price_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ic_sell_row.add_child(_ic_sell_price_lbl)

	_ic_sell_btn = Button.new()
	_ic_sell_btn.text = "SELL  💰"
	_ic_sell_btn.custom_minimum_size = Vector2(110, 44)
	_ic_sell_btn.add_theme_font_size_override("font_size", 15)
	var ic_sell_sb := StyleBoxFlat.new()
	ic_sell_sb.bg_color                       = Color(0.75, 0.22, 0.12)
	ic_sell_sb.corner_radius_top_left         = 8
	ic_sell_sb.corner_radius_top_right        = 8
	ic_sell_sb.corner_radius_bottom_left      = 8
	ic_sell_sb.corner_radius_bottom_right     = 8
	_ic_sell_btn.add_theme_stylebox_override("normal", ic_sell_sb)
	var ic_sell_hover := ic_sell_sb.duplicate() as StyleBoxFlat
	ic_sell_hover.bg_color = Color(0.90, 0.28, 0.14)
	_ic_sell_btn.add_theme_stylebox_override("hover",   ic_sell_hover)
	var ic_sell_press := ic_sell_sb.duplicate() as StyleBoxFlat
	ic_sell_press.bg_color = Color(0.55, 0.15, 0.08)
	_ic_sell_btn.add_theme_stylebox_override("pressed", ic_sell_press)
	_ic_sell_btn.pressed.connect(func() -> void:
		_hide_info_card()
		sell_tower_pressed.emit())
	ic_sell_row.add_child(_ic_sell_btn)

	# ── Draft overlay ─────────────────────────────────────────────
	_draft_overlay = ColorRect.new()
	(_draft_overlay as ColorRect).color = Color(0.04, 0.05, 0.08, 0.94)
	_draft_overlay.set_anchor(SIDE_LEFT,   0.0)
	_draft_overlay.set_anchor(SIDE_RIGHT,  1.0)
	_draft_overlay.set_anchor(SIDE_TOP,    0.0)
	_draft_overlay.set_anchor(SIDE_BOTTOM, 1.0)
	_draft_overlay.visible = false
	cl.add_child(_draft_overlay)

	var do_outer := VBoxContainer.new()
	do_outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	do_outer.alignment = BoxContainer.ALIGNMENT_CENTER
	_draft_overlay.add_child(do_outer)

	var do_margin := MarginContainer.new()
	do_margin.add_theme_constant_override("margin_left", 12)
	do_margin.add_theme_constant_override("margin_right", 12)
	do_outer.add_child(do_margin)

	var do_vbox := VBoxContainer.new()
	do_vbox.add_theme_constant_override("separation", 14)
	do_margin.add_child(do_vbox)

	var do_title := Label.new()
	do_title.text = "CHOOSE YOUR NEXT TOWER"
	do_title.add_theme_font_size_override("font_size", 18)
	do_title.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0))
	do_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	do_vbox.add_child(do_title)

	var do_sub := Label.new()
	do_sub.text = "— pick 1 —"
	do_sub.add_theme_font_size_override("font_size", 10)
	do_sub.add_theme_color_override("font_color", Color(0.40, 0.42, 0.50))
	do_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	do_vbox.add_child(do_sub)

	var do_cards_vbox := VBoxContainer.new()
	do_cards_vbox.add_theme_constant_override("separation", 10)
	do_vbox.add_child(do_cards_vbox)

	for _i in 3:
		var card := Button.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(0, 90)
		card.visible = false
		do_cards_vbox.add_child(card)
		_draft_cards.append(card)

	# ── Relic draft overlay ───────────────────────────────────────
	_relic_draft_overlay = ColorRect.new()
	(_relic_draft_overlay as ColorRect).color = Color(0.04, 0.05, 0.08, 0.95)
	_relic_draft_overlay.set_anchor(SIDE_LEFT,   0.0)
	_relic_draft_overlay.set_anchor(SIDE_RIGHT,  1.0)
	_relic_draft_overlay.set_anchor(SIDE_TOP,    0.0)
	_relic_draft_overlay.set_anchor(SIDE_BOTTOM, 1.0)
	_relic_draft_overlay.visible = false
	cl.add_child(_relic_draft_overlay)

	var rd_center := CenterContainer.new()
	rd_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_relic_draft_overlay.add_child(rd_center)

	var rd_vbox := VBoxContainer.new()
	rd_vbox.add_theme_constant_override("separation", 14)
	rd_center.add_child(rd_vbox)

	var rd_title := Label.new()
	rd_title.text = "CHOOSE A RELIC"
	rd_title.add_theme_font_size_override("font_size", 18)
	rd_title.add_theme_color_override("font_color", Color(1.0, 0.75, 0.1))
	rd_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rd_vbox.add_child(rd_title)

	var rd_sub := Label.new()
	rd_sub.text = "— global passive —"
	rd_sub.add_theme_font_size_override("font_size", 10)
	rd_sub.add_theme_color_override("font_color", Color(0.40, 0.42, 0.50))
	rd_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rd_vbox.add_child(rd_sub)

	var rd_cards_hbox := HBoxContainer.new()
	rd_cards_hbox.add_theme_constant_override("separation", 12)
	rd_vbox.add_child(rd_cards_hbox)

	for _i in 3:
		var card := Button.new()
		card.custom_minimum_size = Vector2(128, 160)
		card.visible = false
		rd_cards_hbox.add_child(card)
		_relic_draft_cards.append(card)

	# ── Run Summary overlay ─────────────────────────────────────
	_summary_overlay = ColorRect.new()
	(_summary_overlay as ColorRect).color = Color(0.04, 0.05, 0.08, 0.96)
	_summary_overlay.set_anchor(SIDE_LEFT,   0.0)
	_summary_overlay.set_anchor(SIDE_RIGHT,  1.0)
	_summary_overlay.set_anchor(SIDE_TOP,    0.0)
	_summary_overlay.set_anchor(SIDE_BOTTOM, 1.0)
	_summary_overlay.visible = false
	cl.add_child(_summary_overlay)

	var sum_center := CenterContainer.new()
	sum_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_summary_overlay.add_child(sum_center)

	var sum_vbox := VBoxContainer.new()
	sum_vbox.add_theme_constant_override("separation", 10)
	sum_center.add_child(sum_vbox)

	var sum_title := Label.new()
	sum_title.text = "RUN OVER"
	sum_title.add_theme_font_size_override("font_size", 32)
	sum_title.add_theme_color_override("font_color", Color(0.95, 0.25, 0.35))
	sum_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sum_vbox.add_child(sum_title)

	var sum_panel := PanelContainer.new()
	var sum_style := StyleBoxFlat.new()
	sum_style.bg_color                       = Color(0.08, 0.10, 0.15)
	sum_style.corner_radius_top_left         = 12
	sum_style.corner_radius_top_right        = 12
	sum_style.corner_radius_bottom_left      = 12
	sum_style.corner_radius_bottom_right     = 12
	sum_panel.add_theme_stylebox_override("panel", sum_style)
	sum_panel.custom_minimum_size = Vector2(260, 0)
	sum_vbox.add_child(sum_panel)

	var sum_m := MarginContainer.new()
	sum_m.add_theme_constant_override("margin_left",   20)
	sum_m.add_theme_constant_override("margin_right",  20)
	sum_m.add_theme_constant_override("margin_top",    16)
	sum_m.add_theme_constant_override("margin_bottom", 16)
	sum_panel.add_child(sum_m)

	var sum_inner := VBoxContainer.new()
	sum_inner.add_theme_constant_override("separation", 8)
	sum_m.add_child(sum_inner)

	_summary_wave_lbl   = Label.new()
	_summary_towers_lbl = Label.new()
	_summary_syn_lbl    = Label.new()
	_summary_relic_lbl  = Label.new()
	_summary_best_lbl   = Label.new()

	for lbl: Label in [_summary_wave_lbl, _summary_towers_lbl,
			_summary_syn_lbl, _summary_relic_lbl, _summary_best_lbl]:
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.80, 0.82, 0.90))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sum_inner.add_child(lbl)

	_summary_best_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))

	var sum_close := Button.new()
	sum_close.text = "BACK TO MENU"
	sum_close.add_theme_font_size_override("font_size", 16)
	sum_close.custom_minimum_size = Vector2(0, 48)
	var scn := StyleBoxFlat.new()
	scn.bg_color = Color(0.15, 0.18, 0.25)
	scn.corner_radius_top_left    = 8; scn.corner_radius_top_right    = 8
	scn.corner_radius_bottom_left = 8; scn.corner_radius_bottom_right = 8
	sum_close.add_theme_stylebox_override("normal", scn)
	sum_close.pressed.connect(func() -> void:
		_summary_overlay.visible = false
		_start_screen.visible    = true)
	sum_vbox.add_child(sum_close)

	# ── Start screen (added last = renders on top) ────────────
	_start_screen = ColorRect.new()
	(_start_screen as ColorRect).color = Color(0.04, 0.05, 0.08, 0.98)
	_start_screen.set_anchor(SIDE_LEFT,   0.0)
	_start_screen.set_anchor(SIDE_RIGHT,  1.0)
	_start_screen.set_anchor(SIDE_TOP,    0.0)
	_start_screen.set_anchor(SIDE_BOTTOM, 1.0)
	cl.add_child(_start_screen)

	var sc_scroll := ScrollContainer.new()
	sc_scroll.set_anchor(SIDE_LEFT,   0.0)
	sc_scroll.set_anchor(SIDE_RIGHT,  1.0)
	sc_scroll.set_anchor(SIDE_TOP,    0.0)
	sc_scroll.set_anchor(SIDE_BOTTOM, 1.0)
	sc_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_start_screen.add_child(sc_scroll)

	var sc_outer := VBoxContainer.new()
	sc_outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc_scroll.add_child(sc_outer)

	var sc_margin := MarginContainer.new()
	sc_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc_margin.add_theme_constant_override("margin_left",   20)
	sc_margin.add_theme_constant_override("margin_right",  20)
	sc_margin.add_theme_constant_override("margin_top",    24)
	sc_margin.add_theme_constant_override("margin_bottom", 24)
	sc_outer.add_child(sc_margin)

	var svbox := VBoxContainer.new()
	svbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	svbox.add_theme_constant_override("separation", 18)
	sc_margin.add_child(svbox)

	# Logotyp
	var main_title := Label.new()
	main_title.text = "MAZE TD"
	main_title.add_theme_font_size_override("font_size", 52)
	main_title.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0))
	main_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	svbox.add_child(main_title)

	var sc_subtitle := Label.new()
	sc_subtitle.text = "ETHEREAL MONOLITH ASCENSION"
	sc_subtitle.add_theme_font_size_override("font_size", 10)
	sc_subtitle.add_theme_color_override("font_color", Color(0.85, 0.55, 0.10))
	sc_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	svbox.add_child(sc_subtitle)

	# ── Kartval ───────────────────────────────────────────────
	svbox.add_child(_section_header("CHOOSE MAP"))

	var sc_map_row := HBoxContainer.new()
	sc_map_row.add_theme_constant_override("separation", 10)
	svbox.add_child(sc_map_row)

	var sc_map_labels: Array[String] = ["Classic", "Mandala"]
	var sc_map_icons:  Array[String] = ["⬛", "◎"]
	for i in 2:
		var mbtn := Button.new()
		mbtn.text = "%s\n%s" % [sc_map_icons[i], sc_map_labels[i]]
		mbtn.toggle_mode = true
		mbtn.button_pressed = (i == 0)
		mbtn.add_theme_font_size_override("font_size", 16)
		mbtn.custom_minimum_size = Vector2(0, 80)
		mbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var mn := StyleBoxFlat.new()
		mn.bg_color = Color(0.08, 0.10, 0.14)
		mn.corner_radius_top_left    = 10; mn.corner_radius_top_right    = 10
		mn.corner_radius_bottom_left = 10; mn.corner_radius_bottom_right = 10
		mbtn.add_theme_stylebox_override("normal", mn)
		var mp := mn.duplicate() as StyleBoxFlat
		mp.border_width_left = 2; mp.border_width_right = 2
		mp.border_width_top  = 2; mp.border_width_bottom = 2
		mp.border_color = Color(0.0, 0.85, 1.0)
		mbtn.add_theme_stylebox_override("pressed", mp)
		mbtn.add_theme_stylebox_override("hover",   mp.duplicate())
		mbtn.pressed.connect(_on_map_btn.bind(i))
		sc_map_row.add_child(mbtn)
		_map_btns.append(mbtn)

	# ── Svårighetsgrad ────────────────────────────────────────
	svbox.add_child(_section_header("CHALLENGE"))

	var sc_diff_row := HBoxContainer.new()
	sc_diff_row.add_theme_constant_override("separation", 8)
	svbox.add_child(sc_diff_row)

	var sc_diff_labels: Array[String] = ["EASY", "MEDIUM", "HARD"]
	for i in 3:
		var dbtn := Button.new()
		dbtn.text = sc_diff_labels[i]
		dbtn.toggle_mode = true
		dbtn.button_pressed = (i == _pending_difficulty)
		dbtn.add_theme_font_size_override("font_size", 14)
		dbtn.custom_minimum_size = Vector2(0, 44)
		dbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var dn := StyleBoxFlat.new()
		dn.bg_color = Color(0.08, 0.10, 0.14)
		dn.corner_radius_top_left    = 8; dn.corner_radius_top_right    = 8
		dn.corner_radius_bottom_left = 8; dn.corner_radius_bottom_right = 8
		dbtn.add_theme_stylebox_override("normal", dn)
		var dp := dn.duplicate() as StyleBoxFlat
		dp.bg_color = Color(0.12, 0.16, 0.22)
		dp.border_width_left = 2; dp.border_width_right = 2
		dp.border_width_top  = 2; dp.border_width_bottom = 2
		dp.border_color = Color(0.0, 0.85, 1.0)
		dbtn.add_theme_stylebox_override("pressed", dp)
		dbtn.add_theme_stylebox_override("hover",   dp.duplicate())
		dbtn.pressed.connect(_on_diff_btn.bind(i))
		sc_diff_row.add_child(dbtn)
		_diff_btns.append(dbtn)

	# ── Start-knapp ───────────────────────────────────────────
	var sc_start_btn := Button.new()
	sc_start_btn.text = "▶  START GAME"
	sc_start_btn.add_theme_font_size_override("font_size", 22)
	sc_start_btn.custom_minimum_size = Vector2(0, 60)
	sc_start_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sbn := StyleBoxFlat.new()
	sbn.bg_color = Color(0.0, 0.75, 0.90)
	sbn.corner_radius_top_left    = 10; sbn.corner_radius_top_right    = 10
	sbn.corner_radius_bottom_left = 10; sbn.corner_radius_bottom_right = 10
	sc_start_btn.add_theme_stylebox_override("normal", sbn)
	var sbh := sbn.duplicate() as StyleBoxFlat
	sbh.bg_color = Color(0.0, 0.90, 1.0)
	sc_start_btn.add_theme_stylebox_override("hover", sbh)
	var sbp := sbn.duplicate() as StyleBoxFlat
	sbp.bg_color = Color(0.0, 0.55, 0.68)
	sc_start_btn.add_theme_stylebox_override("pressed", sbp)
	sc_start_btn.add_theme_color_override("font_color", Color(0.04, 0.05, 0.08))
	sc_start_btn.pressed.connect(_do_start)
	svbox.add_child(sc_start_btn)

	var sc_footer := Label.new()
	sc_footer.text = "CHOOSE MAP · DIFFICULTY TO BEGIN"
	sc_footer.add_theme_font_size_override("font_size", 9)
	sc_footer.add_theme_color_override("font_color", Color(0.30, 0.30, 0.38))
	sc_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	svbox.add_child(sc_footer)

	_sc_best_lbl = Label.new()
	_sc_best_lbl.add_theme_font_size_override("font_size", 11)
	_sc_best_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_sc_best_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	svbox.add_child(_sc_best_lbl)
	_update_best_label()

# ============================================================
# Private helpers
# ============================================================

func _update_best_label() -> void:
	if GameState.best_wave == 0:
		_sc_best_lbl.text = ""
	else:
		_sc_best_lbl.text = "🏆 Best: Wave %d  •  Runs: %d" % [
			GameState.best_wave, GameState.runs_played]


func _format_tower_stats(type: int) -> String:
	var dps: float = TowerDefs.DAMAGE[type] * TowerDefs.FIRERATE[type]
	var sz: Vector2i = TowerDefs.SIZES[type]
	var size_str := "" if sz == Vector2i(1, 1) else "  ▣ %d×%d" % [sz.x, sz.y]
	var aoe_str := "  ◎ %.1ft" % TowerDefs.SPLASH[type] if TowerDefs.AOE[type] else ""
	var air_str := "  ✈ ×%.0f" % TowerDefs.AIR_MULT[type] \
		if TowerDefs.AIR_MULT[type] > 1.0 else ""
	return "⚔ %.0f  📡 %.1ft  ⚡ %.2f/s\n◈ %.0f dps%s%s%s" % [
		TowerDefs.DAMAGE[type],
		TowerDefs.RANGE[type],
		TowerDefs.FIRERATE[type],
		dps,
		aoe_str,
		air_str,
		size_str,
	]


func _format_tower_stats_short(type: int) -> String:
	var dps: float = TowerDefs.DAMAGE[type] * TowerDefs.FIRERATE[type]
	var aoe_dot := " ◎" if TowerDefs.AOE[type] else ""
	var air_dot := " ✈" if TowerDefs.AIR_MULT[type] > 1.0 else ""
	return "⚔ %.0f  📡 %.1ft%s%s\n◈ %.0f dps" % [
		TowerDefs.DAMAGE[type],
		TowerDefs.RANGE[type],
		aoe_dot,
		air_dot,
		dps,
	]


func _make_lbl(txt: String, expand: bool) -> Label:
	var lbl: Label = Label.new()
	lbl.text = txt
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return lbl


func _toggle_drawer() -> void:
	_tower_drawer.visible = not _tower_drawer.visible
	_tower_toggle.text    = "Towers  ^" if _tower_drawer.visible else "Towers  v"


# ============================================================
# GameState signal handlers
# ============================================================

func _on_gold_changed(amount: int) -> void:
	_gold_lbl.text = _format_number(amount)


func _on_escaped_changed(current: int, max_val: int) -> void:
	var remaining := max_val - current
	_health_bar.max_value = max_val
	_health_bar.value     = remaining
	_escaped_lbl.text     = "%d/%d" % [remaining, max_val]


func _on_wave_started(wave_num: int, _banner: String) -> void:
	_wave_lbl.text              = "%d /\n40" % wave_num
	_countdown_lbl.text         = ""
	_send_btn_wrap.visible      = false
	_wave_preview_lbl.text      = ""


func _on_wave_completed(_wave_num: int, _bonus: int) -> void:
	_send_early_btn.text        = "SEND WAVE  »"
	_send_btn_wrap.visible      = true
	_send_early_btn.disabled    = false


func show_run_summary() -> void:
	_summary_wave_lbl.text = "📊 Wave nådd: %d / 40" % GameState.wave

	var tower_names: Array[String] = []
	for idx: int in GameState.unlocked_towers:
		tower_names.append(TowerDefs.NAMES[idx])
	_summary_towers_lbl.text = "🏗 Torn upplåsta: " + (", ".join(tower_names) if not tower_names.is_empty() else "—")

	if GameState.active_synergies.is_empty():
		_summary_syn_lbl.text = "🔗 Synergier: —"
	else:
		var syn_names: Array[String] = []
		for sid: String in GameState.active_synergies:
			for syn: Dictionary in SynergyDefs.SYNERGIES:
				if syn.id == sid:
					syn_names.append(syn.icon + " " + syn.name)
		_summary_syn_lbl.text = "🔗 Synergier: " + ", ".join(syn_names)

	if GameState.active_relics.is_empty():
		_summary_relic_lbl.text = "✨ Relics: —"
	else:
		var relic_names: Array[String] = []
		for rel: Dictionary in GameState.active_relics:
			relic_names.append(rel.icon + " " + rel.name)
		_summary_relic_lbl.text = "✨ Relics: " + ", ".join(relic_names)

	_summary_best_lbl.text = "🏆 Bäst: Wave %d  •  Runs: %d" % [
		GameState.best_wave, GameState.runs_played]

	_summary_overlay.visible = true


func _on_game_over() -> void:
	Engine.time_scale           = 1.0
	_speed_btn.text             = "⚡  1x SPEED"
	_countdown_lbl.text         = "GAME OVER"
	_send_btn_wrap.visible      = true
	_send_early_btn.text        = "RESTART"
	_send_early_btn.disabled    = false


func _on_game_restarted() -> void:
	Engine.time_scale           = 1.0
	_speed_btn.text             = "⚡  1x SPEED"
	_wave_lbl.text              = "— /\n40"
	_gold_lbl.text              = _format_number(GameState.gold)
	_health_bar.max_value       = GameState.max_escape
	_health_bar.value           = GameState.max_escape
	_escaped_lbl.text           = "%d/%d" % [GameState.max_escape, GameState.max_escape]
	_countdown_lbl.text         = ""
	_send_early_btn.text        = "SEND WAVE  »"
	_send_btn_wrap.visible      = true
	_send_early_btn.disabled    = false
	_info_lbl.text = "Tap a placed tower"
	_info_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.75))
	_hide_info_card()
	for btn in _tower_btns:
		btn.button_pressed = false
	for i in _map_btns.size():
		_map_btns[i].button_pressed = (i == _selected_map)
	if _tower_drawer.visible:
		_toggle_drawer()
	# Återställ val
	_pending_difficulty = 1
	for i in _diff_btns.size():
		_diff_btns[i].button_pressed = (i == 1)
	_summary_overlay.visible = false
	_update_best_label()
	_start_screen.visible = true
	_rebuild_relic_strip()
	_rebuild_synergy_strip()


func _on_tower_inspected(tower: Dictionary) -> void:
	if tower.is_empty():
		_hide_info_card()
		return
	var type: int = tower.type
	var stroke: Color = TowerDefs.STROKE[type]
	var sell_price: int = int(TowerDefs.COST[type] * 0.75)
	_ic_name_lbl.text = TowerDefs.NAMES[type]
	_ic_name_lbl.add_theme_color_override("font_color", stroke)
	# Uppdatera top-border-färgen på info-kortet till tornets stroke-färg
	var ic_style := StyleBoxFlat.new()
	ic_style.bg_color                   = Color(0.06, 0.08, 0.13, 0.97)
	ic_style.corner_radius_top_left     = 14
	ic_style.corner_radius_top_right    = 14
	ic_style.corner_radius_bottom_left  = 0
	ic_style.corner_radius_bottom_right = 0
	ic_style.border_width_top           = 2
	ic_style.border_color               = stroke
	_info_card.add_theme_stylebox_override("panel", ic_style)
	_ic_stats_lbl.text       = _format_tower_stats(type)
	_ic_lore_lbl.text        = '"%s"' % TowerDefs.LORE[type]
	_ic_sell_price_lbl.text  = "💰 Refund: %dg" % sell_price
	_show_info_card()


func _show_info_card() -> void:
	_info_card.visible = true
	_ic_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	await get_tree().process_frame
	var card_h: float = _info_card.size.y
	_info_card.set_offset(SIDE_TOP,    card_h)
	_info_card.set_offset(SIDE_BOTTOM, card_h - 44)
	if _ic_anim_tween and _ic_anim_tween.is_valid():
		_ic_anim_tween.kill()
	_ic_anim_tween = get_tree().create_tween()
	_ic_anim_tween.set_ease(Tween.EASE_OUT)
	_ic_anim_tween.set_trans(Tween.TRANS_CUBIC)
	_ic_anim_tween.tween_method(
		func(v: float) -> void:
			_info_card.set_offset(SIDE_TOP,    v)
			_info_card.set_offset(SIDE_BOTTOM, v - 44),
		card_h, -card_h, 0.28
	)


func _hide_info_card() -> void:
	if not _info_card.visible:
		return
	_ic_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card_h: float = _info_card.size.y
	if _ic_anim_tween and _ic_anim_tween.is_valid():
		_ic_anim_tween.kill()
	_ic_anim_tween = get_tree().create_tween()
	_ic_anim_tween.set_ease(Tween.EASE_IN)
	_ic_anim_tween.set_trans(Tween.TRANS_CUBIC)
	_ic_anim_tween.tween_method(
		func(v: float) -> void:
			_info_card.set_offset(SIDE_TOP,    v)
			_info_card.set_offset(SIDE_BOTTOM, v - 44),
		-card_h, card_h, 0.20
	)
	_ic_anim_tween.tween_callback(func() -> void: _info_card.visible = false)


func _on_ic_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_hide_info_card()


func _on_draft_ready(offer: Array[int]) -> void:
	for i in _draft_cards.size():
		var card := _draft_cards[i]
		if i >= offer.size():
			card.visible = false
			continue
		var t := offer[i]
		var stroke: Color = TowerDefs.STROKE[t]

		# Rensa gamla signal-kopplingar
		for conn in card.pressed.get_connections():
			card.pressed.disconnect(conn["callable"])

		# Stil — mörk bakgrund med färgad vänsterkant
		var sb := StyleBoxFlat.new()
		sb.bg_color                       = Color(0.06, 0.08, 0.13)
		sb.corner_radius_top_left         = 10
		sb.corner_radius_top_right        = 10
		sb.corner_radius_bottom_left      = 10
		sb.corner_radius_bottom_right     = 10
		sb.border_width_left              = 3
		sb.border_color                   = stroke
		card.add_theme_stylebox_override("normal", sb)
		var sbh := sb.duplicate() as StyleBoxFlat
		sbh.bg_color           = Color(stroke.r * 0.18, stroke.g * 0.18, stroke.b * 0.18)
		sbh.border_width_left  = 3
		sbh.border_width_right = 1
		sbh.border_width_top   = 1
		sbh.border_width_bottom = 1
		card.add_theme_stylebox_override("hover",   sbh)
		card.add_theme_stylebox_override("pressed", sbh)

		# Text — tema, namn, stats, lore
		var dps: float = TowerDefs.DAMAGE[t] * TowerDefs.FIRERATE[t]
		var slow_str := "\n🧊 slow %.0f%%" % (TowerDefs.SLOW[t] * 100.0) \
			if TowerDefs.SLOW[t] > 0.0 else ""
		var dot_str  := "\n☠ %.0f/s" % TowerDefs.DOT[t] \
			if TowerDefs.DOT[t] > 0.0 else ""
		var aoe_str  := "  ◎" if TowerDefs.AOE[t] else ""
		card.text = "%s\n%s\n\n⚔ %.0f  📡 %.1ft%s\n◈ %.0f dps%s%s\n\n💰 %dg\n\n%s" % [
			TowerDefs.THEME[t].to_upper(),
			TowerDefs.NAMES[t],
			TowerDefs.DAMAGE[t], TowerDefs.RANGE[t], aoe_str,
			dps, slow_str, dot_str,
			TowerDefs.COST[t],
			TowerDefs.LORE[t],
		]
		card.add_theme_font_size_override("font_size", 11)
		card.add_theme_color_override("font_color",
			Color(stroke.r, stroke.g, stroke.b, 0.95))
		card.visible = true
		card.pressed.connect(func() -> void: _on_draft_pick(t))

	_draft_overlay.visible = true


func _on_draft_pick(tower_idx: int) -> void:
	GameState.unlocked_towers.append(tower_idx)
	GameState.draft_pending   = false
	_draft_overlay.visible    = false
	_rebuild_tower_buttons_from_unlocked()


func _rebuild_tower_buttons_from_unlocked() -> void:
	for child in _tower_grid.get_children():
		_tower_grid.remove_child(child)
		child.queue_free()
	_tower_btns.clear()

	for i in GameState.unlocked_towers:
		var stroke: Color = TowerDefs.STROKE[i]

		var sb_normal := StyleBoxFlat.new()
		sb_normal.bg_color                       = Color(0.07, 0.09, 0.13)
		sb_normal.corner_radius_top_left         = 6
		sb_normal.corner_radius_top_right        = 6
		sb_normal.corner_radius_bottom_left      = 6
		sb_normal.corner_radius_bottom_right     = 6
		sb_normal.border_width_left              = 3
		sb_normal.border_color                   = stroke

		var sb_pressed := sb_normal.duplicate() as StyleBoxFlat
		sb_pressed.bg_color            = Color(stroke.r * 0.18, stroke.g * 0.18, stroke.b * 0.18)
		sb_pressed.border_width_left   = 3
		sb_pressed.border_width_right  = 1
		sb_pressed.border_width_top    = 1
		sb_pressed.border_width_bottom = 1
		sb_pressed.border_color        = stroke

		var sb_hover := sb_normal.duplicate() as StyleBoxFlat
		sb_hover.bg_color = Color(0.10, 0.13, 0.19)

		var btn := Button.new()
		btn.text = "%s\n%s\n💰 %dg" % [
			TowerDefs.NAMES[i],
			_format_tower_stats_short(i),
			TowerDefs.COST[i],
		]
		btn.toggle_mode               = true
		btn.size_flags_horizontal     = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size       = Vector2(0, 68)
		btn.alignment                 = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 11)
		btn.add_theme_color_override("font_color",
			Color(stroke.r, stroke.g, stroke.b, 0.95))
		btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
		btn.add_theme_color_override("font_hover_color",
			Color(minf(stroke.r * 1.2, 1.0), minf(stroke.g * 1.2, 1.0), minf(stroke.b * 1.2, 1.0), 1.0))
		btn.add_theme_stylebox_override("normal",  sb_normal)
		btn.add_theme_stylebox_override("pressed", sb_pressed)
		btn.add_theme_stylebox_override("hover",   sb_hover)
		btn.button_down.connect(_on_tower_btn.bind(i))
		_tower_grid.add_child(btn)
		_tower_btns.append(btn)

# ============================================================
# Button handlers
# ============================================================

func _on_map_btn(idx: int) -> void:
	_selected_map = idx
	for i in _map_btns.size():
		_map_btns[i].button_pressed = (i == idx)


func _on_diff_btn(idx: int) -> void:
	_pending_difficulty = idx
	for i in _diff_btns.size():
		_diff_btns[i].button_pressed = (i == idx)


func _do_start() -> void:
	GameState.wave_countdown = GameState.WAVE_INTERVAL_FIRST
	map_selected.emit(_selected_map)
	difficulty_set.emit(_pending_difficulty)
	_rebuild_tower_buttons_from_unlocked()
	_start_screen.visible = false


func _on_start_difficulty(idx: int) -> void:
	_do_start()


func _on_tower_btn(idx: int) -> void:
	for btn in _tower_btns:
		btn.button_pressed = false
	var pos: int = GameState.unlocked_towers.find(idx)
	if pos >= 0 and pos < _tower_btns.size():
		_tower_btns[pos].button_pressed = true
	# Visa stats-preview i info_lbl
	var stroke: Color = TowerDefs.STROKE[idx]
	_info_lbl.text = "%s — 💰 %dg\n%s" % [TowerDefs.NAMES[idx], TowerDefs.COST[idx], _format_tower_stats(idx)]
	_info_lbl.add_theme_color_override("font_color", Color(stroke.r, stroke.g, stroke.b, 0.90))
	tower_selected.emit(idx)


func _on_settings_toggle() -> void:
	_settings_panel.visible = not _settings_panel.visible


func _on_mute_toggle() -> void:
	var bus := AudioServer.get_bus_index("Master")
	var muted := not AudioServer.is_bus_mute(bus)
	AudioServer.set_bus_mute(bus, muted)
	_mute_btn.text = "🔇  MUTED" if muted else "🔊  SOUND ON"


func _on_speed_toggle() -> void:
	if Engine.time_scale == 1.0:
		Engine.time_scale = 2.0
		_speed_btn.text   = "⚡  2x SPEED"
	else:
		Engine.time_scale = 1.0
		_speed_btn.text   = "⚡  1x SPEED"


func _on_drag_side_toggle() -> void:
	_drag_right = not _drag_right
	_drag_side_btn.text = "►  DRAG RIGHT" if _drag_right else "◄  DRAG LEFT"
	drag_side_changed.emit(_drag_right)


func _make_settings_row(parent: Control, icon: String,
		label: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = "%s  %s" % [icon, label]
	btn.flat = true
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	btn.custom_minimum_size = Vector2(0, 36)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn

# ============================================================
# Public helpers (called from main.gd)
# ============================================================

func deselect_tower_buttons() -> void:
	for btn in _tower_btns:
		btn.button_pressed = false


func show_status(text: String) -> void:
	_status_lbl.text = text


func update_countdown(seconds: float, next_wave: int) -> void:
	if GameState.wave_in_progress or GameState.game_over:
		return
	_countdown_lbl.text = "Wave %d  %ds" % [next_wave, int(ceil(seconds))]


func update_wave_preview(next_wave: int) -> void:
	if next_wave > WaveDefs.count():
		_wave_preview_lbl.text = ""
		return
	var wd := WaveDefs.get_wave(next_wave)
	var tags: Array[String] = []
	if wd.flies:
		tags.append("AIR")
	match wd.special:
		WaveDefs.SPECIAL_BOSS:         tags.append("BOSS")
		WaveDefs.SPECIAL_FINAL_BOSS:   tags.append("FINAL BOSS")
		WaveDefs.SPECIAL_MASS:         tags.append("SWARM")
		WaveDefs.SPECIAL_MAGIC_IMMUNE: tags.append("MAGIC IMMUNE")
		WaveDefs.SPECIAL_INVISIBLE:    tags.append("INVISIBLE")
	var tag_str: String = "  •  ".join(tags) if not tags.is_empty() else ""
	var suffix := ("  —  " + tag_str) if tag_str else ""
	_wave_preview_lbl.text = "NEXT: %s  ×%d%s" % [wd.name, wd.count, suffix]


func _section_header(text: String) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	var left_sep := HSeparator.new()
	left_sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left_sep)
	var sec_lbl := Label.new()
	sec_lbl.text = text
	sec_lbl.add_theme_font_size_override("font_size", 11)
	sec_lbl.add_theme_color_override("font_color", Color(0.45, 0.48, 0.58))
	hbox.add_child(sec_lbl)
	var right_sep := HSeparator.new()
	right_sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right_sep)
	return hbox


func _format_number(n: int) -> String:
	var s   := str(n)
	var out := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		if cnt > 0 and cnt % 3 == 0:
			out = "," + out
		out = s[i] + out
		cnt += 1
	return out


func _relic_relevant_tag(effect: String) -> String:
	match effect:
		"disc_damage":     return "disc"
		"slow_duration":   return "slow"
		"guitar_firerate": return "gitarr"
		"muay_range":      return "muay_thai"
		"snus_pierce":     return "snus"
		_:                 return ""   # wave_gold always relevant


func _has_placed_tag(tag: String) -> bool:
	if tag.is_empty():
		return true
	for t: Dictionary in GameState.towers:
		if TowerDefs.TAGS[t.type].has(tag):
			return true
	return false


func _on_relic_draft_ready(offer: Array[Dictionary]) -> void:
	for i in _relic_draft_cards.size():
		var card: Button = _relic_draft_cards[i]
		if i >= offer.size():
			card.visible = false
			continue
		var rel: Dictionary = offer[i]
		card.visible = true
		var relevant: bool = _has_placed_tag(_relic_relevant_tag(rel.get("effect", "")))
		var status_line: String = "✅ Aktiv för dina torn" if relevant else "⚠️ Inga matchande torn"
		card.text = "%s\n%s\n\n%s\n\n%s" % [rel.icon, rel.name, rel.desc, status_line]
		card.add_theme_font_size_override("font_size", 13)
		# Clear all existing connections on pressed signal
		for conn in card.pressed.get_connections():
			card.pressed.disconnect(conn["callable"])
		card.pressed.connect(_on_relic_pick.bind(rel))
		var rsb := StyleBoxFlat.new()
		rsb.bg_color                       = Color(0.12, 0.10, 0.06)
		rsb.corner_radius_top_left         = 10
		rsb.corner_radius_top_right        = 10
		rsb.corner_radius_bottom_left      = 10
		rsb.corner_radius_bottom_right     = 10
		rsb.border_width_left              = 2
		rsb.border_width_right             = 2
		rsb.border_width_top               = 2
		rsb.border_width_bottom            = 2
		rsb.border_color                   = Color(1.0, 0.75, 0.1, 0.7)
		card.add_theme_stylebox_override("normal",  rsb)
		var rsh := rsb.duplicate() as StyleBoxFlat
		rsh.border_color = Color(1.0, 0.90, 0.3)
		card.add_theme_stylebox_override("hover",   rsh)
		card.add_theme_stylebox_override("pressed", rsh)
	_relic_draft_overlay.visible = true


func _on_relic_pick(relic: Dictionary) -> void:
	GameState.acquire_relic(relic)
	GameState.draft_pending = false
	_relic_draft_overlay.visible = false


func _on_relic_acquired(_relic: Dictionary) -> void:
	_rebuild_relic_strip()


func _on_synergy_activated(_syn_id: String, syn_name: String, syn_icon: String) -> void:
	_toast_lbl.text = "%s  SYNERGI: %s" % [syn_icon, syn_name]
	_toast_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	var tw := get_tree().create_tween()
	tw.tween_interval(2.0)
	tw.tween_method(
		func(a: float) -> void:
			_toast_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, a)),
		1.0, 0.0, 0.6
	)
	_rebuild_synergy_strip()


func _rebuild_synergy_strip() -> void:
	if GameState.active_synergies.is_empty():
		_synergy_strip_lbl.text = ""
		return
	var parts: Array[String] = []
	for sid: String in GameState.active_synergies:
		for syn: Dictionary in SynergyDefs.SYNERGIES:
			if syn.id == sid:
				parts.append("%s %s" % [syn.icon, syn.name])
	_synergy_strip_lbl.text = "\n".join(parts)


func _rebuild_relic_strip() -> void:
	for child in _relic_strip_hbox.get_children():
		child.queue_free()
	for relic: Dictionary in GameState.active_relics:
		var lbl := Label.new()
		lbl.text = relic.icon
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.tooltip_text = relic.name + "\n" + relic.desc
		_relic_strip_hbox.add_child(lbl)
