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
var current_path:    Array = []
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


func reset() -> void:
	towers.clear()
	enemies.clear()
	projectiles.clear()
	explosions.clear()
	particles.clear()
	floats.clear()
	current_path.clear()
	wave_spawn_queue.clear()

	wave              = 0
	wave_in_progress  = false
	wave_countdown    = WAVE_INTERVAL_FIRST
	spawn_timer       = 0.0
	wave_banner_timer = 0.0
	wave_banner_text  = ""

	escaped      = 0
	max_escape   = [100, 50, 0][difficulty]
	gold         = 200
	game_started = false
	game_over    = false

	hover_pos   = Vector2(-1.0, -1.0)
	hover_valid = false
	placing     = false
	inspected   = {}

	gold_changed.emit(gold)
	escaped_changed.emit(escaped, max_escape)
	game_restarted.emit()
