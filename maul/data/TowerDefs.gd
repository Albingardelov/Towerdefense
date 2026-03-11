class_name TowerDefs

const NAMES    := ["Cornerstone", "Lightning Rod", "Storm Guard", "Mjolnir", "Tempest"]
const SIZES    := [Vector2i(1,1), Vector2i(1,1), Vector2i(1,1), Vector2i(2,2), Vector2i(1,1)]
const RANGE    := [2.5,  4.5,  3.5,  6.0,  3.5]
const DAMAGE   := [30.0, 73.0, 190.0, 10.0, 65.0]
const FIRERATE := [1.05, 0.85, 0.80,  20.0,  0.55]
const COST     := [100,  250,  600,  2000,  450]
const AOE      := [true, false, false, false, true]
const SPLASH   := [0.4,  0.0,  0.0,  0.0,  1.5]
const AIR_MULT := [2.0,  2.0,  2.0,  1.0,  1.0]

const FILL := [
	Color(0.280, 0.360, 0.420),   # Cornerstone  — gray
	Color(0.080, 0.220, 0.500),   # Lightning Rod — blue
	Color(0.040, 0.120, 0.300),   # Storm Guard   — dark blue
	Color(0.500, 0.350, 0.040),   # Mjolnir       — gold
	Color(0.220, 0.060, 0.380),   # Tempest       — purple
]

const STROKE := [
	Color(0.750, 0.850, 0.920),   # Cornerstone  — bright silver
	Color(0.180, 0.600, 1.000),   # Lightning Rod — vivid blue
	Color(0.450, 0.700, 1.000),   # Storm Guard   — bright blue
	Color(1.000, 0.820, 0.120),   # Mjolnir       — bright gold
	Color(0.850, 0.420, 1.000),   # Tempest       — vivid purple
]

const ANIM_SHEET := [
	"res://assets/Part 1/03.png",   # Cornerstone  — vit/silver gnista
	"res://assets/Part 2/69.png",   # Lightning Rod — blå flamma
	"res://assets/Part 3/113.png",  # Storm Guard   — isblå effekt
	"res://assets/Part 4/174.png",  # Mjolnir       — orange/guld
	"res://assets/Part 6/273.png",  # Tempest       — lila kaos
]
const ANIM_ROW  := [0, 2, 1, 3, 0]
const ANIM_FPS  := [6.0, 8.0, 7.0, 10.0, 5.0]

static func count() -> int:
	return NAMES.size()
