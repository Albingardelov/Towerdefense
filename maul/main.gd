extends Node2D

# ============================================================
# Layout & visual constants
# ============================================================

const COLS       := 16
const VIEWPORT_W := 480
const VIEWPORT_H := 660

var ROWS: int = 22
var CELL: int = 30

const GRID_TOP := 74   # pixels the top bar occupies (+ breathing room below header)
const GRID_BOT := 44   # pixels the bottom toggle occupies

const COL_BG      := Color(0.055, 0.048, 0.042)   # mörk stenfog
const COL_GRID    := Color(0.0, 0.0, 0.0, 0.25)  # subtil svart linje ovanpå texturen
const COL_SUBGRID := Color(1.0, 1.0, 1.0, 0.03)
const COL_ENTRY   := Color(0.29, 1.0, 0.29)
const COL_EXIT    := Color(1.0, 0.29, 0.29)
const COL_INVALID := Color(1.0, 0.29, 0.29)
const COL_PATH    := Color(1.0, 0.8, 0.0, 0.04)
const COL_ENEMY   := Color(0.85, 0.20, 0.20)
const COL_HP_BG   := Color(0.20, 0.05, 0.05)
const COL_HP_FG   := Color(0.20, 0.85, 0.20)

const PROJ_SPEED := 180.0

# ============================================================
# Balance debug + WC3-style armor table
# ============================================================

const _BALANCE_LOG_PREFIX := "[balance]"

# attack_type order matches TowerDefs.ATTACK_*:
# normal, pierce, magic, siege, chaos, hero
# armor order matches WaveDefs.ARMOR_*:
# unarmored, light, medium, heavy, fortified, divine
const _ARMOR_MULT: Array[Array] = [
	[1.00, 1.00, 0.75, 1.00, 0.70, 0.05], # normal
	[1.50, 2.00, 1.00, 0.75, 0.35, 0.05], # pierce
	[1.00, 0.75, 0.75, 2.00, 0.35, 0.05], # magic
	[1.00, 0.50, 1.50, 1.00, 1.50, 0.05], # siege
	[1.00, 1.00, 1.00, 1.00, 1.00, 1.00], # chaos
	[1.00, 1.00, 1.00, 1.00, 0.50, 0.50], # hero
]

const _MAGIC_IMMUNE_MAGIC_MULT := 0.10

# ============================================================
# Nodes
# ============================================================

var _hud:       HUD
var _font:      Font
var _sfx_shoot: AudioStreamPlayer
var _proj_tex:   Texture2D
var _tower_texs: Array = []   # Texture2D per tower type
var _orc_walk_tex:  Texture2D
var _orc_death_tex: Texture2D
var _floor_tex: Texture2D
var _world_env: WorldEnvironment

var _has_drag:  bool = false   # true once a drag event was received this placement
var _drag_right: bool = false  # false = offset left, true = offset right

var _syn_ring_angle: float = 0.0   # rotates synergy rings over time

# Synergy colors (matches SynergyDefs order)
const SYN_COLORS: Dictionary = {
	"slow_roast":       Color(1.0, 0.42, 0.10),  # ember orange
	"disc_mastery":     Color(0.00, 0.90, 1.00),  # electric cyan
	"caffeine_economy": Color(1.00, 0.85, 0.00),  # warm gold
}

# Which tags a tower needs to participate visually in each synergy
const SYN_TAGS: Dictionary = {
	"slow_roast":       ["slow", "dot"],
	"disc_mastery":     ["disc"],
	"caffeine_economy": ["kaffe"],
}


# ============================================================
# Ready
# ============================================================

func _ready() -> void:
	if OS.get_name() == "Windows" or OS.get_name() == "Linux" or OS.get_name() == "macOS":
		get_window().size     = Vector2i(VIEWPORT_W, VIEWPORT_H)
		get_window().min_size = Vector2i(VIEWPORT_W, VIEWPORT_H)

	# Fit grid to actual viewport, leaving room for top/bottom bars
	var vp_size := get_viewport_rect().size
	CELL = int(vp_size.x / COLS)
	ROWS = int((vp_size.y - GRID_TOP - GRID_BOT) / CELL)
	position = Vector2(0, GRID_TOP)
	Pathfinder.ROWS  = ROWS
	Pathfinder.SROWS = ROWS * 2
	Pathfinder.EXIT  = Vector2i(Pathfinder.ENTRY.x, ROWS - 1)

	_font = ThemeDB.fallback_font

	var sfx_start := AudioStreamPlayer.new()
	sfx_start.stream = load("res://assets/Startsound.wav")
	sfx_start.volume_db = 0.0
	add_child(sfx_start)
	sfx_start.play()

	_sfx_shoot = AudioStreamPlayer.new()
	_sfx_shoot.stream = load("res://assets/39459__the_bizniss__laser.wav")
	_sfx_shoot.volume_db = -6.0
	add_child(_sfx_shoot)

	_proj_tex     = load("res://assets/Part 2/69.png")
	_orc_walk_tex  = load("res://assets/Orc/Orc/Orc-Walk.png")
	_orc_death_tex = load("res://assets/Orc/Orc/Orc-Death.png")
	# Tower textures no longer used — towers are drawn procedurally
	_tower_texs.clear()
	_floor_tex = load("res://assets/Floor_Tileset/floor_tiles.png")

	var env := Environment.new()
	env.glow_enabled       = true
	env.glow_normalized    = false
	env.glow_intensity     = 3.5
	env.glow_bloom         = 1.0
	env.glow_hdr_threshold = 0.3
	env.glow_hdr_scale     = 5.0
	_world_env             = WorldEnvironment.new()
	_world_env.environment = env
	add_child(_world_env)

	_hud = HUD.new()
	_hud.tower_selected.connect(_select_tower)
	_hud.start_wave_pressed.connect(_on_send_early)
	_hud.difficulty_set.connect(_set_difficulty)
	_hud.map_selected.connect(_on_map_selected)
	_hud.clear_all_pressed.connect(_on_clear_all)
	_hud.sell_tower_pressed.connect(_on_sell_tower)
	_hud.drag_side_changed.connect(func(right: bool) -> void: _drag_right = right)
	add_child(_hud)

	GameState.wave_completed.connect(func(wave_num: int, _bonus: int) -> void:
		if wave_num % 10 == 0:
			_trigger_relic_draft()
		elif wave_num % 5 == 0:
			_trigger_draft())

	GameState.wave_started.connect(func(_wave_num: int, _banner: String) -> void:
		for relic: Dictionary in GameState.active_relics:
			if relic.effect == "wave_gold":
				GameState.add_gold(int(relic.value)))

	# Konfigurera klassisk karta som standard
	_on_map_selected(0)
	Pathfinder.rebuild(CELL)

# ============================================================
# Input
# ============================================================

func _get_drag_off() -> Vector2:
	var side := 1 if _drag_right else -1
	return Vector2(CELL * 2.5 * side, -CELL * 2.5)


func _input(event: InputEvent) -> void:
	# ── Drag-to-place: update ghost while dragging ────────────
	if event is InputEventScreenDrag and GameState.placing:
		var local := to_local(event.position)
		GameState.hover_pos   = _snap(local + _get_drag_off())
		GameState.hover_valid = _can_place(GameState.hover_pos, TowerDefs.SIZES[GameState.selected])
		_has_drag = true
		queue_redraw()
		get_viewport().set_input_as_handled()
		return

	# ── Touch release: place or inspect ───────────────────────
	if event is InputEventScreenTouch and not event.pressed:
		if GameState.placing:
			if _has_drag:
				# Use the last stable snapped position from drag, ignoring release jitter.
				# Pass top-left corner in pixels so _snap() re-snaps to the exact same cell.
				var stable := GameState.hover_pos * float(CELL)
				_has_drag = false
				_handle_tap(stable)
			else:
				# Tap (no prior drag): apply offset normally
				var tap_pos := to_local(event.position) + _get_drag_off()
				var in_grid: bool = tap_pos.x >= 0 and tap_pos.y >= 0 \
					and tap_pos.x < COLS * CELL and tap_pos.y < ROWS * CELL
				if in_grid:
					GameState.hover_pos   = _snap(tap_pos)
					GameState.hover_valid = _can_place(GameState.hover_pos, TowerDefs.SIZES[GameState.selected])
					_handle_tap(tap_pos)
				else:
					_exit_placement()
		else:
			_has_drag = false
			_handle_tap(to_local(event.position))
		queue_redraw()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if GameState.placing:
			GameState.hover_pos   = _snap(to_local(event.position))
			GameState.hover_valid = _can_place(GameState.hover_pos, TowerDefs.SIZES[GameState.selected])
			queue_redraw()
		return

	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_handle_tap(to_local(event.position))
					queue_redraw()
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					_remove_at(to_local(event.position))
					queue_redraw()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F8:
			GameState.balance_debug_enabled = not GameState.balance_debug_enabled
			_hud.show_status("Balance debug: %s" % ["ON" if GameState.balance_debug_enabled else "OFF"])
			await get_tree().create_timer(1.2).timeout
			_hud.show_status("")

# ============================================================
# Placement & selection
# ============================================================

func _select_tower(idx: int) -> void:
	GameState.selected = idx
	GameState.placing  = true


func _exit_placement() -> void:
	GameState.placing   = false
	GameState.hover_pos = Vector2(-1.0, -1.0)
	_hud.deselect_tower_buttons()
	queue_redraw()


func _handle_tap(local: Vector2) -> void:
	var in_grid := local.x >= 0 and local.y >= 0 \
		and local.x < COLS * CELL and local.y < ROWS * CELL
	if not in_grid:
		return

	if GameState.placing:
		GameState.hover_pos   = _snap(local)
		GameState.hover_valid = _can_place(GameState.hover_pos, TowerDefs.SIZES[GameState.selected])

	var gx := local.x / CELL
	var gy := local.y / CELL
	var hit := _get_tower_at(gx, gy)

	if not hit.is_empty() and not GameState.placing:
		GameState.set_inspected(hit)
	elif GameState.placing and GameState.hover_valid \
			and GameState.gold >= TowerDefs.COST[GameState.selected]:
		var sz: Vector2i = TowerDefs.SIZES[GameState.selected]
		GameState.towers.append({
			pos      = GameState.hover_pos,
			sz       = sz,
			type     = GameState.selected,
			cooldown = 0.0,
		})
		GameState.spend_gold(TowerDefs.COST[GameState.selected])
		GameState._refresh_synergies()
		GameState.set_inspected({})
		Pathfinder.rebuild(CELL)
		_exit_placement()
	else:
		GameState.set_inspected({})

# ============================================================
# UI callbacks
# ============================================================

func _on_map_selected(idx: int) -> void:
	if not GameState.game_started and GameState.unlocked_towers.is_empty():
		_give_starting_towers()
	GameState.current_map  = idx
	Pathfinder.map_mode    = idx
	if idx == 1:  # Mandala — fyra hörn mot mitten
		Pathfinder.map_entries = [
			Vector2i(0,        0),
			Vector2i(COLS - 1, 0),
			Vector2i(0,        ROWS - 1),
			Vector2i(COLS - 1, ROWS - 1),
		]
		Pathfinder.map_exit_point = Vector2i(COLS / 2, ROWS / 2)
	else:         # Klassisk — uppifrån ner
		Pathfinder.map_entries    = [Pathfinder.ENTRY]
		Pathfinder.map_exit_point = Pathfinder.EXIT


func _set_difficulty(idx: int) -> void:
	if GameState.game_started:
		return
	GameState.difficulty = idx
	GameState.max_escape = [100, 50, 0][idx]
	GameState.escaped_changed.emit(GameState.escaped, GameState.max_escape)
	if GameState.current_map == 1:  # Mandala — fyra ingångar kräver mer guld
		GameState.gold = 1200
		GameState.gold_changed.emit(GameState.gold)


func _on_send_early() -> void:
	if GameState.game_over:
		GameState.reset()
		Pathfinder.rebuild(CELL)
		queue_redraw()
		return
	if GameState.wave_in_progress or GameState.current_path.is_empty():
		return
	GameState.wave_countdown = 0.0


func _on_sell_tower() -> void:
	if GameState.inspected.is_empty():
		return
	var t := GameState.inspected
	GameState.set_inspected({})
	var refund: int = int(TowerDefs.COST[t.type] * 0.75)
	GameState.add_gold(refund)
	GameState.towers = GameState.towers.filter(func(x: Dictionary) -> bool:
		return not is_same(x, t))
	GameState._refresh_synergies()
	Pathfinder.rebuild(CELL)
	queue_redraw()


func _on_clear_all() -> void:
	if GameState.wave_in_progress:
		return
	var refund: int = 0
	for t in GameState.towers:
		refund += int(TowerDefs.COST[t.type] * 0.75)
	if refund > 0:
		GameState.add_gold(refund)
	GameState.towers.clear()
	GameState._refresh_synergies()
	GameState.set_inspected({})
	Pathfinder.rebuild(CELL)
	queue_redraw()

# ============================================================
# Grid helpers
# ============================================================

func _snap(pixel: Vector2) -> Vector2:
	var sz: Vector2i = TowerDefs.SIZES[GameState.selected]
	var cell         := float(CELL)
	var gx: float    = round((pixel.x / cell) * 2.0) / 2.0
	var gy: float    = round((pixel.y / cell) * 2.0) / 2.0
	gx = clamp(gx, 0.0, float(COLS - sz.x))
	gy = clamp(gy, 0.0, float(ROWS - sz.y))
	return Vector2(gx, gy)


func _overlap(ax: float, ay: float, aw: float, ah: float,
		bx: float, by: float, bw: float, bh: float) -> bool:
	return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by


func _can_place(pos: Vector2, sz: Vector2i) -> bool:
	if pos.x < 0 or pos.y < 0 or pos.x + sz.x > COLS or pos.y + sz.y > ROWS:
		return false
	# Blockera inte ingångspunkter
	for entry in Pathfinder.map_entries:
		if _overlap(pos.x, pos.y, sz.x, sz.y, entry.x, entry.y, 1, 1):
			return false
	# Blockera inte utgångspunkten
	var ep := Pathfinder.map_exit_point
	if _overlap(pos.x, pos.y, sz.x, sz.y, ep.x, ep.y, 1, 1):
		return false
	for t in GameState.towers:
		if _overlap(pos.x, pos.y, sz.x, sz.y, t.pos.x, t.pos.y, t.sz.x, t.sz.y):
			return false
	# Alla stigar måste förbli öppna
	var blocked := Pathfinder.build_blocked(pos, sz)
	for entry in Pathfinder.map_entries:
		if Pathfinder.bfs_path(entry, Pathfinder.map_exit_point, blocked).is_empty():
			return false
	return true


func _get_tower_at(gx: float, gy: float) -> Dictionary:
	for t in GameState.towers:
		if gx >= t.pos.x and gx < t.pos.x + t.sz.x \
		and gy >= t.pos.y and gy < t.pos.y + t.sz.y:
			return t
	return {}


func _remove_at(pixel: Vector2) -> void:
	var gx := pixel.x / CELL
	var gy := pixel.y / CELL
	var hit := _get_tower_at(gx, gy)
	if hit.is_empty():
		return
	var refund: int = int(TowerDefs.COST[hit.type] * 0.75)
	GameState.add_gold(refund)
	if is_same(hit, GameState.inspected):
		GameState.set_inspected({})
	GameState.towers = GameState.towers.filter(func(t: Dictionary) -> bool:
		return not (gx >= t.pos.x and gx < t.pos.x + t.sz.x
				and gy >= t.pos.y and gy < t.pos.y + t.sz.y))
	Pathfinder.rebuild(CELL)

# ============================================================
# Game loop
# ============================================================

func _process(delta: float) -> void:
	if GameState.game_over:
		return

	if not GameState.wave_in_progress:
		GameState.wave_countdown = maxf(0.0, GameState.wave_countdown - delta)
		_hud.update_countdown(GameState.wave_countdown, GameState.wave + 1)
		_hud.update_wave_preview(GameState.wave + 1)
		if GameState.wave_countdown <= 0.0 and not GameState.current_path.is_empty():
			WaveManager.start()
			_balance_on_wave_start()
		queue_redraw()
		return

	_syn_ring_angle += delta * 0.4
	WaveManager.tick_spawner(delta, CELL)
	_tick_enemies(delta)
	_tick_towers(delta)
	_tick_projectiles(delta)
	_tick_vfx(delta)
	_check_wave_end()
	queue_redraw()


func _tick_vfx(delta: float) -> void:
	for pt in GameState.particles:
		pt.timer -= delta
		pt.pos   += pt.vel * delta
		pt.vel   *= pow(0.04, delta)
	for f in GameState.floats:
		f.timer  -= delta
		f.pos.y  -= 28.0 * delta
	GameState.wave_banner_timer = maxf(0.0, GameState.wave_banner_timer - delta)
	for ex in GameState.explosions:
		ex.timer -= delta
	for c in GameState.corpses:
		c.timer += delta



	GameState.enemies     = GameState.enemies.filter(func(e:  Dictionary) -> bool: return not e.dead)
	GameState.corpses     = GameState.corpses.filter(func(c:  Dictionary) -> bool: return c.timer < 0.7)
	GameState.projectiles = GameState.projectiles.filter(func(p:  Dictionary) -> bool: return not p.spent)
	GameState.explosions  = GameState.explosions.filter(func(ex: Dictionary) -> bool: return ex.timer > 0.0)
	GameState.particles   = GameState.particles.filter(func(pt: Dictionary) -> bool: return pt.timer > 0.0)
	GameState.floats      = GameState.floats.filter(func(f:  Dictionary) -> bool: return f.timer  > 0.0)


func _check_wave_end() -> void:
	if not GameState.game_over and GameState.escaped > GameState.max_escape:
		GameState.game_over        = true
		GameState.wave_in_progress = false
		GameState.runs_played += 1
		if GameState.wave > GameState.best_wave:
			GameState.best_wave = GameState.wave
		GameState.save_meta()
		_hud.show_run_summary()
		GameState.game_over_triggered.emit()
		return

	if not GameState.game_over \
			and GameState.wave_spawn_queue.is_empty() \
			and GameState.enemies.is_empty():
		GameState.wave_in_progress = false
		GameState.wave_countdown   = GameState.WAVE_INTERVAL
		var wd_end := WaveDefs.get_wave(GameState.wave)
		# Air waves: bonus only if player killed at least 1 enemy (has air towers)
		var bonus: int = wd_end.bonus if (not wd_end.flies or GameState.wave_kills > 0) else 0
		if bonus > 0:
			GameState.add_gold(bonus)
		GameState.wave_completed.emit(GameState.wave, bonus)
		_show_wave_complete_status(bonus)
		_balance_on_wave_end(bonus)


func _show_wave_complete_status(bonus: int) -> void:
	_hud.show_status("Wave %d done! +%dg" % [GameState.wave, bonus])
	await get_tree().create_timer(2.5).timeout
	_hud.show_status("")

# ============================================================
# Simulation — enemies
# ============================================================

func _tick_enemies(delta: float) -> void:
	for e in GameState.enemies:
		if e.dead:
			continue

		# Ticka DoT
		if e.get("dot_t", 0.0) > 0.0:
			e["dot_t"] -= delta
			var creep_gold_dot: int = WaveDefs.get_wave(GameState.wave).bounty
			var dot_mult := 1.5 if (GameState.active_synergies.has("slow_roast") \
				and e.get("slow_factor", 0.0) > 0.0) else 1.0
			_apply_damage(e, e["dot_dps"] * delta * dot_mult, creep_gold_dot)
			if e.dead:
				continue

		# Räkna ner slow
		if e.get("slow_t", 0.0) > 0.0:
			e["slow_t"] -= delta
			if e["slow_t"] <= 0.0:
				e["slow_factor"] = 0.0

		if e.hit_flash > 0.0:
			e.hit_flash = maxf(0.0, e.hit_flash - delta)

		var eff_speed: float = e.speed * (1.0 - e.get("slow_factor", 0.0))

		if e.flying:
			var fdiff: Vector2 = e.goal - e.pos
			var fdist: float   = fdiff.length()
			var fmove: float   = eff_speed * delta
			if fdist <= fmove:
				GameState.add_escaped()
				e.dead = true
			else:
				e.pos += fdiff.normalized() * fmove
			continue

		if e.wp_idx >= e.waypoints.size():
			GameState.add_escaped()
			e.dead = true
			continue

		var target: Vector2  = e.waypoints[e.wp_idx]
		var diff:   Vector2  = target - e.pos
		var dist:   float    = diff.length()
		var move:   float    = eff_speed * delta

		if dist <= move:
			e.pos     = target
			e.wp_idx += 1
		else:
			if abs(diff.x) > 1.0:
				e.face_right = diff.x > 0.0
			e.pos += diff.normalized() * move


# ============================================================
# Draft
# ============================================================

func _trigger_relic_draft() -> void:
	var pool: Array[Dictionary] = []
	for relic: Dictionary in RelicDefs.RELICS:
		var already: bool = false
		for held: Dictionary in GameState.active_relics:
			if held.id == relic.id:
				already = true
				break
		if not already:
			pool.append(relic)
	if pool.is_empty():
		return
	pool.shuffle()
	var offer: Array[Dictionary] = pool.slice(0, mini(3, pool.size()))
	GameState.draft_pending = true
	GameState.relic_draft_ready.emit(offer)


func _trigger_draft() -> void:
	# Stratify pool by wave: early waves only see affordable towers
	var wave := GameState.wave
	var cost_cap: int
	if wave <= 10:
		cost_cap = 400
	elif wave <= 20:
		cost_cap = 600
	else:
		cost_cap = 9999

	var pool: Array[int] = []
	for i in TowerDefs.count():
		if not GameState.unlocked_towers.has(i) and TowerDefs.COST[i] <= cost_cap:
			pool.append(i)
	# Fallback: if pool is tiny, open to all unlockable towers
	if pool.size() < 3:
		for i in TowerDefs.count():
			if not GameState.unlocked_towers.has(i) and not pool.has(i):
				pool.append(i)
	pool.shuffle()
	var offer: Array[int] = pool.slice(0, mini(3, pool.size()))
	GameState.draft_pending = true
	GameState.draft_ready.emit(offer)


func _give_starting_towers() -> void:
	var all: Array[int] = []
	for i in TowerDefs.count():
		all.append(i)
	all.shuffle()
	for i in mini(2, all.size()):
		GameState.unlocked_towers.append(all[i])


# ============================================================
# Simulation — towers & projectiles
# ============================================================

func _tick_towers(delta: float) -> void:
	for t in GameState.towers:
		t.cooldown = maxf(0.0, t.cooldown - delta)
		if t.cooldown > 0.0:
			continue

		var tc       := Vector2((t.pos.x + t.sz.x * 0.5) * CELL, (t.pos.y + t.sz.y * 0.5) * CELL)
		var range_px: float = TowerDefs.RANGE[t.type] * CELL
		if GameState.active_synergies.has("disc_mastery") \
				and TowerDefs.TAGS[t.type].has("disc"):
			range_px *= 1.20
		# Relic: Muay Thai +range
		for relic: Dictionary in GameState.active_relics:
			if relic.effect == "muay_range" \
					and TowerDefs.TAGS[t.type].has("muay_thai"):
				range_px += relic.value * float(CELL)

		var ground_target: Dictionary = {}
		var fly_target:    Dictionary = {}
		var best_wp:       int        = -1
		var best_fly_dtg:  float      = INF

		for e in GameState.enemies:
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
			var dmg: float = TowerDefs.DAMAGE[t.type]
			for relic: Dictionary in GameState.active_relics:
				if relic.effect == "disc_damage" \
						and TowerDefs.TAGS[t.type].has("disc"):
					dmg *= relic.value
			if nearest.get("flying", false):
				dmg *= TowerDefs.AIR_MULT[t.type]
			GameState.projectiles.append({
				pos        = tc,
				target     = nearest,
				speed      = PROJ_SPEED,
				damage     = dmg,
				color      = TowerDefs.STROKE[t.type],
				aoe        = TowerDefs.AOE[t.type],
				splash_px  = TowerDefs.SPLASH[t.type] * CELL,
				spent      = false,
				anim_time  = 0.0,
				tower_type = t.type,
			})
			var firerate: float = TowerDefs.FIRERATE[t.type]
			for relic: Dictionary in GameState.active_relics:
				if relic.effect == "guitar_firerate" \
						and TowerDefs.TAGS[t.type].has("gitarr"):
					firerate *= relic.value
			t.cooldown = 1.0 / firerate
			_sfx_shoot.play()


func _tick_projectiles(delta: float) -> void:
	var creep_gold: int = WaveDefs.get_wave(GameState.wave).bounty
	for p in GameState.projectiles:
		if p.spent:
			continue
		if p.target.dead:
			p.spent = true
			continue

		p.anim_time += delta

		var diff: Vector2 = p.target.pos - p.pos
		var dist: float   = diff.length()
		var move: float   = p.speed * delta

		if dist <= move + 2.0:
			if p.aoe:
				GameState.explosions.append({ pos = p.target.pos, radius = p.splash_px, timer = 0.25 })
				for e in GameState.enemies:
					if e.dead: continue
					if p.target.pos.distance_to(e.pos) <= p.splash_px:
						_apply_damage(e, p.damage, creep_gold, p.tower_type)
			else:
				_apply_damage(p.target, p.damage, creep_gold, p.tower_type)
			p.spent = true
		else:
			p.pos += diff.normalized() * move


func _apply_damage(e: Dictionary, damage: float, creep_gold: int,
		tower_type: int = -1) -> void:
	var prev_hp: float = e.hp
	var applied: float = _apply_armor_and_special(damage, tower_type, e)
	e.hp -= applied
	if GameState.balance_debug_enabled and applied > 0.0:
		GameState.balance_wave_damage += minf(prev_hp, applied)
	# Applicera slow
	if tower_type >= 0 and TowerDefs.SLOW[tower_type] > 0.0:
		e["slow_factor"] = TowerDefs.SLOW[tower_type]
		var slow_dur: float = TowerDefs.SLOW_DUR[tower_type]
		for relic: Dictionary in GameState.active_relics:
			if relic.effect == "slow_duration":
				slow_dur += relic.value
		e["slow_t"] = slow_dur
	# Applicera DoT (ersätter befintlig om starkare)
	if tower_type >= 0 and TowerDefs.DOT[tower_type] > 0.0:
		if TowerDefs.DOT[tower_type] >= e.get("dot_dps", 0.0):
			e["dot_dps"] = TowerDefs.DOT[tower_type]
			e["dot_t"]   = TowerDefs.DOT_DUR[tower_type]
	if e.hp <= 0.0:
		e.hp   = 0.0
		e.dead = true
		GameState.wave_kills += 1
		var kg: int = creep_gold
		if tower_type >= 0 and GameState.active_synergies.has("caffeine_economy") \
				and TowerDefs.TAGS[tower_type].has("kaffe"):
			kg += 1
		GameState.add_gold(kg)
		if not e.get("flying", false):
			GameState.corpses.append({
				pos        = e.pos,
				is_boss    = e.get("is_boss", false),
				face_right = e.get("face_right", true),
				timer      = 0.0,
			})
		WaveManager.spawn_death_fx(e.pos, e.get("flying", false), e.get("is_boss", false), kg)
		e["hit_flash"] = 0.0
	else:
		e["hit_flash"] = 0.15


func _apply_armor_and_special(base_damage: float, tower_type: int, e: Dictionary) -> float:
	if base_damage <= 0.0:
		return 0.0

	var attack_type: int = TowerDefs.ATTACK_NORMAL
	if tower_type >= 0 and tower_type < TowerDefs.count():
		attack_type = int(TowerDefs.ATTACK_TYPE[tower_type])

	var armor_type: int = int(e.get("armor", WaveDefs.ARMOR_UNARMORED))
	armor_type = clampi(armor_type, WaveDefs.ARMOR_UNARMORED, WaveDefs.ARMOR_DIVINE)

	var mult: float = float(_ARMOR_MULT[attack_type][armor_type])

	# Wave special: magic immune → reduce magic damage further.
	# Keeps the identity without hard-immunity (0 damage) which can soft-lock builds.
	var special: int = int(e.get("special", WaveDefs.SPECIAL_NONE))
	if special == WaveDefs.SPECIAL_MAGIC_IMMUNE and attack_type == TowerDefs.ATTACK_MAGIC:
		mult *= _MAGIC_IMMUNE_MAGIC_MULT

	return base_damage * mult


func _balance_on_wave_start() -> void:
	if not GameState.balance_debug_enabled:
		return
	GameState.balance_wave_start_t = Time.get_ticks_msec() / 1000.0
	GameState.balance_wave_damage = 0.0
	GameState.balance_wave_gold_start = GameState.gold
	GameState.balance_wave_escaped_start = GameState.escaped


func _balance_on_wave_end(bonus_paid: int) -> void:
	if not GameState.balance_debug_enabled:
		return

	var t_end: float = Time.get_ticks_msec() / 1000.0
	var clear_time: float = maxf(0.001, t_end - GameState.balance_wave_start_t)

	var wd := WaveDefs.get_wave(GameState.wave)
	var count: int = int(wd.count)
	var hp_unit: float = float(wd.hp)
	var speed: float = float(wd.speed)

	# Estimate L (px) as average path length over entries.
	# For flying waves, use straight-line in->out distance.
	var L_px: float = 0.0
	var entries: Array = Pathfinder.map_entries
	if bool(wd.flies):
		for entry in entries:
			var entry_px := Vector2((entry.x + 0.5) * CELL, (entry.y + 0.5) * CELL)
			var exit_px  := Vector2((Pathfinder.map_exit_point.x + 0.5) * CELL,
									(Pathfinder.map_exit_point.y + 0.5) * CELL)
			L_px += entry_px.distance_to(exit_px)
	else:
		var n: int = maxi(1, GameState.current_paths.size())
		for i in n:
			var path: Array = GameState.current_paths[i]
			if path.size() < 2:
				continue
			var len: float = 0.0
			for j in range(path.size() - 1):
				var a: Vector2i = path[j]
				var b: Vector2i = path[j + 1]
				len += Vector2(float(b.x - a.x), float(b.y - a.y)).length() * (CELL * 0.5)
			L_px += len
	L_px = L_px / float(maxi(1, entries.size()))

	var spawn_time: float = float(maxi(0, count - 1)) * WaveManager.SPAWN_INTERVAL
	var travel_time: float = L_px / maxf(1.0, speed)
	var T: float = maxf(0.001, travel_time + spawn_time)

	var hp_pool: float = float(count) * hp_unit

	# "Effective HP" baseline vs NORMAL attack type (gives a stable reference).
	var armor_type: int = int(wd.armor)
	armor_type = clampi(armor_type, WaveDefs.ARMOR_UNARMORED, WaveDefs.ARMOR_DIVINE)
	var k_norm: float = float(_ARMOR_MULT[TowerDefs.ATTACK_NORMAL][armor_type])
	var hp_pool_eff_norm: float = hp_pool / maxf(0.0001, k_norm)

	var dps_req_base: float = hp_pool / T
	var dps_req_norm: float = hp_pool_eff_norm / T

	var leaks: int = GameState.escaped - GameState.balance_wave_escaped_start
	var gold_start: int = GameState.balance_wave_gold_start
	var gold_end: int = GameState.gold
	var gold_gained: int = gold_end - gold_start
	var kill_income_est: int = int(wd.bounty) * int(GameState.wave_kills)

	var tower_value: int = 0
	for t in GameState.towers:
		tower_value += int(TowerDefs.COST[t.type])
	var tower_sell_value: int = int(float(tower_value) * 0.75)

	print_debug("%s wave=%d name=%s special=%d flies=%s armor=%d count=%d hp=%.1f speed=%.1f" % [
		_BALANCE_LOG_PREFIX, GameState.wave, String(wd.name), int(wd.special), str(bool(wd.flies)),
		armor_type, count, hp_unit, speed
	])
	print_debug("%s L_px=%.0f T=%.2f travel=%.2f spawn=%.2f clear_time=%.2f" % [
		_BALANCE_LOG_PREFIX, L_px, T, travel_time, spawn_time, clear_time
	])
	print_debug("%s hp_pool=%.0f hp_pool_eff_norm=%.0f dps_req_base=%.1f dps_req_norm=%.1f" % [
		_BALANCE_LOG_PREFIX, hp_pool, hp_pool_eff_norm, dps_req_base, dps_req_norm
	])
	print_debug("%s dmg_dealt=%.0f dps_dealt=%.1f kills=%d leaks=%d" % [
		_BALANCE_LOG_PREFIX, GameState.balance_wave_damage, GameState.balance_wave_damage / clear_time,
		GameState.wave_kills, leaks
	])
	print_debug("%s gold_start=%d gold_end=%d gold_gained=%+d (bonus_paid=%d, kill_income_est=%d) tower_value=%d sell_value=%d" % [
		_BALANCE_LOG_PREFIX, gold_start, gold_end, gold_gained, bonus_paid, kill_income_est,
		tower_value, tower_sell_value
	])

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
	if not GameState.inspected.is_empty():
		var tc := Vector2(
			(GameState.inspected.pos.x + GameState.inspected.sz.x * 0.5) * CELL,
			(GameState.inspected.pos.y + GameState.inspected.sz.y * 0.5) * CELL)
		draw_arc(tc, TowerDefs.RANGE[GameState.inspected.type] * CELL,
			0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.35), 1.5)

	for t in GameState.towers:
		_draw_tower(t.pos, t.sz, t.type, 1.0)
		if not GameState.inspected.is_empty() and is_same(t, GameState.inspected):
			draw_rect(Rect2(t.pos.x * CELL, t.pos.y * CELL, t.sz.x * CELL, t.sz.y * CELL),
				Color(1.0, 1.0, 1.0, 0.9), false, 2.0)
		_draw_synergy_ring(t)

	for c in GameState.corpses:
		if _orc_death_tex:
			var frame: int = mini(int(c.timer * 6.0), 3)   # 4 frames, 6fps ≈ 0.67s
			var r:     float = 110.0 if c.is_boss else 80.0
			var src   := Rect2(frame * 100, 0, 100, 100)
			var dst   := Rect2(c.pos.x - r, c.pos.y - r, r * 2.0, r * 2.0)
			var fade:  float = 1.0 - (c.timer / 0.7)
			if c.face_right:
				draw_texture_rect_region(_orc_death_tex, dst, src, Color(1, 1, 1, fade))
			else:
				draw_set_transform(Vector2(c.pos.x * 2.0, 0.0), 0.0, Vector2(-1.0, 1.0))
				draw_texture_rect_region(_orc_death_tex, dst, src, Color(1, 1, 1, fade))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for e in GameState.enemies:
		if not e.dead:
			_draw_enemy(e)

	for p in GameState.projectiles:
		if not p.spent:
			var ttype: int = p.get("tower_type", 0)
			var sc:  Color = TowerDefs.STROKE[ttype]
			var tex: Texture2D = _tower_texs[ttype] if ttype < _tower_texs.size() else null
			if tex:
				var row:   int = TowerDefs.ANIM_ROW[ttype]
				var fps: float = TowerDefs.ANIM_FPS[ttype]
				var frame: int = int(p.anim_time * fps * 2.0) % 8
				var src := Rect2(frame * 64, row * 64, 64, 64)
				var dst := Rect2(p.pos.x - 10, p.pos.y - 10, 20, 20)
				# Glow-aura i tornets färg
				draw_circle(p.pos, 12.0, Color(sc.r * 0.25, sc.g * 0.25, sc.b * 0.25, 0.20))
				draw_circle(p.pos,  8.0, Color(sc.r * 0.60, sc.g * 0.60, sc.b * 0.60, 0.35))
				draw_circle(p.pos,  5.0, Color(sc.r * 1.00, sc.g * 1.00, sc.b * 1.00, 0.55))
				# Sprite med HDR-modulate för bloom
				draw_texture_rect_region(tex, dst, src, Color(sc.r * 6.0, sc.g * 6.0, sc.b * 6.0))
			else:
				draw_circle(p.pos, 4.0, p.color)

	for ex in GameState.explosions:
		var t_frac: float = ex.timer / 0.25
		draw_arc(ex.pos, ex.radius, 0.0, TAU, 32, Color(0.78, 0.4, 1.0, t_frac * 0.8), 2.0)
		draw_circle(ex.pos, ex.radius * (1.0 - t_frac) * 0.5 + 4.0, Color(0.78, 0.4, 1.0, t_frac * 0.4))

	for pt in GameState.particles:
		var a: float = pt.timer / pt.max_timer
		draw_circle(pt.pos, 3.0 * a + 1.0, Color(pt.color.r, pt.color.g, pt.color.b, a))

	for f in GameState.floats:
		var a: float = f.timer / f.max_timer
		draw_string(_font, f.pos, f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
			Color(f.color.r, f.color.g, f.color.b, a))

	if GameState.wave_banner_timer > 0.0:
		var elapsed: float = 2.5 - GameState.wave_banner_timer
		var fade: float = minf(1.0, elapsed * 6.0) * minf(1.0, GameState.wave_banner_timer * 2.5)
		var fs   := 18
		var tw:  float = float(GameState.wave_banner_text.length()) * float(fs) * 0.55
		var cx:  float = (float(COLS) * float(CELL) - tw) * 0.5
		var cy:  float = float(ROWS) * float(CELL) * 0.35
		draw_string(_font, Vector2(cx + 1.0, cy + 1.0), GameState.wave_banner_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.0, 0.0, 0.0, fade * 0.8))
		draw_string(_font, Vector2(cx, cy), GameState.wave_banner_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.88, 0.2, fade))

	if GameState.hover_pos.x >= 0:
		# Visa footprint på alla placerade torn under placement-läge
		for t in GameState.towers:
			draw_rect(
				Rect2(t.pos.x * CELL + 1, t.pos.y * CELL + 1,
					t.sz.x * CELL - 2, t.sz.y * CELL - 2),
				Color(1.0, 1.0, 1.0, 0.25), false, 1.0)

		var hc := Vector2(
			(GameState.hover_pos.x + TowerDefs.SIZES[GameState.selected].x * 0.5) * CELL,
			(GameState.hover_pos.y + TowerDefs.SIZES[GameState.selected].y * 0.5) * CELL)
		draw_arc(hc, TowerDefs.RANGE[GameState.selected] * CELL,
			0.0, TAU, 64, Color(1.0, 1.0, 0.0, 0.20), 1.0)
		var fp_rect := Rect2(
			GameState.hover_pos.x * CELL + 1, GameState.hover_pos.y * CELL + 1,
			TowerDefs.SIZES[GameState.selected].x * CELL - 2,
			TowerDefs.SIZES[GameState.selected].y * CELL - 2)
		if GameState.hover_valid:
			draw_rect(fp_rect, Color(0.3, 1.0, 0.3, 0.12))
			draw_rect(fp_rect, Color(0.3, 1.0, 0.3, 0.55), false, 1.5)
		else:
			draw_rect(fp_rect, Color(1.0, 0.3, 0.3, 0.12))
			draw_rect(fp_rect, COL_INVALID, false, 1.5)
		_draw_tower(GameState.hover_pos, TowerDefs.SIZES[GameState.selected],
			GameState.selected, 0.5 if GameState.hover_valid else 0.2)


func _draw_synergy_ring(t: Dictionary) -> void:
	if GameState.active_synergies.is_empty():
		return
	var tags: Array = TowerDefs.TAGS[t.type]
	var active_colors: Array[Color] = []
	for syn_id: String in GameState.active_synergies:
		if not SYN_TAGS.has(syn_id) or not SYN_COLORS.has(syn_id):
			continue
		var needed: Array = SYN_TAGS[syn_id]
		for need: String in needed:
			if tags.has(need):
				active_colors.append(SYN_COLORS[syn_id] as Color)
				break
	if active_colors.is_empty():
		return

	var cx: float = (t.pos.x + t.sz.x * 0.5) * CELL
	var cy: float = (t.pos.y + t.sz.y * 0.5) * CELL
	var center := Vector2(cx, cy)
	var r: float = (maxi(t.sz.x, t.sz.y) * CELL) * 0.5 + 5.0
	var n := active_colors.size()
	var arc_span: float = TAU / n * 0.80   # 80% fill, 20% gap
	for i in n:
		var col: Color = active_colors[i]
		var start: float = _syn_ring_angle + i * (TAU / n)
		# Glow halo (wider, dimmer)
		draw_arc(center, r + 2.0, start, start + arc_span, 32,
			Color(col.r, col.g, col.b, 0.30), 3.0)
		# Sharp ring
		draw_arc(center, r, start, start + arc_span, 32,
			Color(col.r, col.g, col.b, 0.90), 2.0)


func _draw_bg() -> void:
	var vp := get_viewport_rect().size
	draw_rect(Rect2(0, -GRID_TOP, vp.x, vp.y), COL_BG)
	if not _floor_tex:
		return

	# 9-slice stengolv — tile-storlek 16×16 i floor_tiles.png (128×128, 8×8 tiles)
	# Rad 0 = ljus stenkant, rad 1-4 = mörkt tegel, rad 5 = nederkant
	# Kolumn 0/7 = sidokant, kolumner 1-6 = interiör
	for row in range(ROWS):
		for col in range(COLS):
			var dst := Rect2(col * CELL, row * CELL, CELL, CELL)
			var src: Rect2
			var is_top    := row == 0
			var is_bot    := row == ROWS - 1
			var is_left   := col == 0
			var is_right  := col == COLS - 1
			if is_top:
				var tx := 112 if is_right else (0 if is_left else 16)
				src = Rect2(tx, 0, 16, 16)
			elif is_bot:
				var tx := 112 if is_right else (0 if is_left else 16)
				src = Rect2(tx, 80, 16, 16)
			elif is_left:
				src = Rect2(0, 16 + (hash(row * 13) % 4) * 16, 16, 16)
			elif is_right:
				src = Rect2(112, 16 + (hash(row * 17) % 4) * 16, 16, 16)
			else:
				# Interiör: variera bland 24 innertiles (rad 1-4, kol 1-6)
				var hi := hash(row * 97 + col * 31)
				var ix := 1 + (hi % 6)
				var iy := 1 + ((hi / 6) % 4)
				src = Rect2(ix * 16, iy * 16, 16, 16)
			draw_texture_rect_region(_floor_tex, dst, src, Color(0.35, 0.30, 0.28))


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
	var half := CELL * 0.5
	for path in GameState.current_paths:
		if path.size() < 2:
			continue
		for i in range(path.size() - 1):
			var a: Vector2i = path[i]
			var b: Vector2i = path[i + 1]
			draw_line(
				Vector2((a.x + 0.5) * half, (a.y + 0.5) * half),
				Vector2((b.x + 0.5) * half, (b.y + 0.5) * half),
				COL_PATH, 1.5)


func _draw_entry_exit() -> void:
	for entry in Pathfinder.map_entries:
		_draw_entry_gate(entry.x, entry.y)
	var ep := Pathfinder.map_exit_point
	_draw_exit_base(ep.x, ep.y)


func _draw_entry_gate(col: int, row: int) -> void:
	var x := float(col * CELL)
	var y := float(row * CELL)
	var c := float(CELL)
	draw_rect(Rect2(x + 1, y + 1, c - 2, c - 2), Color(0.04, 0.18, 0.04))
	draw_rect(Rect2(x + 1, y + 1, c - 2, c - 2), Color(0.20, 0.90, 0.20), false, 1.5)
	# Downward arrow ▼
	var cx := x + c * 0.5
	var cy := y + c * 0.5
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx,             cy + c * 0.28),
		Vector2(cx - c * 0.22, cy - c * 0.14),
		Vector2(cx + c * 0.22, cy - c * 0.14),
	]), Color(0.20, 0.90, 0.20))


func _draw_exit_base(col: int, row: int) -> void:
	var x := float(col * CELL)
	var y := float(row * CELL)
	var c := float(CELL)
	# Background — dark warm stone
	draw_rect(Rect2(x + 1, y + 1, c - 2, c - 2), Color(0.13, 0.10, 0.06))
	# Outer gold border (2px)
	draw_rect(Rect2(x + 1, y + 1, c - 2, c - 2), Color(0.88, 0.68, 0.18), false, 2.0)
	# Battlements — 3 notches across the top
	for i in range(3):
		draw_rect(Rect2(x + 4.0 + i * 7.5, y + 1.0, 4.5, 4.0), Color(0.88, 0.68, 0.18))
	# Central tower body
	var tw := c * 0.44
	var th := c * 0.44
	var tx := x + c * 0.5 - tw * 0.5
	var ty := y + c * 0.30
	draw_rect(Rect2(tx, ty, tw, th), Color(0.19, 0.15, 0.09))
	draw_rect(Rect2(tx, ty, tw, th), Color(0.88, 0.68, 0.18), false, 1.0)
	# Gate opening (dark arch at tower bottom)
	var gw := tw * 0.46
	var gh := th * 0.52
	draw_rect(Rect2(tx + tw * 0.5 - gw * 0.5, ty + th - gh, gw, gh), Color(0.04, 0.03, 0.02))


func _draw_marker(col: int, row: int, label: String, stroke: Color, fill: Color) -> void:
	var r := Rect2(col * CELL + 1, row * CELL + 1, CELL - 2, CELL - 2)
	draw_rect(r, fill)
	draw_rect(r, stroke, false, 1.0)
	draw_string(_font,
		Vector2((col + 0.5) * CELL - 5, (row + 0.7) * CELL),
		label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, stroke)


# ── Tower shape helpers ──────────────────────────────────────

func _tpoly(cx: float, cy: float, r: float, n: int, a0: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := a0 + TAU * i / n
		pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
	return pts


func _tstar(cx: float, cy: float, r_out: float, r_in: float,
		n: int, a0: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n * 2:
		var a := a0 + TAU * i / (n * 2)
		var rv := r_out if i % 2 == 0 else r_in
		pts.append(Vector2(cx + cos(a) * rv, cy + sin(a) * rv))
	return pts


func _tfill(n: int, c: Color) -> PackedColorArray:
	var arr := PackedColorArray()
	arr.resize(n)
	arr.fill(c)
	return arr


func _tdraw(pts: PackedVector2Array, fill: Color, stroke: Color, w: float = 1.5) -> void:
	draw_polygon(pts, _tfill(pts.size(), fill))
	var closed := pts + PackedVector2Array([pts[0]])
	draw_polyline(closed, stroke, w)


func _draw_tower(pos: Vector2, sz: Vector2i, type: int, alpha: float) -> void:
	var px := pos.x * CELL
	var py := pos.y * CELL
	var pw := sz.x  * CELL
	var ph := sz.y  * CELL
	var cx := px + pw * 0.5
	var cy := py + ph * 0.5
	var fill:   Color = TowerDefs.FILL[type];   fill.a = alpha
	var stroke: Color = TowerDefs.STROKE[type]; stroke.a = alpha
	var r := CELL * 0.40

	match type:
		0:  # Destroyer — flying disc
			draw_circle(Vector2(cx, cy), r, fill)
			draw_arc(Vector2(cx, cy), r, 0.0, TAU, 48, stroke, 1.5)
			draw_line(Vector2(cx - r, cy), Vector2(cx + r, cy), stroke, 1.0)

		1:  # Buzzz — disc med inre ring
			draw_circle(Vector2(cx, cy), r, fill)
			draw_arc(Vector2(cx, cy), r, 0.0, TAU, 48, stroke, 1.5)
			draw_arc(Vector2(cx, cy), r * 0.52, 0.0, TAU, 32, stroke, 1.0)

		2:  # Aviar — putter, kompakt kvadrat
			var ar := r * 0.75
			_tdraw(PackedVector2Array([
				Vector2(cx - ar, cy - ar), Vector2(cx + ar, cy - ar),
				Vector2(cx + ar, cy + ar), Vector2(cx - ar, cy + ar),
			]), fill, stroke, 2.0)
			draw_circle(Vector2(cx, cy), ar * 0.28, stroke)

		3:  # Hatchet — yxform
			_tdraw(PackedVector2Array([
				Vector2(cx,          cy - r),
				Vector2(cx + r*0.7,  cy - r*0.2),
				Vector2(cx + r*0.5,  cy + r*0.6),
				Vector2(cx - r*0.5,  cy + r*0.6),
				Vector2(cx - r*0.7,  cy - r*0.2),
			]), fill, stroke)

		4:  # Pure — smal aerodynamisk diamant
			_tdraw(PackedVector2Array([
				Vector2(cx,          cy - r),
				Vector2(cx + r*0.35, cy),
				Vector2(cx,          cy + r),
				Vector2(cx - r*0.35, cy),
			]), fill, stroke)

		5:  # Gjutjärnspannan — cirkel + handtag
			draw_circle(Vector2(cx - r*0.1, cy), r * 0.78, fill)
			draw_arc(Vector2(cx - r*0.1, cy), r * 0.78, 0.0, TAU, 48, stroke, 1.5)
			_tdraw(PackedVector2Array([
				Vector2(cx + r*0.65, cy - r*0.15),
				Vector2(cx + r*1.10, cy - r*0.15),
				Vector2(cx + r*1.10, cy + r*0.15),
				Vector2(cx + r*0.65, cy + r*0.15),
			]), fill, stroke, 1.5)

		6:  # Sous Vide — avlång rektangel (vakuumpåse)
			_tdraw(PackedVector2Array([
				Vector2(cx - r*0.55, cy - r*0.90),
				Vector2(cx + r*0.55, cy - r*0.90),
				Vector2(cx + r*0.55, cy + r*0.90),
				Vector2(cx - r*0.55, cy + r*0.90),
			]), fill, stroke)
			draw_line(Vector2(cx - r*0.35, cy - r*0.55),
					  Vector2(cx + r*0.35, cy - r*0.55), stroke, 1.0)

		7:  # Woken — wok-form (halvcirkel)
			var wp := PackedVector2Array()
			for wi in 14:
				var wa := PI + PI * wi / 13.0
				wp.append(Vector2(cx + cos(wa) * r, cy + sin(wa) * r * 0.7))
			wp.append(Vector2(cx + r, cy))
			wp.append(Vector2(cx - r, cy))
			_tdraw(wp, fill, stroke)

		8:  # Morteln — U-form
			var mp := PackedVector2Array()
			for mi in 10:
				var ma := PI + PI * mi / 9.0
				mp.append(Vector2(cx + cos(ma) * r * 0.85, cy + sin(ma) * r * 0.75))
			mp.append(Vector2(cx + r * 0.85, cy - r * 0.1))
			mp.append(Vector2(cx - r * 0.85, cy - r * 0.1))
			_tdraw(mp, fill, stroke)
			draw_line(Vector2(cx - r, cy - r * 0.1),
					  Vector2(cx + r, cy - r * 0.1), stroke, 1.5)

		9:  # Göteborgs Rapé — rund snusdosa
			draw_circle(Vector2(cx, cy), r, fill)
			draw_arc(Vector2(cx, cy), r, 0.0, TAU, 48, stroke, 1.5)
			draw_arc(Vector2(cx, cy), r * 0.65, 0.0, TAU, 32, stroke, 0.8)
			draw_circle(Vector2(cx, cy), r * 0.12, stroke)

		10: # General White — oktagon
			_tdraw(_tpoly(cx, cy, r, 8, PI / 8.0), fill, stroke)
			draw_circle(Vector2(cx, cy), r * 0.22, stroke)

		11: # Oden's Extreme — pentagonstjärna
			_tdraw(_tstar(cx, cy, r, r * 0.42, 5, -PI / 2.0), fill, stroke, 2.0)

		12: # Siberia — tjock diamant
			_tdraw(_tpoly(cx, cy, r, 4, 0.0), fill, stroke, 2.5)
			_tdraw(_tpoly(cx, cy, r * 0.50, 4, 0.0), stroke, stroke, 1.5)

		13: # Ristretto — espressokopp
			_tdraw(PackedVector2Array([
				Vector2(cx - r*0.50, cy - r*0.55),
				Vector2(cx + r*0.50, cy - r*0.55),
				Vector2(cx + r*0.50, cy + r*0.30),
				Vector2(cx - r*0.50, cy + r*0.30),
			]), fill, stroke, 2.0)
			draw_line(Vector2(cx - r*0.70, cy + r*0.30),
					  Vector2(cx + r*0.70, cy + r*0.30), stroke, 1.5)

		14: # Cold Brew — långt glas
			_tdraw(PackedVector2Array([
				Vector2(cx - r*0.40, cy - r*0.95),
				Vector2(cx + r*0.40, cy - r*0.95),
				Vector2(cx + r*0.40, cy + r*0.95),
				Vector2(cx - r*0.40, cy + r*0.95),
			]), fill, stroke)
			draw_line(Vector2(cx - r*0.40, cy + r*0.20),
					  Vector2(cx + r*0.40, cy + r*0.20), stroke, 0.8)

		15: # Chemex — timglasform
			_tdraw(PackedVector2Array([
				Vector2(cx - r*0.70, cy - r*0.95),
				Vector2(cx + r*0.70, cy - r*0.95),
				Vector2(cx + r*0.20, cy - r*0.05),
				Vector2(cx + r*0.55, cy + r*0.95),
				Vector2(cx - r*0.55, cy + r*0.95),
				Vector2(cx - r*0.20, cy - r*0.05),
			]), fill, stroke)

		16: # Ernie Ball — strängspole (hexagon)
			_tdraw(_tpoly(cx, cy, r, 6, 0.0), fill, stroke)
			for ei in 3:
				var ea := TAU * ei / 3.0
				draw_line(Vector2(cx, cy),
					Vector2(cx + cos(ea) * r * 0.80, cy + sin(ea) * r * 0.80),
					stroke, 1.0)

		17: # Tube Screamer — pedalform
			_tdraw(PackedVector2Array([
				Vector2(cx - r*0.65, cy - r*0.80),
				Vector2(cx + r*0.65, cy - r*0.80),
				Vector2(cx + r*0.80, cy - r*0.30),
				Vector2(cx + r*0.80, cy + r*0.80),
				Vector2(cx - r*0.80, cy + r*0.80),
				Vector2(cx - r*0.80, cy - r*0.30),
			]), fill, stroke)
			draw_circle(Vector2(cx, cy - r*0.20), r * 0.25, stroke)

		18: # Roundhouse — kickcirkel
			var rp := PackedVector2Array()
			for ri in 20:
				var ra := -PI * 0.1 + TAU * 0.65 * ri / 19.0
				rp.append(Vector2(cx + cos(ra) * r, cy + sin(ra) * r))
			rp.append(Vector2(cx, cy))
			_tdraw(rp, fill, stroke)

		19: # Elbow — skarp triangel
			_tdraw(PackedVector2Array([
				Vector2(cx,      cy - r),
				Vector2(cx + r,  cy + r * 0.70),
				Vector2(cx,      cy + r * 0.20),
				Vector2(cx - r,  cy + r * 0.70),
			]), fill, stroke, 2.0)

		20: # Hot Stone — oregelbunden sten
			_tdraw(PackedVector2Array([
				Vector2(cx - r*0.30, cy - r*0.90),
				Vector2(cx + r*0.55, cy - r*0.65),
				Vector2(cx + r*0.90, cy + r*0.20),
				Vector2(cx + r*0.20, cy + r*0.90),
				Vector2(cx - r*0.80, cy + r*0.50),
				Vector2(cx - r*0.85, cy - r*0.30),
			]), fill, stroke)

		_:  # fallback
			draw_rect(Rect2(px + 1, py + 1, pw - 2, ph - 2), fill)
			draw_rect(Rect2(px + 1, py + 1, pw - 2, ph - 2), stroke, false, 1.5)


func _draw_enemy(e: Dictionary) -> void:
	var is_boss:   bool  = e.get("is_boss",   false)
	var is_flying: bool  = e.get("flying",    false)
	var flash_t:   float = minf(1.0, e.get("hit_flash", 0.0) / 0.15)

	if is_flying:
		var r:   float = 12.0 if is_boss else 7.0
		var col: Color = Color(1.0, 0.45, 0.1) if is_boss else Color(0.25, 0.55, 1.0)
		if flash_t > 0.0:
			col = col.lerp(Color.WHITE, flash_t)
		draw_colored_polygon(PackedVector2Array([
			e.pos + Vector2(0.0,  -r * 1.4),
			e.pos + Vector2(r,     0.0),
			e.pos + Vector2(0.0,   r * 0.9),
			e.pos + Vector2(-r,    0.0),
		]), col)
		var bar_w: float = r * 3.2
		var bx:    float = e.pos.x - bar_w * 0.5
		var by_:   float = e.pos.y - r * 1.4 - 5.0
		draw_rect(Rect2(bx, by_, bar_w, 3.0), COL_HP_BG)
		draw_rect(Rect2(bx, by_, bar_w * (e.hp / e.max_hp), 3.0), COL_HP_FG)
	else:
		var r:   float = 110.0 if is_boss else 80.0
		var sz:  float = r * 2.0
		var mod: Color = Color.WHITE if flash_t <= 0.0 else Color.WHITE.lerp(Color(3.0, 3.0, 3.0), flash_t)
		var dst := Rect2(e.pos.x - r, e.pos.y - r, sz, sz)

		if _orc_walk_tex:
			var frame := int(Time.get_ticks_msec() / 1000.0 * 8.0) % 8
			var src   := Rect2(frame * 100, 0, 100, 100)
			if e.get("face_right", true):
				draw_texture_rect_region(_orc_walk_tex, dst, src, mod)
			else:
				draw_set_transform(Vector2(e.pos.x * 2.0, 0.0), 0.0, Vector2(-1.0, 1.0))
				draw_texture_rect_region(_orc_walk_tex, dst, src, mod)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			var col: Color = COL_ENEMY
			if flash_t > 0.0:
				col = col.lerp(Color.WHITE, flash_t)
			draw_circle(e.pos, r, col)

		var bar_w: float = 28.0
		var bx:    float = e.pos.x - bar_w * 0.5
		var by_:   float = e.pos.y - r * 0.55
		draw_rect(Rect2(bx, by_, bar_w, 3.0), COL_HP_BG)
		draw_rect(Rect2(bx, by_, bar_w * (e.hp / e.max_hp), 3.0), COL_HP_FG)

	# Slow-indikator — blå ring
	if e.get("slow_t", 0.0) > 0.0:
		var sr: float = 14.0 if e.get("is_boss", false) else 9.0
		draw_arc(e.pos, sr, 0.0, TAU, 16, Color(0.40, 0.65, 1.00, 0.70), 1.5)

	# DoT-indikator — orange ring
	if e.get("dot_t", 0.0) > 0.0:
		var dr: float = 12.0 if e.get("is_boss", false) else 8.0
		draw_arc(e.pos, dr, 0.0, TAU, 16, Color(1.00, 0.55, 0.15, 0.70), 1.5)
