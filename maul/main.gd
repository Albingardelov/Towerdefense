extends Node2D

# ============================================================
# Constants
# ============================================================

const COLS  := 16
const ROWS  := 22
const CELL  := 30
const SCOLS := COLS * 2
const SROWS := ROWS * 2

const ENTRY := Vector2i(8, 0)
const EXIT  := Vector2i(8, 21)

const VIEWPORT_W := 640
const VIEWPORT_H := 660
const UI_W       := 160

const TOWER_NAMES    = ["Cornerstone", "Lightning Rod", "Storm Guard", "Mjolnir", "Tempest"]
const TOWER_SIZES    = [Vector2i(1,1), Vector2i(1,1), Vector2i(1,1), Vector2i(2,2), Vector2i(1,1)]
const TOWER_RANGE    = [2.5, 4.5, 3.5, 6.0, 3.5]    # grid units
const TOWER_DAMAGE   = [30.0, 73.0, 190.0,  10.0, 65.0]
const TOWER_FIRERATE = [1.05, 0.85, 0.80,  20.0,  0.55]  # attacks/second
const TOWER_COST     = [100, 250,  600,  2000,  450]    # gold cost
const TOWER_AOE      = [true,  false, false, false, true]   # AOE splash on hit
const TOWER_SPLASH   = [0.4,   0.0,   0.0,   0.0,  1.5]   # splash radius in grid units
const TOWER_AIR_MULT = [2.0,   2.0,   2.0,   1.0,  1.0]   # damage multiplier vs flying

const TOWER_FILL = [
	Color(0.280, 0.360, 0.420),   # Cornerstone   gray
	Color(0.080, 0.220, 0.500),   # Lightning Rod  blue
	Color(0.040, 0.120, 0.300),   # Storm Guard    dark blue
	Color(0.500, 0.350, 0.040),   # Mjolnir        gold
	Color(0.220, 0.060, 0.380),   # Tempest        purple
]
const TOWER_STROKE = [
	Color(0.750, 0.850, 0.920),   # Cornerstone   bright silver
	Color(0.180, 0.600, 1.000),   # Lightning Rod  vivid blue
	Color(0.450, 0.700, 1.000),   # Storm Guard    bright blue
	Color(1.000, 0.820, 0.120),   # Mjolnir        bright gold
	Color(0.850, 0.420, 1.000),   # Tempest        vivid purple
]

const PROJ_SPEED := 180.0

# Per-wave lookup tables (index 0 = wave 1, capped at index 19 for wave 20+)
const WAVE_NORMAL_COUNT = [12,  14,  15,   16,   18,   18,   20,   20,   22,   22,   24,   24,   26,   26,   28,   28,    30,    30,    32,    32]
const WAVE_FLYING_COUNT = [ 0,   0,   0,    0,   12,   12,   14,   14,   16,   16,   18,   18,   20,   20,   22,   22,    24,    24,    26,    26]
const WAVE_BOSS_COUNT   = [ 0,   0,   0,    0,    0,    0,    0,    0,    0,    2,    0,    0,    0,    0,    0,    0,     0,     0,     0,     2]
const WAVE_NORMAL_HP    = [72,  86, 104,  125,  150,  180,  216,  260,  312,  375,  450,  540,  650,  780,  940, 1125,  1350,  1620,  1940,  2330]
const WAVE_FLYING_HP    = [ 0,   0,   0,    0,   60,   72,   86,  104,  125,  150,  180,  216,  260,  312,  375,  450,   540,   648,   780,   940]
const WAVE_BOSS_HP      = [  0,   0,   0,    0,    0,    0,    0,    0,    0, 1875,    0,    0,    0,    0,    0,    0,     0,     0,     0, 11650]
const WAVE_SPEED        = [28,  29,  30,   31,   32,   33,   34,   35,   36,   37,   38,   39,   40,   41,   42,   43,    44,    45,    46,    47]
const WAVE_CREEP_GOLD   = [10,  12,  14,   16,   18,   20,   22,   24,   26,   30,   32,   34,   36,   38,   40,   42,    44,    46,    48,    50]
const WAVE_BONUS        = [30,  40,  50,   60,   80,   90,  100,  110,  120,  150,  160,  170,  180,  190,  200,  210,   220,   230,   240,   250]

const COL_BG      := Color(0.051, 0.067, 0.090)
const COL_GRID    := Color(0.110, 0.129, 0.157)
const COL_SUBGRID := Color(1.0, 1.0, 1.0, 0.04)
const COL_ENTRY   := Color(0.29, 1.0, 0.29)
const COL_EXIT    := Color(1.0, 0.29, 0.29)
const COL_INVALID := Color(1.0, 0.29, 0.29)
const COL_PATH    := Color(1.0, 0.8, 0.0, 0.20)
const COL_ENEMY   := Color(0.85, 0.20, 0.20)
const COL_HP_BG   := Color(0.20, 0.05, 0.05)
const COL_HP_FG   := Color(0.20, 0.85, 0.20)

# ============================================================
# State
# ============================================================

var towers:       Array = []
var enemies:      Array = []
var projectiles:  Array = []
var explosions:   Array = []
var current_path: Array = []
var wave_spawn_queue:  Array  = []
var floats:            Array  = []   # floating text {pos, text, color, timer, max_timer}
var particles:         Array  = []   # death burst {pos, vel, color, timer, max_timer}
var wave_banner_timer: float  = 0.0
var wave_banner_text:  String = ""

var wave:             int   = 0
var wave_in_progress: bool  = false
var spawn_timer:      float = 0.0
const SPAWN_INTERVAL         = 0.60

var escaped:    int  = 0
var max_escape: int  = 50
var difficulty: int  = 1   # 0=Easy, 1=Medium, 2=Hard
var gold:       int  = 500
var game_started: bool = false
var game_over:    bool = false

var inspected: Dictionary = {}

var hover_pos   := Vector2(-1.0, -1.0)
var hover_valid := false
var selected    := 0
var placing     := false


var _tower_btns  : Array[Button] = []
var _diff_btns   : Array[Button] = []
var _start_btn   : Button
var _status_lbl  : Label
var _wave_lbl    : Label
var _escaped_lbl : Label
var _gold_lbl    : Label
var _info_lbl    : Label
var _font        : Font

# ============================================================
# Ready
# ============================================================

func _ready() -> void:
	get_window().size = Vector2i(VIEWPORT_W, VIEWPORT_H)
	get_window().min_size = Vector2i(VIEWPORT_W, VIEWPORT_H)
	# Make mouse behave exactly like a finger (for desktop testing of mobile feel)
	ProjectSettings.set_setting("input_devices/pointing/emulate_touch_from_mouse", true)
	_font = ThemeDB.fallback_font
	_build_ui()
	_rebuild_path()
	_update_ui()

# ============================================================
# UI
# ============================================================

func _build_ui() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)

	# ── Right panel ───────────────────────────────────────────────
	var panel := PanelContainer.new()
	panel.set_anchor(SIDE_LEFT,   0.0)
	panel.set_anchor(SIDE_RIGHT,  1.0)
	panel.set_anchor(SIDE_TOP,    0.0)
	panel.set_anchor(SIDE_BOTTOM, 1.0)
	panel.set_offset(SIDE_LEFT,   COLS * CELL)
	panel.set_offset(SIDE_RIGHT,  0.0)
	panel.set_offset(SIDE_TOP,    0.0)
	panel.set_offset(SIDE_BOTTOM, 0.0)
	cl.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Info labels
	_wave_lbl = Label.new();    _wave_lbl.text = "Wave: —"
	vbox.add_child(_wave_lbl)
	_gold_lbl = Label.new();    _gold_lbl.text = "Gold: 700"
	vbox.add_child(_gold_lbl)
	_escaped_lbl = Label.new(); _escaped_lbl.text = "Esc: 0/50"
	vbox.add_child(_escaped_lbl)

	vbox.add_child(HSeparator.new())

	# Tower buttons (vertical)
	for i in TOWER_NAMES.size():
		var btn := Button.new()
		btn.text = "%s\n%dg" % [TOWER_NAMES[i], TOWER_COST[i]]
		btn.toggle_mode = true
		btn.button_pressed = false
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size   = Vector2(0, 44)
		btn.pressed.connect(_select_tower.bind(i))
		vbox.add_child(btn)
		_tower_btns.append(btn)

	vbox.add_child(HSeparator.new())

	# Start button
	_start_btn = Button.new()
	_start_btn.text = "Start Wave 1"
	_start_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_start_btn.pressed.connect(_on_start_wave)
	vbox.add_child(_start_btn)

	# Difficulty buttons
	var diff_row := HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 2)
	vbox.add_child(diff_row)
	var diff_names := ["Easy", "Med", "Hard"]
	for i in 3:
		var dbtn := Button.new()
		dbtn.text = diff_names[i]
		dbtn.toggle_mode = true
		dbtn.button_pressed = (i == difficulty)
		dbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dbtn.pressed.connect(_set_difficulty.bind(i))
		diff_row.add_child(dbtn)
		_diff_btns.append(dbtn)

	vbox.add_child(HSeparator.new())

	# Inspect label
	_info_lbl = Label.new()
	_info_lbl.text = "Klicka ett torn"
	_info_lbl.add_theme_font_size_override("font_size", 10)
	_info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_info_lbl)

	# Clear button
	var clear := Button.new()
	clear.text = "Rensa alla torn"
	clear.pressed.connect(func() -> void:
		if wave_in_progress: return
		towers.clear()
		inspected = {}
		_rebuild_path()
		_update_inspect_ui()
		queue_redraw())
	vbox.add_child(clear)

	# Overlay status label (top-left of game area)
	_status_lbl = Label.new()
	_status_lbl.position = Vector2(4, 4)
	_status_lbl.text     = ""
	_status_lbl.add_theme_font_size_override("font_size", 11)
	_status_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	cl.add_child(_status_lbl)


func _add_section_label(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(0.91, 0.78, 0.31))
	lbl.add_theme_font_size_override("font_size", 11)
	parent.add_child(lbl)


func _select_tower(idx: int) -> void:
	selected = idx
	placing  = true
	for i in _tower_btns.size():
		_tower_btns[i].button_pressed = (i == idx)


func _exit_placement() -> void:
	placing   = false
	hover_pos = Vector2(-1.0, -1.0)
	for btn in _tower_btns:
		btn.button_pressed = false
	queue_redraw()


func _set_difficulty(idx: int) -> void:
	if game_started:
		return
	difficulty = idx
	max_escape = [100, 50, 0][idx]
	for i in _diff_btns.size():
		_diff_btns[i].button_pressed = (i == idx)
	_update_ui()


func _update_ui() -> void:
	_wave_lbl.text    = "Wave: %d" % wave if wave > 0 else "Wave: —"
	_escaped_lbl.text = "Esc: %d/%d" % [escaped, max_escape]
	_gold_lbl.text    = "Gold: %d" % gold
	if game_over:
		_start_btn.text     = "GAME OVER — Starta om"
		_start_btn.disabled = false
	elif wave_in_progress:
		_start_btn.text     = "Wave %d running..." % wave
		_start_btn.disabled = true
	else:
		_start_btn.text     = "Start Wave %d" % (wave + 1)
		_start_btn.disabled = false
	for btn in _diff_btns:
		btn.disabled = game_started


func _update_inspect_ui() -> void:
	if inspected.is_empty():
		_info_lbl.text = "Tap a placed tower to inspect"
		return
	var type: int = inspected.type
	var aoe_str := " AOE%.1ft" % TOWER_SPLASH[type] if TOWER_AOE[type] else ""
	_info_lbl.text = "%s | %.0fdmg | %.1fr | %.2f/s | %dg%s" % [
		TOWER_NAMES[type], TOWER_DAMAGE[type], TOWER_RANGE[type],
		TOWER_FIRERATE[type], TOWER_COST[type], aoe_str,
	]


func _get_tower_at(gx: float, gy: float) -> Dictionary:
	for t in towers:
		if gx >= t.pos.x and gx < t.pos.x + t.sz.x \
		and gy >= t.pos.y and gy < t.pos.y + t.sz.y:
			return t
	return {}


# ============================================================
# Snap
# ============================================================

func _snap(pixel: Vector2) -> Vector2:
	var sz: Vector2i = TOWER_SIZES[selected]
	var cell := float(CELL)
	var gx: float = round((pixel.x / cell) * 2.0) / 2.0
	var gy: float = round((pixel.y / cell) * 2.0) / 2.0
	gx = clamp(gx, 0.0, float(COLS - sz.x))
	gy = clamp(gy, 0.0, float(ROWS - sz.y))
	return Vector2(gx, gy)

# ============================================================
# Collision
# ============================================================

func _overlap(ax: float, ay: float, aw: float, ah: float,
			  bx: float, by: float, bw: float, bh: float) -> bool:
	return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by


func _can_place(pos: Vector2, sz: Vector2i) -> bool:
	if pos.x < 0 or pos.y < 0 or pos.x + sz.x > COLS or pos.y + sz.y > ROWS:
		return false
	if _overlap(pos.x, pos.y, sz.x, sz.y, ENTRY.x, ENTRY.y, 1, 1):
		return false
	if _overlap(pos.x, pos.y, sz.x, sz.y, EXIT.x, EXIT.y, 1, 1):
		return false
	for t in towers:
		if _overlap(pos.x, pos.y, sz.x, sz.y, t.pos.x, t.pos.y, t.sz.x, t.sz.y):
			return false
	if _bfs(_build_blocked(pos, sz)).is_empty():
		return false
	return true


func _remove_at(pixel: Vector2) -> void:
	var gx: float = pixel.x / CELL
	var gy: float = pixel.y / CELL
	var hit := _get_tower_at(gx, gy)
	if not hit.is_empty() and is_same(hit, inspected):
		inspected = {}
		_update_inspect_ui()
	towers = towers.filter(func(t: Dictionary) -> bool:
		return not (gx >= t.pos.x and gx < t.pos.x + t.sz.x
				and gy >= t.pos.y and gy < t.pos.y + t.sz.y))
	_rebuild_path()
	queue_redraw()

# ============================================================
# Pathfinding
# ============================================================

func _build_blocked(extra_pos: Vector2 = Vector2(-1, -1), extra_sz: Vector2i = Vector2i(0, 0)) -> PackedByteArray:
	var blocked := PackedByteArray()
	blocked.resize(SCOLS * SROWS)
	blocked.fill(0)
	for t in towers:
		_block_rect(blocked, t.pos, t.sz)
	if extra_sz.x > 0:
		_block_rect(blocked, extra_pos, extra_sz)
	return blocked


func _block_rect(blocked: PackedByteArray, pos: Vector2, sz: Vector2i) -> void:
	var sx0 := int(pos.x * 2)
	var sy0 := int(pos.y * 2)
	var sx1 := int((pos.x + sz.x) * 2)
	var sy1 := int((pos.y + sz.y) * 2)
	for sy in range(sy0, sy1):
		for sx in range(sx0, sx1):
			if sx >= 0 and sx < SCOLS and sy >= 0 and sy < SROWS:
				blocked[sy * SCOLS + sx] = 1


func _bfs(blocked: PackedByteArray) -> Array:
	var queue: Array[Vector2i] = []
	var came_from := {}

	for dy in range(2):
		for dx in range(2):
			var s := Vector2i(ENTRY.x * 2 + dx, ENTRY.y * 2 + dy)
			if blocked[s.y * SCOLS + s.x] == 0 and not came_from.has(s):
				came_from[s] = Vector2i(-1, -1)
				queue.append(s)

	if queue.is_empty():
		return []

	var dirs := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	var goal  := Vector2i(-1, -1)
	var ex0   := EXIT.x * 2
	var ey0   := EXIT.y * 2
	var head  := 0

	while head < queue.size():
		var cur: Vector2i = queue[head]
		head += 1
		if cur.x >= ex0 and cur.x <= ex0 + 1 and cur.y >= ey0 and cur.y <= ey0 + 1:
			goal = cur
			break
		for d in dirs:
			var nxt: Vector2i = cur + d
			if nxt.x < 0 or nxt.y < 0 or nxt.x >= SCOLS or nxt.y >= SROWS:
				continue
			if blocked[nxt.y * SCOLS + nxt.x] == 1:
				continue
			if came_from.has(nxt):
				continue
			came_from[nxt] = cur
			queue.append(nxt)

	if goal == Vector2i(-1, -1):
		return []

	var path: Array[Vector2i] = []
	var c := goal
	while c != Vector2i(-1, -1):
		path.push_front(c)
		c = came_from.get(c, Vector2i(-1, -1))
	return path


func _rebuild_path() -> void:
	current_path = _bfs(_build_blocked())
	if current_path.is_empty():
		return
	var new_waypoints := _path_to_pixels(current_path)
	for e: Dictionary in enemies:
		if e.dead or e.get("flying", false):
			continue
		var best_idx := 0
		var best_dist := INF
		for i in new_waypoints.size():
			var d: float = e.pos.distance_to(new_waypoints[i])
			if d < best_dist:
				best_dist = d
				best_idx  = i
		e.waypoints = new_waypoints
		e.wp_idx = mini(best_idx + 1, new_waypoints.size() - 1)
		if e.wp_idx < new_waypoints.size():
			e.dir = (new_waypoints[e.wp_idx] - e.pos).normalized()


func _path_to_pixels(path: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	var half   := float(CELL) * 0.5
	for p: Vector2i in path:
		result.append(Vector2((p.x + 0.5) * half, (p.y + 0.5) * half))
	return result

# ============================================================
# Wave & Spawning
# ============================================================

func _restart() -> void:
	towers.clear()
	enemies.clear()
	projectiles.clear()
	explosions.clear()
	wave             = 0
	wave_in_progress = false
	spawn_timer      = 0.0
	wave_spawn_queue.clear()
	floats.clear()
	particles.clear()
	wave_banner_timer = 0.0
	wave_banner_text  = ""
	escaped      = 0
	gold         = 200
	game_started = false
	game_over    = false
	inspected    = {}
	hover_pos    = Vector2(-1.0, -1.0)
	placing      = false
	_update_inspect_ui()
	_rebuild_path()
	_update_ui()
	queue_redraw()


func _on_start_wave() -> void:
	if game_over:
		_restart()
		return
	if wave_in_progress or current_path.is_empty():
		return
	game_started     = true
	wave            += 1
	spawn_timer      = 0.0
	wave_in_progress = true
	var widx: int = mini(wave - 1, 19)
	wave_spawn_queue.clear()
	if wave % 5 == 0:  # flying wave (every 5th); wave % 10 == 0 also adds bosses
		for _i in WAVE_FLYING_COUNT[widx]:
			wave_spawn_queue.append(1)
		for _i in WAVE_BOSS_COUNT[widx]:
			wave_spawn_queue.append(2)
	else:  # ground wave
		for _i in WAVE_NORMAL_COUNT[widx]:
			wave_spawn_queue.append(0)
	if wave % 10 == 0:
		wave_banner_text = "WAVE %d  —  BOSS ASSAULT" % wave
	elif wave % 5 == 0:
		wave_banner_text = "WAVE %d  —  AIR WAVE" % wave
	else:
		wave_banner_text = "WAVE %d" % wave
	wave_banner_timer = 2.5
	_update_ui()


func _spawn_enemy(etype: int) -> void:
	var widx: int  = mini(wave - 1, 19)
	var speed: float = float(WAVE_SPEED[widx])

	if etype == 2:  # boss
		var hp: float = float(WAVE_BOSS_HP[widx])
		var start := Vector2((ENTRY.x + 0.5) * CELL, (ENTRY.y + 0.5) * CELL)
		var goal  := Vector2((EXIT.x  + 0.5) * CELL, (EXIT.y  + 0.5) * CELL)
		enemies.append({
			pos     = start,
			goal    = goal,
			flying  = true,
			is_boss = true,
			hp      = hp,
			max_hp  = hp,
			speed     = speed * 1.15,
			hit_flash = 0.0,
			dead      = false,
		})
	elif etype == 1:  # flying
		var hp: float = float(WAVE_FLYING_HP[widx])
		var start := Vector2((ENTRY.x + 0.5) * CELL, (ENTRY.y + 0.5) * CELL)
		var goal  := Vector2((EXIT.x  + 0.5) * CELL, (EXIT.y  + 0.5) * CELL)
		enemies.append({
			pos     = start,
			goal    = goal,
			flying  = true,
			is_boss = false,
			hp      = hp,
			max_hp  = hp,
			speed     = speed * 1.25,
			hit_flash = 0.0,
			dead      = false,
		})
	else:  # normal ground
		if current_path.is_empty():
			return
		var hp: float = float(WAVE_NORMAL_HP[widx])
		var waypoints := _path_to_pixels(current_path)
		var init_dir := Vector2.ZERO
		if waypoints.size() >= 2:
			init_dir = (waypoints[1] - waypoints[0]).normalized()
		enemies.append({
			pos        = waypoints[0],
			waypoints  = waypoints,
			wp_idx     = 0,
			dir        = init_dir,
			speed_mult = 1.0,
			flying     = false,
			is_boss    = false,
			hp         = hp,
			max_hp     = hp,
			speed      = speed,
			hit_flash  = 0.0,
			dead       = false,
		})

func _spawn_death_fx(pos: Vector2, flying: bool, is_boss: bool, gold_gained: int) -> void:
	var col: Color = Color(1.0, 0.45, 0.1) if is_boss else (Color(0.25, 0.55, 1.0) if flying else COL_ENEMY)
	var count: int = 8 if is_boss else 5
	for i in count:
		var angle: float = (float(i) / float(count)) * TAU + randf() * 0.5
		var spd:   float = randf_range(35.0, 90.0)
		particles.append({
			pos       = pos,
			vel       = Vector2(cos(angle), sin(angle)) * spd,
			color     = col,
			timer     = randf_range(0.25, 0.55),
			max_timer = 0.5,
		})
	floats.append({
		pos       = pos + Vector2(0.0, -12.0),
		text      = "+%dg" % gold_gained,
		color     = Color(1.0, 0.92, 0.25),
		timer     = 1.1,
		max_timer = 1.1,
	})

# ============================================================
# Game Loop
# ============================================================

func _process(delta: float) -> void:
	if not wave_in_progress:
		return

	_tick_spawner(delta)
	_tick_enemies(delta)
	_resolve_enemy_collisions()
	_tick_towers(delta)
	_tick_projectiles(delta)

	# Tick particles, floats, wave banner
	for pt in particles:
		pt.timer -= delta
		pt.pos   += pt.vel * delta
		pt.vel   *= pow(0.04, delta)
	for f in floats:
		f.timer  -= delta
		f.pos.y  -= 28.0 * delta
	wave_banner_timer = maxf(0.0, wave_banner_timer - delta)

	# Tick explosions
	for ex in explosions:
		ex.timer -= delta
	# Cleanup
	enemies     = enemies.filter(func(e:  Dictionary) -> bool: return not e.dead)
	projectiles = projectiles.filter(func(p:  Dictionary) -> bool: return not p.spent)
	explosions  = explosions.filter(func(ex: Dictionary) -> bool: return ex.timer > 0.0)
	particles   = particles.filter(func(pt: Dictionary) -> bool: return pt.timer > 0.0)
	floats      = floats.filter(func(f:  Dictionary) -> bool: return f.timer  > 0.0)

	if not game_over and escaped > max_escape:
		game_over        = true
		wave_in_progress = false

	if not game_over and wave_spawn_queue.is_empty() and enemies.is_empty():
		wave_in_progress = false
		var wave_bonus: int = WAVE_BONUS[mini(wave - 1, 19)]
		gold += wave_bonus
		_status_lbl.text = "Wave %d klar! +%dg" % [wave, wave_bonus]
		await get_tree().create_timer(2.5).timeout
		_status_lbl.text = ""

	_update_ui()
	queue_redraw()


func _tick_spawner(delta: float) -> void:
	if wave_spawn_queue.is_empty():
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy(wave_spawn_queue.pop_front())
		spawn_timer = SPAWN_INTERVAL


func _tick_enemies(delta: float) -> void:
	for e in enemies:
		if e.dead:
			continue
		if e.hit_flash > 0.0:
			e.hit_flash = maxf(0.0, e.hit_flash - delta)
		if e.flying:
			var fdiff: Vector2 = e.goal - e.pos
			var fdist: float   = fdiff.length()
			var fmove: float   = e.speed * delta
			if fdist <= fmove:
				escaped += 1
				e.dead   = true
			else:
				e.pos += fdiff.normalized() * fmove
			continue
		if e.wp_idx >= e.waypoints.size():
			escaped     += 1
			e.dead       = true
			continue
		var target: Vector2  = e.waypoints[e.wp_idx]
		var diff: Vector2    = target - e.pos
		var dist: float      = diff.length()
		var seg_dir: Vector2 = diff.normalized() if dist > 0.1 else e.dir
		var move: float      = e.speed * e.speed_mult * delta
		if dist <= move:
			e.pos     = target
			e.wp_idx += 1
			if e.wp_idx < e.waypoints.size():
				var new_dir: Vector2   = (e.waypoints[e.wp_idx] - e.pos).normalized()
				var angle: float       = abs(e.dir.angle_to(new_dir)) if e.dir.length() > 0.5 else 0.0
				e.speed_mult = 1.0 - (angle / PI) * 0.6
				e.dir        = new_dir
		else:
			e.pos += seg_dir * move


func _resolve_enemy_collisions() -> void:
	const R     := 7.0
	const MIN_D := R * 2.0
	for i in enemies.size():
		var a: Dictionary = enemies[i]
		if a.dead: continue
		for j in range(i + 1, enemies.size()):
			var b: Dictionary = enemies[j]
			if b.dead: continue
			var sep: Vector2 = b.pos - a.pos
			var d: float     = sep.length()
			if d < MIN_D and d > 0.01:
				var push: Vector2 = sep.normalized() * (MIN_D - d) * 0.5
				a.pos -= push
				b.pos += push


func _tick_towers(delta: float) -> void:
	for t in towers:
		t.cooldown = maxf(0.0, t.cooldown - delta)
		if t.cooldown > 0.0:
			continue
		var tc       := Vector2((t.pos.x + t.sz.x * 0.5) * CELL, (t.pos.y + t.sz.y * 0.5) * CELL)
		var range_px: float = TOWER_RANGE[t.type] * CELL
		# "First" targeting: prefer ground enemy furthest along path, then flying closest to goal
		var ground_target: Dictionary = {}
		var fly_target:    Dictionary = {}
		var best_wp:       int        = -1
		var best_fly_dtg:  float      = INF
		for e in enemies:
			if e.dead: continue
			if tc.distance_to(e.pos) > range_px: continue
			if e.flying:
				var dtg: float = e.pos.distance_to(e.goal)
				if dtg < best_fly_dtg:
					best_fly_dtg = dtg
					fly_target   = e
			else:
				if e.wp_idx > best_wp:
					best_wp       = e.wp_idx
					ground_target = e
		var nearest: Dictionary = ground_target if not ground_target.is_empty() else fly_target
		if not nearest.is_empty():
			var proj_color: Color = TOWER_STROKE[t.type]
			var dmg: float = TOWER_DAMAGE[t.type]
			if nearest.get("flying", false):
				dmg *= TOWER_AIR_MULT[t.type]
			projectiles.append({
				pos         = tc,
				target      = nearest,
				speed       = PROJ_SPEED,
				damage      = dmg,
				color       = proj_color,
				aoe         = TOWER_AOE[t.type],
				splash_px   = TOWER_SPLASH[t.type] * CELL,
				spent       = false,
			})
			t.cooldown = 1.0 / TOWER_FIRERATE[t.type]


func _tick_projectiles(delta: float) -> void:
	for p in projectiles:
		if p.spent:
			continue
		if p.target.dead:
			p.spent = true
			continue
		var diff: Vector2 = p.target.pos - p.pos
		var dist: float   = diff.length()
		var move: float   = p.speed * delta
		if dist <= move + 2.0:
			if p.aoe:
				# Damage all enemies within splash radius
				explosions.append({ pos = p.target.pos, radius = p.splash_px, timer = 0.25 })
				for e in enemies:
					if e.dead: continue
					if p.target.pos.distance_to(e.pos) <= p.splash_px:
						e.hp -= p.damage
						if e.hp <= 0.0:
							e.hp   = 0.0
							e.dead = true
							var kg: int = WAVE_CREEP_GOLD[mini(wave - 1, 19)] * (5 if e.is_boss else 1)
							gold += kg
							_spawn_death_fx(e.pos, e.get("flying", false), e.get("is_boss", false), kg)
						else:
							e.hit_flash = 0.15
			else:
				p.target.hp -= p.damage
				if p.target.hp <= 0.0:
					p.target.hp   = 0.0
					p.target.dead = true
					var kg: int = WAVE_CREEP_GOLD[mini(wave - 1, 19)] * (5 if p.target.is_boss else 1)
					gold += kg
					_spawn_death_fx(p.target.pos, p.target.get("flying", false), p.target.get("is_boss", false), kg)
				else:
					p.target.hit_flash = 0.15
			p.spent = true
		else:
			p.pos += diff.normalized() * move

# ============================================================
# Camera helpers
# ============================================================

func _screen_to_local(screen_pos: Vector2) -> Vector2:
	return screen_pos


func _handle_tap(local: Vector2) -> void:
	var in_grid := local.x >= 0 and local.y >= 0 \
		and local.x < COLS * CELL and local.y < ROWS * CELL
	if not in_grid:
		return
	# In touch mode there is no hover, so calculate placement position on tap
	if placing:
		hover_pos   = _snap(local)
		hover_valid = _can_place(hover_pos, TOWER_SIZES[selected])
	var gx := local.x / CELL
	var gy := local.y / CELL
	var hit := _get_tower_at(gx, gy)
	if not hit.is_empty():
		inspected = hit
		_update_inspect_ui()
		_exit_placement()
	elif placing and hover_valid and gold >= TOWER_COST[selected]:
		var sz: Vector2i = TOWER_SIZES[selected]
		towers.append({ pos = hover_pos, sz = sz, type = selected, cooldown = 0.0 })
		gold -= TOWER_COST[selected]
		inspected = {}
		_update_inspect_ui()
		_rebuild_path()
		_update_ui()
		_exit_placement()

# ============================================================
# Input
# ============================================================

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not event.pressed:
		_handle_tap(event.position)
		queue_redraw()
		return

	if event is InputEventMouseMotion:
		if placing:
			hover_pos   = _snap(event.position)
			hover_valid = _can_place(hover_pos, TOWER_SIZES[selected])
			queue_redraw()
		return

	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_handle_tap(event.position)
					queue_redraw()
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					_remove_at(event.position)
					queue_redraw()

# ============================================================
# Drawing
# ============================================================

func _draw() -> void:
	_draw_bg()
	_draw_grid()
	_draw_subgrid()
	_draw_path()
	_draw_entry_exit()

	# Range circle for inspected tower
	if not inspected.is_empty():
		var tc := Vector2(
			(inspected.pos.x + inspected.sz.x * 0.5) * CELL,
			(inspected.pos.y + inspected.sz.y * 0.5) * CELL)
		var range_px: float = TOWER_RANGE[inspected.type] * CELL
		draw_arc(tc, range_px, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.35), 1.5)

	for t in towers:
		_draw_tower(t.pos, t.sz, t.type, 1.0)
		if not inspected.is_empty() and is_same(t, inspected):
			draw_rect(
				Rect2(t.pos.x * CELL, t.pos.y * CELL, t.sz.x * CELL, t.sz.y * CELL),
				Color(1.0, 1.0, 1.0, 0.9), false, 2.0)

	for e in enemies:
		if not e.dead:
			_draw_enemy(e)
	for p in projectiles:
		if not p.spent:
			var pcol: Color = p.color
			draw_circle(p.pos, 4.0, pcol)

	for ex in explosions:
		var t_frac: float = ex.timer / 0.25
		draw_arc(ex.pos, ex.radius, 0.0, TAU, 32, Color(0.78, 0.4, 1.0, t_frac * 0.8), 2.0)
		draw_circle(ex.pos, ex.radius * (1.0 - t_frac) * 0.5 + 4.0, Color(0.78, 0.4, 1.0, t_frac * 0.4))

	for pt in particles:
		var a: float = pt.timer / pt.max_timer
		draw_circle(pt.pos, 3.0 * a + 1.0, Color(pt.color.r, pt.color.g, pt.color.b, a))

	for f in floats:
		var a: float = f.timer / f.max_timer
		draw_string(_font, f.pos, f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
			Color(f.color.r, f.color.g, f.color.b, a))

	if wave_banner_timer > 0.0:
		var elapsed: float = 2.5 - wave_banner_timer
		var fade: float = minf(1.0, elapsed * 6.0) * minf(1.0, wave_banner_timer * 2.5)
		var fs   := 18
		var tw:  float = float(wave_banner_text.length()) * float(fs) * 0.55
		var cx:  float = (float(COLS) * float(CELL) - tw) * 0.5
		var cy:  float = float(ROWS) * float(CELL) * 0.35
		draw_string(_font, Vector2(cx + 1.0, cy + 1.0), wave_banner_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.0, 0.0, 0.0, fade * 0.8))
		draw_string(_font, Vector2(cx, cy), wave_banner_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.88, 0.2, fade))

	if hover_pos.x >= 0:
		# Range preview while placing
		var hc := Vector2(
			(hover_pos.x + TOWER_SIZES[selected].x * 0.5) * CELL,
			(hover_pos.y + TOWER_SIZES[selected].y * 0.5) * CELL)
		var hrange: float = TOWER_RANGE[selected] * CELL
		draw_arc(hc, hrange, 0.0, TAU, 64, Color(1.0, 1.0, 0.0, 0.20), 1.0)

		_draw_tower(hover_pos, TOWER_SIZES[selected], selected, 0.5 if hover_valid else 0.2)
		if not hover_valid:
			draw_rect(
				Rect2(hover_pos.x * CELL + 1, hover_pos.y * CELL + 1,
					  TOWER_SIZES[selected].x * CELL - 2,
					  TOWER_SIZES[selected].y * CELL - 2),
				COL_INVALID, false, 1.5
			)


func _draw_bg() -> void:
	draw_rect(Rect2(0, 0, COLS * CELL, ROWS * CELL), COL_BG)


func _draw_grid() -> void:
	for c in range(COLS + 1):
		draw_line(Vector2(c * CELL, 0), Vector2(c * CELL, ROWS * CELL), COL_GRID)
	for r in range(ROWS + 1):
		draw_line(Vector2(0, r * CELL), Vector2(COLS * CELL, r * CELL), COL_GRID)


func _draw_subgrid() -> void:
	for i in range(COLS * 2 + 1):
		if i % 2 == 0: continue
		draw_line(Vector2(i * CELL * 0.5, 0), Vector2(i * CELL * 0.5, ROWS * CELL), COL_SUBGRID)
	for i in range(ROWS * 2 + 1):
		if i % 2 == 0: continue
		draw_line(Vector2(0, i * CELL * 0.5), Vector2(COLS * CELL, i * CELL * 0.5), COL_SUBGRID)


func _draw_path() -> void:
	if current_path.size() < 2:
		return
	var half := CELL * 0.5
	for i in range(current_path.size() - 1):
		var a: Vector2i = current_path[i]
		var b: Vector2i = current_path[i + 1]
		draw_line(
			Vector2((a.x + 0.5) * half, (a.y + 0.5) * half),
			Vector2((b.x + 0.5) * half, (b.y + 0.5) * half),
			COL_PATH, 1.5
		)


func _draw_entry_exit() -> void:
	_draw_marker(ENTRY.x, ENTRY.y, "IN",  COL_ENTRY, Color(0.05, 0.20, 0.05))
	_draw_marker(EXIT.x,  EXIT.y,  "OUT", COL_EXIT,  Color(0.20, 0.05, 0.05))


func _draw_marker(col: int, row: int, label: String, stroke: Color, fill: Color) -> void:
	var r := Rect2(col * CELL + 1, row * CELL + 1, CELL - 2, CELL - 2)
	draw_rect(r, fill)
	draw_rect(r, stroke, false, 1.0)
	draw_string(_font,
		Vector2((col + 0.5) * CELL - 5, (row + 0.7) * CELL),
		label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, stroke)


func _draw_tower(pos: Vector2, sz: Vector2i, type: int, alpha: float) -> void:
	var px := pos.x * CELL
	var py := pos.y * CELL
	var pw := sz.x * CELL
	var ph := sz.y * CELL
	var fill:   Color = TOWER_FILL[type];   fill.a   = alpha
	var stroke: Color = TOWER_STROKE[type]; stroke.a = alpha
	draw_rect(Rect2(px + 1, py + 1, pw - 2, ph - 2), fill)
	draw_rect(Rect2(px + 1, py + 1, pw - 2, ph - 2), stroke, false, 1.0)
	var fs := int(minf(pw, ph) * 0.38)
	draw_string(_font,
		Vector2(px + pw * 0.5 - fs * 0.3, py + ph * 0.5 + fs * 0.4),
		TOWER_NAMES[type].substr(0, 1),
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, stroke)


func _draw_enemy(e: Dictionary) -> void:
	var is_boss:   bool  = e.get("is_boss",   false)
	var is_flying: bool  = e.get("flying",    false)
	var flash_t:   float = minf(1.0, e.get("hit_flash", 0.0) / 0.15)

	if is_flying:
		var r:   float = 12.0 if is_boss else 7.0
		var col: Color = Color(1.0, 0.45, 0.1) if is_boss else Color(0.25, 0.55, 1.0)
		if flash_t > 0.0:
			col = col.lerp(Color.WHITE, flash_t)
		var pts := PackedVector2Array([
			e.pos + Vector2(0.0,  -r * 1.4),
			e.pos + Vector2(r,     0.0),
			e.pos + Vector2(0.0,   r * 0.9),
			e.pos + Vector2(-r,    0.0),
		])
		draw_colored_polygon(pts, col)
		var bar_w: float = r * 3.2
		var bar_h  := 3.0
		var bx:    float = e.pos.x - bar_w * 0.5
		var by_:   float = e.pos.y - r * 1.4 - 5.0
		draw_rect(Rect2(bx, by_, bar_w, bar_h), COL_HP_BG)
		draw_rect(Rect2(bx, by_, bar_w * (e.hp / e.max_hp), bar_h), COL_HP_FG)
	else:
		var radius: float = 12.0 if is_boss else 7.0
		var col:    Color = COL_ENEMY
		if flash_t > 0.0:
			col = col.lerp(Color.WHITE, flash_t)
		draw_circle(e.pos, radius, col)
		var bar_w: float = radius * 3.0
		var bar_h  := 3.0
		var bx:    float = e.pos.x - bar_w * 0.5
		var by_:   float = e.pos.y - radius - 5.0
		draw_rect(Rect2(bx, by_, bar_w, bar_h), COL_HP_BG)
		draw_rect(Rect2(bx, by_, bar_w * (e.hp / e.max_hp), bar_h), COL_HP_FG)
