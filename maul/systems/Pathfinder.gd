class_name Pathfinder

const COLS  := 16
const ROWS  := 22
const SCOLS := COLS * 2
const SROWS := ROWS * 2

const ENTRY := Vector2i(8, 0)
const EXIT  := Vector2i(8, 21)

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


static func bfs(blocked: PackedByteArray) -> Array:
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


static func path_to_pixels(path: Array, cell: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	var half   := float(cell) * 0.5
	for p: Vector2i in path:
		result.append(Vector2((p.x + 0.5) * half, (p.y + 0.5) * half))
	return result


static func rebuild(cell: int) -> void:
	var blocked      := build_blocked()
	GameState.current_path = bfs(blocked)
	if GameState.current_path.is_empty():
		return
	var new_waypoints := path_to_pixels(GameState.current_path, cell)
	var half: float   = float(cell) * 0.5

	for e: Dictionary in GameState.enemies:
		if e.dead or e.get("flying", false):
			continue

		# Find the first blocked waypoint in the enemy's remaining path.
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
			continue  # No blocked waypoints ahead — keep old path as-is.

		# The enemy follows its OLD waypoints right up to the block, then switches to
		# the new path. We find the new-path waypoint nearest to the last unblocked
		# position so the transition is seamless and never passes through a tower.
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

		# Build merged waypoint list: old (unblocked) prefix + new path suffix.
		var merged := PackedVector2Array()
		for i in range(int(e.wp_idx), first_blocked):
			merged.append(e.waypoints[i])
		for i in range(best_idx, new_waypoints.size()):
			merged.append(new_waypoints[i])
		e.waypoints = merged
		e.wp_idx    = 0

# ============================================================
# Private
# ============================================================

static func _block_rect(blocked: PackedByteArray, pos: Vector2, sz: Vector2i) -> void:
	var sx0 := int(pos.x * 2)
	var sy0 := int(pos.y * 2)
	var sx1 := int((pos.x + sz.x) * 2)
	var sy1 := int((pos.y + sz.y) * 2)
	for sy in range(sy0, sy1):
		for sx in range(sx0, sx1):
			if sx >= 0 and sx < SCOLS and sy >= 0 and sy < SROWS:
				blocked[sy * SCOLS + sx] = 1
