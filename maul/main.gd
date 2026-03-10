extends Node2D

# ============================================================
# Layout & visual constants
# ============================================================

const COLS       := 16
const ROWS       := 22
const CELL       := 30
const VIEWPORT_W := 640
const VIEWPORT_H := 660

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

const PROJ_SPEED := 180.0

# ============================================================
# Nodes
# ============================================================

var _hud:       HUD
var _font:      Font
var _sfx_shoot: AudioStreamPlayer

# ============================================================
# Ready
# ============================================================

func _ready() -> void:
	get_window().size     = Vector2i(VIEWPORT_W, VIEWPORT_H)
	get_window().min_size = Vector2i(VIEWPORT_W, VIEWPORT_H)
	_font = ThemeDB.fallback_font

	_sfx_shoot = AudioStreamPlayer.new()
	_sfx_shoot.stream = load("res://assets/39459__the_bizniss__laser.wav")
	_sfx_shoot.volume_db = -6.0
	add_child(_sfx_shoot)

	_hud = HUD.new()
	_hud.tower_selected.connect(_select_tower)
	_hud.start_wave_pressed.connect(_on_send_early)
	_hud.difficulty_set.connect(_set_difficulty)
	_hud.clear_all_pressed.connect(_on_clear_all)
	add_child(_hud)

	Pathfinder.rebuild(CELL)

# ============================================================
# Input
# ============================================================

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not event.pressed:
		_handle_tap(event.position)
		queue_redraw()
		return

	if event is InputEventMouseMotion:
		if GameState.placing:
			GameState.hover_pos   = _snap(event.position)
			GameState.hover_valid = _can_place(GameState.hover_pos, TowerDefs.SIZES[GameState.selected])
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

	if not hit.is_empty():
		GameState.set_inspected(hit)
		_exit_placement()
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
		GameState.set_inspected({})
		Pathfinder.rebuild(CELL)
		_exit_placement()

# ============================================================
# UI callbacks
# ============================================================

func _set_difficulty(idx: int) -> void:
	if GameState.game_started:
		return
	GameState.difficulty = idx
	GameState.max_escape = [100, 50, 0][idx]
	GameState.escaped_changed.emit(GameState.escaped, GameState.max_escape)


func _on_send_early() -> void:
	if GameState.game_over:
		GameState.reset()
		Pathfinder.rebuild(CELL)
		queue_redraw()
		return
	if GameState.wave_in_progress or GameState.current_path.is_empty():
		return
	GameState.wave_countdown = 0.0


func _on_clear_all() -> void:
	if GameState.wave_in_progress:
		return
	var refund: int = 0
	for t in GameState.towers:
		refund += int(TowerDefs.COST[t.type] * 0.75)
	if refund > 0:
		GameState.add_gold(refund)
	GameState.towers.clear()
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
	if _overlap(pos.x, pos.y, sz.x, sz.y, Pathfinder.ENTRY.x, Pathfinder.ENTRY.y, 1, 1):
		return false
	if _overlap(pos.x, pos.y, sz.x, sz.y, Pathfinder.EXIT.x, Pathfinder.EXIT.y, 1, 1):
		return false
	for t in GameState.towers:
		if _overlap(pos.x, pos.y, sz.x, sz.y, t.pos.x, t.pos.y, t.sz.x, t.sz.y):
			return false
	if Pathfinder.bfs(Pathfinder.build_blocked(pos, sz)).is_empty():
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
		if GameState.wave_countdown <= 0.0 and not GameState.current_path.is_empty():
			WaveManager.start()
		queue_redraw()
		return

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

	GameState.enemies     = GameState.enemies.filter(func(e:  Dictionary) -> bool: return not e.dead)
	GameState.projectiles = GameState.projectiles.filter(func(p:  Dictionary) -> bool: return not p.spent)
	GameState.explosions  = GameState.explosions.filter(func(ex: Dictionary) -> bool: return ex.timer > 0.0)
	GameState.particles   = GameState.particles.filter(func(pt: Dictionary) -> bool: return pt.timer > 0.0)
	GameState.floats      = GameState.floats.filter(func(f:  Dictionary) -> bool: return f.timer  > 0.0)


func _check_wave_end() -> void:
	if not GameState.game_over and GameState.escaped > GameState.max_escape:
		GameState.game_over        = true
		GameState.wave_in_progress = false
		GameState.game_over_triggered.emit()
		return

	if not GameState.game_over \
			and GameState.wave_spawn_queue.is_empty() \
			and GameState.enemies.is_empty():
		GameState.wave_in_progress = false
		GameState.wave_countdown   = GameState.WAVE_INTERVAL
		var bonus: int = WaveDefs.get_wave(GameState.wave).bonus
		GameState.add_gold(bonus)
		GameState.wave_completed.emit(GameState.wave, bonus)
		_show_wave_complete_status(bonus)


func _show_wave_complete_status(bonus: int) -> void:
	_hud.show_status("Wave %d klar! +%dg" % [GameState.wave, bonus])
	await get_tree().create_timer(2.5).timeout
	_hud.show_status("")

# ============================================================
# Simulation — enemies
# ============================================================

func _tick_enemies(delta: float) -> void:
	for e in GameState.enemies:
		if e.dead:
			continue
		if e.hit_flash > 0.0:
			e.hit_flash = maxf(0.0, e.hit_flash - delta)

		if e.flying:
			var fdiff: Vector2 = e.goal - e.pos
			var fdist: float   = fdiff.length()
			var fmove: float   = e.speed * delta
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
		var move:   float    = e.speed * delta

		if dist <= move:
			e.pos     = target
			e.wp_idx += 1
		else:
			e.pos += diff.normalized() * move


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
			if nearest.get("flying", false):
				dmg *= TowerDefs.AIR_MULT[t.type]
			GameState.projectiles.append({
				pos       = tc,
				target    = nearest,
				speed     = PROJ_SPEED,
				damage    = dmg,
				color     = TowerDefs.STROKE[t.type],
				aoe       = TowerDefs.AOE[t.type],
				splash_px = TowerDefs.SPLASH[t.type] * CELL,
				spent     = false,
			})
			t.cooldown = 1.0 / TowerDefs.FIRERATE[t.type]
			_sfx_shoot.play()


func _tick_projectiles(delta: float) -> void:
	var creep_gold: int = WaveDefs.get_wave(GameState.wave).bounty
	for p in GameState.projectiles:
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
				GameState.explosions.append({ pos = p.target.pos, radius = p.splash_px, timer = 0.25 })
				for e in GameState.enemies:
					if e.dead: continue
					if p.target.pos.distance_to(e.pos) <= p.splash_px:
						_apply_damage(e, p.damage, creep_gold)
			else:
				_apply_damage(p.target, p.damage, creep_gold)
			p.spent = true
		else:
			p.pos += diff.normalized() * move


func _apply_damage(e: Dictionary, damage: float, creep_gold: int) -> void:
	e.hp -= damage
	if e.hp <= 0.0:
		e.hp   = 0.0
		e.dead = true
		var kg: int = creep_gold
		GameState.add_gold(kg)
		WaveManager.spawn_death_fx(e.pos, e.get("flying", false), e.get("is_boss", false), kg)
	else:
		e.hit_flash = 0.15

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

	for e in GameState.enemies:
		if not e.dead:
			_draw_enemy(e)

	for p in GameState.projectiles:
		if not p.spent:
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
		var hc := Vector2(
			(GameState.hover_pos.x + TowerDefs.SIZES[GameState.selected].x * 0.5) * CELL,
			(GameState.hover_pos.y + TowerDefs.SIZES[GameState.selected].y * 0.5) * CELL)
		draw_arc(hc, TowerDefs.RANGE[GameState.selected] * CELL,
			0.0, TAU, 64, Color(1.0, 1.0, 0.0, 0.20), 1.0)
		_draw_tower(GameState.hover_pos, TowerDefs.SIZES[GameState.selected],
			GameState.selected, 0.5 if GameState.hover_valid else 0.2)
		if not GameState.hover_valid:
			draw_rect(
				Rect2(GameState.hover_pos.x * CELL + 1, GameState.hover_pos.y * CELL + 1,
					TowerDefs.SIZES[GameState.selected].x * CELL - 2,
					TowerDefs.SIZES[GameState.selected].y * CELL - 2),
				COL_INVALID, false, 1.5)


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
	if GameState.current_path.size() < 2:
		return
	var half := CELL * 0.5
	for i in range(GameState.current_path.size() - 1):
		var a: Vector2i = GameState.current_path[i]
		var b: Vector2i = GameState.current_path[i + 1]
		draw_line(
			Vector2((a.x + 0.5) * half, (a.y + 0.5) * half),
			Vector2((b.x + 0.5) * half, (b.y + 0.5) * half),
			COL_PATH, 1.5)


func _draw_entry_exit() -> void:
	_draw_marker(Pathfinder.ENTRY.x, Pathfinder.ENTRY.y, "IN",  COL_ENTRY, Color(0.05, 0.20, 0.05))
	_draw_marker(Pathfinder.EXIT.x,  Pathfinder.EXIT.y,  "OUT", COL_EXIT,  Color(0.20, 0.05, 0.05))


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
	var pw := sz.x  * CELL
	var ph := sz.y  * CELL
	var fill:   Color = TowerDefs.FILL[type];   fill.a   = alpha
	var stroke: Color = TowerDefs.STROKE[type]; stroke.a = alpha
	draw_rect(Rect2(px + 1, py + 1, pw - 2, ph - 2), fill)
	draw_rect(Rect2(px + 1, py + 1, pw - 2, ph - 2), stroke, false, 1.0)
	var fs := int(minf(pw, ph) * 0.38)
	draw_string(_font,
		Vector2(px + pw * 0.5 - fs * 0.3, py + ph * 0.5 + fs * 0.4),
		TowerDefs.NAMES[type].substr(0, 1),
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
		var radius: float = 12.0 if is_boss else 7.0
		var col:    Color = COL_ENEMY
		if flash_t > 0.0:
			col = col.lerp(Color.WHITE, flash_t)
		draw_circle(e.pos, radius, col)
		var bar_w: float = radius * 3.0
		var bx:    float = e.pos.x - bar_w * 0.5
		var by_:   float = e.pos.y - radius - 5.0
		draw_rect(Rect2(bx, by_, bar_w, 3.0), COL_HP_BG)
		draw_rect(Rect2(bx, by_, bar_w * (e.hp / e.max_hp), 3.0), COL_HP_FG)
