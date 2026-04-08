extends Node

# ============================================================
# Signals
# ============================================================

signal gold_changed(amount: int)
signal escaped_changed(current: int, max_val: int)
signal wave_started(wave_num: int, banner: String)
signal wave_completed(wave_num: int, bonus: int)
signal game_over_triggered()
signal game_restarted()
signal tower_inspected(tower: Dictionary)

# ============================================================
# World arrays
# ============================================================

var towers:          Array = []
var enemies:         Array = []
var projectiles:     Array = []
var explosions:      Array = []
var particles:       Array = []
var floats:          Array = []
var corpses:         Array = []
var current_path:    Array = []
var current_paths:   Array = []   # Array of paths, one per map entry
var current_map:     int   = 0    # 0 = klassisk, 1 = mandala
var wave_spawn_queue: Array = []

# ============================================================
# Wave state
# ============================================================

const WAVE_INTERVAL_FIRST := 60.0
const WAVE_INTERVAL       := 30.0

var wave:              int   = 0
var wave_in_progress:  bool  = false
var wave_countdown:    float = WAVE_INTERVAL_FIRST
var spawn_timer:       float = 0.0
var wave_banner_timer: float = 0.0
var wave_banner_text:  String = ""

# ============================================================
# Game state
# ============================================================

var escaped:      int  = 0
var max_escape:   int  = 50
var difficulty:   int  = 1   # 0=Easy  1=Medium  2=Hard
var gold:         int  = 500
var game_started: bool = false
var game_over:    bool = false
signal draft_ready(offer: Array[int])   # emittas med 3 tornindex
signal relic_draft_ready(offer: Array[Dictionary])
signal synergy_activated(syn_id: String, syn_name: String, syn_icon: String)
signal relic_acquired(relic: Dictionary)

var unlocked_towers: Array[int] = []    # vilka torn spelaren fått via draft
var draft_pending:   bool       = false # väntar på spelarens val

var active_synergies: Array[String] = []   # IDs på aktiva synergier
var active_relics:    Array[Dictionary] = []  # Hela relic-dicts

var runs_played: int = 0
var best_wave:   int = 0

# ============================================================
# Placement state
# ============================================================

var hover_pos:   Vector2    = Vector2(-1.0, -1.0)
var hover_valid: bool       = false
var placing:     bool       = false
var selected:    int        = 0
var inspected:   Dictionary = {}

# ============================================================
# Mutators
# ============================================================

func _ready() -> void:
	load_meta()


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> void:
	gold -= amount
	gold_changed.emit(gold)


func add_escaped() -> void:
	escaped += 1
	escaped_changed.emit(escaped, max_escape)


func set_inspected(tower: Dictionary) -> void:
	inspected = tower
	tower_inspected.emit(tower)


func _refresh_synergies() -> void:
	# Räkna taggar från PLACERADE torn (ej bara unlockade)
	var tag_counts: Dictionary = {}
	for t in towers:
		for tag: String in TowerDefs.TAGS[t.type]:
			tag_counts[tag] = tag_counts.get(tag, 0) + 1

	var prev: Array[String] = active_synergies.duplicate()
	active_synergies.clear()

	for syn: Dictionary in SynergyDefs.SYNERGIES:
		var is_active := false

		if syn.has("req_tags"):
			is_active = true
			for tag: String in syn.req_tags:
				if tag_counts.get(tag, 0) == 0:
					is_active = false
					break

		elif syn.has("req_count"):
			is_active = true
			for tag: String in syn.req_count:
				if tag_counts.get(tag, 0) < (syn.req_count as Dictionary)[tag]:
					is_active = false
					break

		if is_active:
			active_synergies.append(syn.id)
			if not prev.has(syn.id):
				synergy_activated.emit(syn.id, syn.name, syn.icon)


func acquire_relic(relic: Dictionary) -> void:
	active_relics.append(relic)
	relic_acquired.emit(relic)


func reset() -> void:
	towers.clear()
	enemies.clear()
	projectiles.clear()
	explosions.clear()
	particles.clear()
	floats.clear()
	corpses.clear()
	current_path.clear()
	current_paths.clear()
	wave_spawn_queue.clear()

	wave              = 0
	wave_in_progress  = false
	wave_countdown    = WAVE_INTERVAL_FIRST
	spawn_timer       = 0.0
	wave_banner_timer = 0.0
	wave_banner_text  = ""

	escaped      = 0
	max_escape   = [100, 50, 0][difficulty]
	gold         = 500
	game_started = false
	game_over    = false

	unlocked_towers.clear()
	draft_pending = false

	active_synergies.clear()
	active_relics.clear()

	hover_pos   = Vector2(-1.0, -1.0)
	hover_valid = false
	placing     = false
	inspected   = {}

	gold_changed.emit(gold)
	escaped_changed.emit(escaped, max_escape)
	game_restarted.emit()


const SAVE_PATH := "user://maze_td_save.json"


func save_meta() -> void:
	var data := {
		"best_wave":   best_wave,
		"runs_played": runs_played,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func load_meta() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed := JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		best_wave   = int(parsed.get("best_wave",   0))
		runs_played = int(parsed.get("runs_played", 0))
