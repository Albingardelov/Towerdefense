class_name Pathfinder

const COLS  := 16
const SCOLS := COLS * 2

static var ROWS:  int      = 22
static var SROWS: int      = ROWS * 2
static var EXIT:  Vector2i = Vector2i(8, ROWS - 1)

const ENTRY := Vector2i(8, 0)

# Map configuration — set by main.gd before rebuild()
static var map_mode:       int            = 0   # 0 = classic, 1 = mandala
static var map_entries:    Array[Vector2i] = []
static var map_exit_point: Vector2i       = Vector2i(8, 21)

# ============================================================
# Public API
# ============================================================

static func build_blocked(extra_pos := Vector2(-1, -1),
		extra_sz := Vector2i(0, 0)) -> PackedByteArray:
	var blocked := PackedByteArray()
	blocked.resize(SCOLS * SROWS)
	blocked.fill(0)
	for t in GameState.towers:
		_block_rect(blocked, t.pos, t.sz)
	if extra_sz.x > 0:
		_block_rect(blocked, extra_pos, extra_sz)
	return blocked


# Classic single-path BFS (kept for backward compat)
static func bfs(blocked: PackedByteArray) -> Array:
	return bfs_path(ENTRY, EXIT, blocked)


# Parameterized BFS from any entry to any exit
static func bfs_path(entry: Vector2i, exit_p: Vector2i,
		blocked: PackedByteArray) -> Array:
	var queue: Array[Vector2i] = []
	var came_from := {}

	for dy in range(2):
		for dx in range(2):
			var s := Vector2i(entry.x * 2 + dx, entry.y * 2 + dy)
			if blocked[s.y * SCOLS + s.x] == 0 and not came_from.has(s):
				came_from[s] = Vector2i(-1, -1)
				queue.append(s)

	if queue.is_empty():
		return []

	var base_dirs := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	var goal      := Vector2i(-1, -1)
	var ex0       := exit_p.x * 2
	var ey0       := exit_p.y * 2
	var head      := 0
	var goal_sub  := Vector2i(exit_p.x * 2 + 1, exit_p.y * 2 + 1)

	while head < queue.size():
		var cur: Vector2i = queue[head]
		head += 1
		if cur.x >= ex0 and cur.x <= ex0 + 1 and cur.y >= ey0 and cur.y <= ey0 + 1:
			goal = cur
			break
		# Tie-breaking: utforska riktningar som rör sig mot målet först
		var dirs := base_dirs.duplicate()
		dirs.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			var da := (cur + a - goal_sub).length_squared()
			var db := (cur + b - goal_sub).length_squared()
			return da < db)
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


static func path_to_pixels(path: Array, cell: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	var half   := float(cell) * 0.5
	if path.is_empty():
		return result

	var raw: Array[Vector2] = []
	for p: Vector2i in path:
		raw.append(Vector2((p.x + 0.5) * half, (p.y + 0.5) * half))

	if raw.size() <= 2:
		for v in raw:
			result.append(v)
		return result

	# Path smoothing: behåll bara hörn (riktningsbyten), ta bort collineära mellanpunkter
	result.append(raw[0])
	for i in range(1, raw.size() - 1):
		var d1 := (raw[i] - raw[i - 1]).normalized()
		var d2 := (raw[i + 1] - raw[i]).normalized()
		if not d1.is_equal_approx(d2):
			result.append(raw[i])
	result.append(raw[raw.size() - 1])
	return result


static func rebuild(cell: int) -> void:
	if map_mode == 1:
		_rebuild_mandala(cell)
	else:
		_rebuild_classic(cell)

# ============================================================
# Private
# ============================================================

static func _rebuild_classic(cell: int) -> void:
	var blocked := build_blocked()
	GameState.current_path  = bfs(blocked)
	GameState.current_paths = [GameState.current_path]
	if GameState.current_path.is_empty():
		return
	var new_waypoints := path_to_pixels(GameState.current_path, cell)
	_reroute_enemy_group(-1, new_waypoints, blocked, cell)


static func _rebuild_mandala(cell: int) -> void:
	var blocked := build_blocked()
	GameState.current_paths.clear()
	var all_valid := true
	for entry in map_entries:
		var path := bfs_path(entry, map_exit_point, blocked)
		GameState.current_paths.append(path)
		if path.is_empty():
			all_valid = false
	# current_path = first path only if ALL paths are valid (controls wave start)
	GameState.current_path = GameState.current_paths[0] if all_valid else []
	# Reroute each enemy group by their entry corner
	for i in GameState.current_paths.size():
		if GameState.current_paths[i].is_empty():
			continue
		var new_wp := path_to_pixels(GameState.current_paths[i], cell)
		_reroute_enemy_group(i, new_wp, blocked, cell)


# Reroutes enemies that belong to a given entry group.
# entry_idx == -1 means classic mode (all ground enemies).
static func _reroute_enemy_group(entry_idx: int,
		new_waypoints: PackedVector2Array,
		blocked: PackedByteArray, cell: int) -> void:
	var half: float = float(cell) * 0.5
	for e: Dictionary in GameState.enemies:
		if e.dead or e.get("flying", false):
			continue
		if entry_idx >= 0 and e.get("path_entry_idx", -1) != entry_idx:
			continue

		# Find the first blocked waypoint ahead
		var first_blocked := -1
		for i in range(int(e.wp_idx), e.waypoints.size()):
			var wp: Vector2 = e.waypoints[i]
			var sx := int(wp.x / half)
			var sy := int(wp.y / half)
			if sx >= 0 and sx < SCOLS and sy >= 0 and sy < SROWS:
				if blocked[sy * SCOLS + sx] == 1:
					first_blocked = i
					break
		if first_blocked < 0:
			continue

		# Find new-path point nearest to the last unblocked position
		var approach: Vector2 = e.waypoints[maxi(first_blocked - 1, int(e.wp_idx))]
		var best_idx  := -1
		var best_dist := INF
		for i in new_waypoints.size():
			var d: float = approach.distance_to(new_waypoints[i])
			if d < best_dist:
				best_dist = d
				best_idx  = i
		if best_idx < 0:
			continue

		var merged := PackedVector2Array()
		for i in range(int(e.wp_idx), first_blocked):
			merged.append(e.waypoints[i])
		for i in range(best_idx, new_waypoints.size()):
			merged.append(new_waypoints[i])
		e.waypoints = merged
		e.wp_idx    = 0


static func _block_rect(blocked: PackedByteArray, pos: Vector2, sz: Vector2i) -> void:
	var sx0 := int(pos.x * 2)
	var sy0 := int(pos.y * 2)
	var sx1 := int((pos.x + sz.x) * 2)
	var sy1 := int((pos.y + sz.y) * 2)
	for sy in range(sy0, sy1):
		for sx in range(sx0, sx1):
			if sx >= 0 and sx < SCOLS and sy >= 0 and sy < SROWS:
				blocked[sy * SCOLS + sx] = 1
