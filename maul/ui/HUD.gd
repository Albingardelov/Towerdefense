class_name HUD
extends Node

# ============================================================
# Signals
# ============================================================

signal tower_selected(idx: int)
signal start_wave_pressed()
signal difficulty_set(idx: int)
signal clear_all_pressed()
signal sell_tower_pressed()
signal drag_side_changed(right: bool)

# ============================================================
# Node references
# ============================================================

var _tower_btns:     Array[Button] = []
var _send_early_btn: Button
var _countdown_lbl:  Label
var _status_lbl:     Label
var _escaped_lbl:    Label
var _gold_lbl:       Label
var _wave_lbl:       Label
var _info_lbl:       Label
var _start_screen:   Control
var _tower_drawer:   Control
var _tower_toggle:   Button
var _sell_popup:     Control
var _sp_name_lbl:    Label
var _sp_stats_lbl:   Label
var _sp_price_lbl:   Label
var _drag_side_btn:  Button
var _drag_right:     bool = false

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

# ============================================================
# Build
# ============================================================

func _build_ui() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)

	# ── Top bar ───────────────────────────────────────────────
	var top_bar := PanelContainer.new()
	top_bar.set_anchor(SIDE_LEFT,   0.0)
	top_bar.set_anchor(SIDE_RIGHT,  1.0)
	top_bar.set_anchor(SIDE_TOP,    0.0)
	top_bar.set_anchor(SIDE_BOTTOM, 0.0)
	top_bar.set_offset(SIDE_BOTTOM, 52)
	cl.add_child(top_bar)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 6)
	top_bar.add_child(top_hbox)

	_wave_lbl    = _make_lbl("Wave: —",               true)
	_gold_lbl    = _make_lbl("Gold: %d" % GameState.gold, true)
	_escaped_lbl = _make_lbl("Esc: 0/%d" % GameState.max_escape, true)
	_countdown_lbl = _make_lbl("", false)
	_countdown_lbl.add_theme_font_size_override("font_size", 10)

	top_hbox.add_child(_wave_lbl)
	top_hbox.add_child(_gold_lbl)
	top_hbox.add_child(_escaped_lbl)
	top_hbox.add_child(_countdown_lbl)

	_send_early_btn = Button.new()
	_send_early_btn.text = "Send"
	_send_early_btn.pressed.connect(func() -> void: start_wave_pressed.emit())
	top_hbox.add_child(_send_early_btn)

	_drag_side_btn = Button.new()
	_drag_side_btn.text = "◄"
	_drag_side_btn.pressed.connect(_on_drag_side_toggle)
	top_hbox.add_child(_drag_side_btn)

	# ── Tower drawer (bottom, hidden by default) ──────────────
	_tower_drawer = PanelContainer.new()
	_tower_drawer.set_anchor(SIDE_LEFT,   0.0)
	_tower_drawer.set_anchor(SIDE_RIGHT,  1.0)
	_tower_drawer.set_anchor(SIDE_TOP,    1.0)
	_tower_drawer.set_anchor(SIDE_BOTTOM, 1.0)
	_tower_drawer.set_offset(SIDE_TOP,    -240)
	_tower_drawer.set_offset(SIDE_BOTTOM, -44)   # sits above the toggle button
	_tower_drawer.visible = false
	cl.add_child(_tower_drawer)

	var dvbox := VBoxContainer.new()
	dvbox.add_theme_constant_override("separation", 6)
	_tower_drawer.add_child(dvbox)

	# 2-column grid for tower buttons
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	dvbox.add_child(grid)

	for i in TowerDefs.count():
		var btn := Button.new()
		btn.text = "%s\n%dg" % [TowerDefs.NAMES[i], TowerDefs.COST[i]]
		btn.toggle_mode = true
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size   = Vector2(0, 52)
		btn.button_down.connect(_on_tower_btn.bind(i))
		grid.add_child(btn)
		_tower_btns.append(btn)

	_info_lbl = Label.new()
	_info_lbl.text = "Tryck pa ett placerat torn"
	_info_lbl.add_theme_font_size_override("font_size", 10)
	_info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dvbox.add_child(_info_lbl)

	var clear_btn := Button.new()
	clear_btn.text = "Rensa alla torn"
	clear_btn.pressed.connect(func() -> void: clear_all_pressed.emit())
	dvbox.add_child(clear_btn)

	# ── Toggle button (full-width strip at very bottom) ───────
	_tower_toggle = Button.new()
	_tower_toggle.text = "Torn  v"
	_tower_toggle.set_anchor(SIDE_LEFT,   0.0)
	_tower_toggle.set_anchor(SIDE_RIGHT,  1.0)
	_tower_toggle.set_anchor(SIDE_TOP,    1.0)
	_tower_toggle.set_anchor(SIDE_BOTTOM, 1.0)
	_tower_toggle.set_offset(SIDE_TOP,    -44)
	_tower_toggle.set_offset(SIDE_BOTTOM, 0)
	_tower_toggle.pressed.connect(_toggle_drawer)
	cl.add_child(_tower_toggle)

	# ── Status overlay (just below top bar) ───────────────────
	_status_lbl = Label.new()
	_status_lbl.position = Vector2(4, 56)
	_status_lbl.text     = ""
	_status_lbl.add_theme_font_size_override("font_size", 11)
	_status_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	cl.add_child(_status_lbl)

	# ── Sell popup ────────────────────────────────────────────
	_sell_popup = ColorRect.new()
	(_sell_popup as ColorRect).color = Color(0.0, 0.0, 0.0, 0.75)
	_sell_popup.set_anchor(SIDE_LEFT,   0.0)
	_sell_popup.set_anchor(SIDE_RIGHT,  1.0)
	_sell_popup.set_anchor(SIDE_TOP,    0.0)
	_sell_popup.set_anchor(SIDE_BOTTOM, 1.0)
	_sell_popup.visible = false
	cl.add_child(_sell_popup)

	var sp_center := CenterContainer.new()
	sp_center.set_anchor(SIDE_LEFT,   0.0)
	sp_center.set_anchor(SIDE_RIGHT,  1.0)
	sp_center.set_anchor(SIDE_TOP,    0.0)
	sp_center.set_anchor(SIDE_BOTTOM, 1.0)
	_sell_popup.add_child(sp_center)

	var sp_panel := PanelContainer.new()
	sp_panel.custom_minimum_size = Vector2(280, 0)
	sp_center.add_child(sp_panel)

	var sp_vbox := VBoxContainer.new()
	sp_vbox.add_theme_constant_override("separation", 16)
	sp_panel.add_child(sp_vbox)

	_sp_name_lbl = Label.new()
	_sp_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sp_name_lbl.add_theme_font_size_override("font_size", 18)
	sp_vbox.add_child(_sp_name_lbl)

	_sp_stats_lbl = Label.new()
	_sp_stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sp_stats_lbl.add_theme_font_size_override("font_size", 11)
	_sp_stats_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	sp_vbox.add_child(_sp_stats_lbl)

	_sp_price_lbl = Label.new()
	_sp_price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sp_vbox.add_child(_sp_price_lbl)

	var sp_row := HBoxContainer.new()
	sp_row.alignment = BoxContainer.ALIGNMENT_CENTER
	sp_row.add_theme_constant_override("separation", 16)
	sp_vbox.add_child(sp_row)

	var sell_btn := Button.new()
	sell_btn.text = "Salj"
	sell_btn.custom_minimum_size = Vector2(100, 52)
	sell_btn.add_theme_font_size_override("font_size", 18)
	sell_btn.pressed.connect(func() -> void:
		_sell_popup.visible = false
		sell_tower_pressed.emit())
	sp_row.add_child(sell_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Avbryt"
	cancel_btn.custom_minimum_size = Vector2(100, 52)
	cancel_btn.pressed.connect(func() -> void: _sell_popup.visible = false)
	sp_row.add_child(cancel_btn)

	# ── Start screen (added last = renders on top) ────────────
	_start_screen = ColorRect.new()
	_start_screen.color = Color(0.05, 0.07, 0.10, 0.96)
	_start_screen.set_anchor(SIDE_LEFT,   0.0)
	_start_screen.set_anchor(SIDE_RIGHT,  1.0)
	_start_screen.set_anchor(SIDE_TOP,    0.0)
	_start_screen.set_anchor(SIDE_BOTTOM, 1.0)
	cl.add_child(_start_screen)

	var center := CenterContainer.new()
	center.set_anchor(SIDE_LEFT,   0.0)
	center.set_anchor(SIDE_RIGHT,  1.0)
	center.set_anchor(SIDE_TOP,    0.0)
	center.set_anchor(SIDE_BOTTOM, 1.0)
	_start_screen.add_child(center)

	var svbox := VBoxContainer.new()
	svbox.add_theme_constant_override("separation", 28)
	center.add_child(svbox)

	var title_lbl := Label.new()
	title_lbl.text = "MAZE  TD"
	title_lbl.add_theme_font_size_override("font_size", 56)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	svbox.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "Valj svarighetsgrad"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	svbox.add_child(sub_lbl)

	var diff_row := HBoxContainer.new()
	diff_row.alignment = BoxContainer.ALIGNMENT_CENTER
	diff_row.add_theme_constant_override("separation", 20)
	svbox.add_child(diff_row)

	var diff_labels: Array[String] = ["Easy", "Medium", "Hard"]
	for i in 3:
		var dbtn := Button.new()
		dbtn.text = diff_labels[i]
		dbtn.custom_minimum_size = Vector2(110, 72)
		dbtn.add_theme_font_size_override("font_size", 22)
		dbtn.pressed.connect(_on_start_difficulty.bind(i))
		diff_row.add_child(dbtn)

# ============================================================
# Private helpers
# ============================================================

func _make_lbl(txt: String, expand: bool) -> Label:
	var lbl: Label = Label.new()
	lbl.text = txt
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return lbl


func _toggle_drawer() -> void:
	_tower_drawer.visible = not _tower_drawer.visible
	_tower_toggle.text    = "Torn  ^" if _tower_drawer.visible else "Torn  v"

# ============================================================
# GameState signal handlers
# ============================================================

func _on_gold_changed(amount: int) -> void:
	_gold_lbl.text = "Gold: %d" % amount



func _on_escaped_changed(current: int, max_val: int) -> void:
	_escaped_lbl.text = "Esc: %d/%d" % [current, max_val]


func _on_wave_started(wave_num: int, _banner: String) -> void:
	_wave_lbl.text           = "Wave: %d" % wave_num
	_countdown_lbl.text      = ""
	_send_early_btn.text     = "..."
	_send_early_btn.disabled = true


func _on_wave_completed(_wave_num: int, _bonus: int) -> void:
	_send_early_btn.text     = "Send"
	_send_early_btn.disabled = false


func _on_game_over() -> void:
	_countdown_lbl.text      = "GAME OVER"
	_send_early_btn.text     = "Restart"
	_send_early_btn.disabled = false


func _on_game_restarted() -> void:
	_wave_lbl.text           = "Wave: —"
	_gold_lbl.text           = "Gold: %d" % GameState.gold
	_escaped_lbl.text        = "Esc: 0/%d" % GameState.max_escape
	_countdown_lbl.text      = ""
	_send_early_btn.text     = "Send"
	_send_early_btn.disabled = false
	_info_lbl.text           = "Tryck pa ett placerat torn"
	for btn in _tower_btns:
		btn.button_pressed = false
	if _tower_drawer.visible:
		_toggle_drawer()
	_start_screen.visible = true


func _on_tower_inspected(tower: Dictionary) -> void:
	if tower.is_empty():
		_sell_popup.visible = false
		return
	var type: int = tower.type
	var aoe_str := " | AOE %.1ft" % TowerDefs.SPLASH[type] if TowerDefs.AOE[type] else ""
	var sell_price: int = int(TowerDefs.COST[type] * 0.75)
	_sp_name_lbl.text  = TowerDefs.NAMES[type]
	_sp_stats_lbl.text = "%.0f skada  |  %.1f räckvidd  |  %.2f/s%s" % [
		TowerDefs.DAMAGE[type], TowerDefs.RANGE[type], TowerDefs.FIRERATE[type], aoe_str]
	_sp_price_lbl.text = "Refund: %dg" % sell_price
	_sell_popup.visible = true

# ============================================================
# Button handlers
# ============================================================

func _on_start_difficulty(idx: int) -> void:
	GameState.wave_countdown = GameState.WAVE_INTERVAL_FIRST
	difficulty_set.emit(idx)
	_start_screen.visible = false


func _on_tower_btn(idx: int) -> void:
	for i in _tower_btns.size():
		_tower_btns[i].button_pressed = (i == idx)
	tower_selected.emit(idx)


func _on_drag_side_toggle() -> void:
	_drag_right = not _drag_right
	_drag_side_btn.text = "►" if _drag_right else "◄"
	drag_side_changed.emit(_drag_right)

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
