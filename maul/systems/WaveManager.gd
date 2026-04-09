class_name WaveManager

const SPAWN_INTERVAL := 0.50

# ============================================================
# Wave lifecycle
# ============================================================

static func start() -> void:
	GameState.wave            += 1
	GameState.spawn_timer      = 0.0
	GameState.wave_in_progress = true
	GameState.game_started     = true
	GameState.wave_kills       = 0

	GameState.wave_spawn_queue.clear()
	var wd := WaveDefs.get_wave(GameState.wave)

	var is_boss_wave: bool = (wd.special == WaveDefs.SPECIAL_BOSS
		or wd.special == WaveDefs.SPECIAL_FINAL_BOSS)

	var etype: int
	if wd.flies and is_boss_wave:
		etype = 3  # flying boss
	elif wd.flies:
		etype = 1  # flying
	elif is_boss_wave:
		etype = 2  # ground boss
	else:
		etype = 0  # ground

	var num_entries: int = Pathfinder.map_entries.size()
	for i in wd.count:
		GameState.wave_spawn_queue.append({
			"etype":     etype,
			"entry_idx": i % num_entries,
		})

	var banner: String
	match wd.special:
		WaveDefs.SPECIAL_FINAL_BOSS:
			banner = "WAVE %d  —  %s  —  FINAL BOSS" % [GameState.wave, wd.name.to_upper()]
		WaveDefs.SPECIAL_BOSS:
			banner = "WAVE %d  —  %s  —  BOSS" % [GameState.wave, wd.name.to_upper()]
		WaveDefs.SPECIAL_MASS:
			banner = "WAVE %d  —  %s  —  SWARM" % [GameState.wave, wd.name]
		WaveDefs.SPECIAL_MAGIC_IMMUNE:
			banner = "WAVE %d  —  %s  —  MAGIC IMMUNE" % [GameState.wave, wd.name]
		WaveDefs.SPECIAL_INVISIBLE:
			banner = "WAVE %d  —  %s  —  INVISIBLE" % [GameState.wave, wd.name]
		_:
			if wd.flies:
				banner = "WAVE %d  —  %s  —  AIR WAVE" % [GameState.wave, wd.name]
			else:
				banner = "WAVE %d  —  %s" % [GameState.wave, wd.name]

	GameState.wave_banner_text  = banner
	GameState.wave_banner_timer = 2.5
	GameState.wave_started.emit(GameState.wave, banner)


static func tick_spawner(delta: float, cell: int) -> void:
	if GameState.wave_spawn_queue.is_empty():
		return
	GameState.spawn_timer -= delta
	if GameState.spawn_timer <= 0.0:
		_spawn_enemy(GameState.wave_spawn_queue.pop_front(), cell)
		GameState.spawn_timer = SPAWN_INTERVAL

# ============================================================
# Visual effects (called from main after kill)
# ============================================================

static func spawn_death_fx(pos: Vector2, flying: bool, is_boss: bool, gold_gained: int) -> void:
	var col: Color
	if is_boss:
		col = Color(1.0, 0.45, 0.1)
	elif flying:
		col = Color(0.25, 0.55, 1.0)
	else:
		col = Color(0.85, 0.20, 0.20)

	var count: int = 8 if is_boss else 5
	for i in count:
		var angle: float = (float(i) / float(count)) * TAU + randf() * 0.5
		var spd:   float = randf_range(35.0, 90.0)
		GameState.particles.append({
			pos       = pos,
			vel       = Vector2(cos(angle), sin(angle)) * spd,
			color     = col,
			timer     = randf_range(0.25, 0.55),
			max_timer = 0.5,
		})

	GameState.floats.append({
		pos       = pos + Vector2(0.0, -12.0),
		text      = "+%dg" % gold_gained,
		color     = Color(1.0, 0.92, 0.25),
		timer     = 1.1,
		max_timer = 1.1,
	})

# ============================================================
# Private
# ============================================================

static func _spawn_enemy(item: Dictionary, cell: int) -> void:
	var wd       := WaveDefs.get_wave(GameState.wave)
	var etype:    int   = item.get("etype", 0)
	var entry_idx: int  = item.get("entry_idx", 0)
	var speed:    float = wd.speed
	var hp:       float = wd.hp
	var is_boss:  bool  = (etype == 2 or etype == 3)
	var flying:   bool  = (etype == 1 or etype == 3)
	var armor:    int   = int(wd.armor)
	var special:  int   = int(wd.special)

	var entry    := Pathfinder.map_entries[entry_idx]
	var entry_px := Vector2((entry.x + 0.5) * cell, (entry.y + 0.5) * cell)
	var exit_px  := Vector2((Pathfinder.map_exit_point.x + 0.5) * cell,
							(Pathfinder.map_exit_point.y + 0.5) * cell)

	if flying:
		GameState.enemies.append({
			pos           = entry_px,
			goal          = exit_px,
			flying        = true,
			is_boss       = is_boss,
			hp            = hp,
			max_hp        = hp,
			armor         = armor,
			special       = special,
			speed         = speed,
			hit_flash     = 0.0,
			dead          = false,
			path_entry_idx = entry_idx,
		})
	else:
		var path: Array = GameState.current_paths[entry_idx] \
			if entry_idx < GameState.current_paths.size() else GameState.current_path
		if path.is_empty():
			return
		var waypoints := Pathfinder.path_to_pixels(path, cell)
		GameState.enemies.append({
			pos            = waypoints[0],
			waypoints      = waypoints,
			wp_idx         = 0,
			flying         = false,
			is_boss        = is_boss,
			hp             = hp,
			max_hp         = hp,
			armor          = armor,
			special        = special,
			speed          = speed,
			hit_flash      = 0.0,
			dead           = false,
			face_right     = true,
			path_entry_idx = entry_idx,
		})
