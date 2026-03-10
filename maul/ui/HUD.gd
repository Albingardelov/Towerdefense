class_name HUD
extends Node

# ============================================================
# Signals (bubbled up to main.gd)
# ============================================================

signal tower_selected(idx: int)
signal start_wave_pressed()
signal difficulty_set(idx: int)
signal clear_all_pressed()

# ============================================================
# UI node references
# ============================================================

var _tower_btns:     Array[Button] = []
var _diff_btns:      Array[Button] = []
var _send_early_btn: Button
var _countdown_lbl:  Label
var _status_lbl:     Label
var _escaped_lbl:    Label
var _gold_lbl:       Label
var _wave_lbl:       Label
var _info_lbl:       Label

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

	# ── Right panel ──────────────────────────────────────────
	var panel := PanelContainer.new()
	panel.set_anchor(SIDE_LEFT,   0.0)
	panel.set_anchor(SIDE_RIGHT,  1.0)
	panel.set_anchor(SIDE_TOP,    0.0)
	panel.set_anchor(SIDE_BOTTOM, 1.0)
	panel.set_offset(SIDE_LEFT,   Pathfinder.COLS * 30)  # COLS * CELL
	panel.set_offset(SIDE_RIGHT,  0.0)
	panel.set_offset(SIDE_TOP,    0.0)
	panel.set_offset(SIDE_BOTTOM, 0.0)
	cl.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Status labels
	_wave_lbl    = Label.new(); _wave_lbl.text    = "Wave: —"
	_gold_lbl    = Label.new(); _gold_lbl.text    = "Gold: %d" % GameState.gold
	_escaped_lbl = Label.new(); _escaped_lbl.text = "Esc: 0/%d" % GameState.max_escape
	vbox.add_child(_wave_lbl)
	vbox.add_child(_gold_lbl)
	vbox.add_child(_escaped_lbl)
	vbox.add_child(HSeparator.new())

	# Tower buttons
	for i in TowerDefs.count():
		var btn := Button.new()
		btn.text = "%s\n%dg" % [TowerDefs.NAMES[i], TowerDefs.COST[i]]
		btn.toggle_mode = true
		btn.button_pressed = false
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size   = Vector2(0, 44)
		btn.pressed.connect(_on_tower_btn.bind(i))
		vbox.add_child(btn)
		_tower_btns.append(btn)

	vbox.add_child(HSeparator.new())

	# Countdown label
	_countdown_lbl = Label.new()
	_countdown_lbl.text = "Wave 1 in 60s"
	_countdown_lbl.add_theme_font_size_override("font_size", 11)
	_countdown_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_countdown_lbl)

	# Send early button
	_send_early_btn = Button.new()
	_send_early_btn.text = "Send Early"
	_send_early_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_send_early_btn.pressed.connect(func() -> void: start_wave_pressed.emit())
	vbox.add_child(_send_early_btn)

	# Difficulty buttons
	var diff_row := HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 2)
	vbox.add_child(diff_row)
	var diff_names := ["Easy", "Med", "Hard"]
	for i in 3:
		var dbtn := Button.new()
		dbtn.text = diff_names[i]
		dbtn.toggle_mode = true
		dbtn.button_pressed = (i == GameState.difficulty)
		dbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dbtn.pressed.connect(_on_diff_btn.bind(i))
		diff_row.add_child(dbtn)
		_diff_btns.append(dbtn)

	vbox.add_child(HSeparator.new())

	# Inspect info label
	_info_lbl = Label.new()
	_info_lbl.text = "Tap a placed tower to inspect"
	_info_lbl.add_theme_font_size_override("font_size", 10)
	_info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_info_lbl)

	# Clear all button
	var clear_btn := Button.new()
	clear_btn.text = "Rensa alla torn"
	clear_btn.pressed.connect(func() -> void: clear_all_pressed.emit())
	vbox.add_child(clear_btn)

	# Overlay status label (top-left of game area)
	_status_lbl = Label.new()
	_status_lbl.position = Vector2(4, 4)
	_status_lbl.text     = ""
	_status_lbl.add_theme_font_size_override("font_size", 11)
	_status_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	cl.add_child(_status_lbl)

# ============================================================
# GameState signal handlers
# ============================================================

func _on_gold_changed(amount: int) -> void:
	_gold_lbl.text = "Gold: %d" % amount


func _on_escaped_changed(current: int, max_val: int) -> void:
	_escaped_lbl.text = "Esc: %d/%d" % [current, max_val]


func _on_wave_started(wave_num: int, _banner: String) -> void:
	_wave_lbl.text          = "Wave: %d" % wave_num
	_countdown_lbl.text     = "Wave %d in progress" % wave_num
	_send_early_btn.text    = "Sending..."
	_send_early_btn.disabled = true
	for btn in _diff_btns:
		btn.disabled = true


func _on_wave_completed(wave_num: int, _bonus: int) -> void:
	_send_early_btn.text     = "Send Wave %d Early" % (wave_num + 1)
	_send_early_btn.disabled = false


func _on_game_over() -> void:
	_countdown_lbl.text      = "GAME OVER"
	_send_early_btn.text     = "Restart"
	_send_early_btn.disabled = false


func _on_game_restarted() -> void:
	_wave_lbl.text    = "Wave: —"
	_gold_lbl.text    = "Gold: %d" % GameState.gold
	_escaped_lbl.text = "Esc: 0/%d" % GameState.max_escape
	_countdown_lbl.text      = "Wave 1 in 60s"
	_send_early_btn.text     = "Send Early"
	_send_early_btn.disabled = false
	for i in _diff_btns.size():
		_diff_btns[i].disabled       = false
		_diff_btns[i].button_pressed = (i == GameState.difficulty)
	_info_lbl.text = "Tap a placed tower to inspect"
	for btn in _tower_btns:
		btn.button_pressed = false


func _on_tower_inspected(tower: Dictionary) -> void:
	if tower.is_empty():
		_info_lbl.text = "Tap a placed tower to inspect"
		return
	var type: int = tower.type
	var aoe_str := " AOE%.1ft" % TowerDefs.SPLASH[type] if TowerDefs.AOE[type] else ""
	var sell_price: int = int(TowerDefs.COST[type] * 0.75)
	_info_lbl.text = "%s | %.0fdmg | %.1fr | %.2f/s | %dg%s\nSell: %dg (right-click)" % [
		TowerDefs.NAMES[type], TowerDefs.DAMAGE[type], TowerDefs.RANGE[type],
		TowerDefs.FIRERATE[type], TowerDefs.COST[type], aoe_str, sell_price,
	]

# ============================================================
# Button handlers
# ============================================================

func _on_tower_btn(idx: int) -> void:
	for i in _tower_btns.size():
		_tower_btns[i].button_pressed = (i == idx)
	tower_selected.emit(idx)


func _on_diff_btn(idx: int) -> void:
	for i in _diff_btns.size():
		_diff_btns[i].button_pressed = (i == idx)
	difficulty_set.emit(idx)

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
	_countdown_lbl.text = "Wave %d in %ds" % [next_wave, int(ceil(seconds))]
