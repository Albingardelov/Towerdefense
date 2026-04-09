class_name WaveDefs

# ============================================================
# Armor type constants
# ============================================================

const ARMOR_UNARMORED := 0
const ARMOR_LIGHT     := 1
const ARMOR_MEDIUM    := 2
const ARMOR_HEAVY     := 3
const ARMOR_FORTIFIED := 4
const ARMOR_DIVINE    := 5

# ============================================================
# Special mechanic constants
# ============================================================

const SPECIAL_NONE         := 0
const SPECIAL_MASS         := 1   # many units per wave
const SPECIAL_MAGIC_IMMUNE := 2   # magic damage reduced
const SPECIAL_INVISIBLE    := 3   # (future: requires detection)
const SPECIAL_BOSS         := 4   # large, high-HP unit(s)
const SPECIAL_FINAL_BOSS   := 5   # single enormous enemy

# ============================================================
# 40-wave data
# Source: Wintermaul community data (wintermaul_data.json)
# Speed converted: WC3_speed × (30 / 270) → px/s on our 30px grid
# HP converted: WC3_hp × 0.5 → fits our tower damage range
# ============================================================

const NAMES := [
	"Draugr",       "Tomte",        "Hulder",        "Vaettir",
	"Grimr",        "Valravn",      "Mountain Troll", "Forest Troll",
	"Einherjar",    "Myling",       "Fossegrim",      "Dvergr",
	"Dark Elf",     "Nokken",       "Lindworm",       "Berserker",
	"Huldra",       "Iron Giant",   "Sea Serpent",    "Rime Giant",
	"Shadow",       "Fire Giant",   "Hraesvelgr",     "Fire Wolf",
	"Ice King",     "Frost Wolf",   "Winter Wyrm",    "Death Rune",
	"Ancient Wyrm", "Bone King",    "Doom Lord",      "Vidofnir",
	"Garm",         "Blood Demon",  "Fafnir",         "Nidhogg",
	"Soul Reaper",  "Surtr",        "Jormungandr",    "Ymir",
]

# WC3 HP × 0.5, rebalanced: early smoothed, late doubled
const HP := [
	    75,    110,    130,    215,    240,    210,    450,    550,  # W3: 155→130, W5: 290→240
	   350,    700,    450,   1100,   1300,    900,   1750,   1000,  # W9: 400→350 (MASS)
	  1400,   2500,   1600,   3500,   1400,   3250,   2500,   4500,  # W21: 2000→1400 (andrum efter boss)
	  6000,   7000,   3500,   9000,  12000,  18000,   7500,   6000,  # W26: 4000→7000, W28: 5000→9000, W29: 7000→12000, W30: 9000→18000
	 20000,   9000,   8000,  28000,  25000,  35000,  12500, 200000,  # W33: 10000→20000, W36: 12500→28000, W37: 11000→25000, W38: 15000→35000, W40: 60000→200000
]

# WC3 move_speed × (30 / 270), rounded to int
const SPEED := [
	30, 30, 30, 30, 33, 39, 28, 31,
	36, 30, 42, 27, 29, 44, 28, 39,
	33, 26, 47, 27, 36, 29, 48, 27,
	26, 31, 42, 30, 26, 27, 29, 44,
	26, 30, 47, 27, 32, 26, 48, 24,
]

const COUNT := [
	12, 12, 14, 14, 16, 14, 10, 12,
	20, 12, 14,  8, 10, 12,  8, 18,
	16,  6, 10,  8, 14,  8, 10,  6,
	 6, 10,  8,  8,  5,  6,  7,  8,
	 5,  6,  6,  5,  7,  5,  6,  1,
]

# Gold per kill (from WC3 bounty values)
const BOUNTY := [
	  8,   9,  10,  11,  12,  13,  16,  17,
	 14,  20,  18,  28,  26,  24,  35,  22,
	 28,  45,  36,  55,  40,  52,  46,  65,
	 80,  70,  75,  80,  90, 100,  95, 105,
	115, 120, 130, 145, 140, 165, 180, 500,
]

# Gold bonus for completing the wave
const BONUS := [
	 35,  38,  42,  46,  50,  55,  60,  65,
	 70,  80,  85,  92, 100, 108, 116, 125,
	135, 145, 155, 220, 165, 175, 186, 198,
	280, 212, 226, 240, 255, 370, 270, 286,
	305, 325, 350, 375, 400, 425, 455, 1200,
]

# Whether the wave flies straight to exit (ignores maze)
const FLIES := [
	false, false, false, false, false,  true, false, false,
	false, false,  true, false, false,  true, false, false,
	false, false,  true, false, false, false,  true, false,
	false, false,  true, false, false, false, false,  true,
	false, false,  true, false, false, false,  true, false,
]

# Armor type (ARMOR_* constants above)
const ARMOR := [
	0, 0, 1, 1, 1, 0, 2, 2,
	0, 2, 1, 3, 3, 2, 3, 2,
	0, 3, 2, 3, 0, 3, 2, 3,
	4, 3, 3, 0, 4, 4, 3, 2,
	4, 3, 3, 4, 0, 4, 3, 5,
]

# Special mechanic (SPECIAL_* constants above)
const SPECIAL := [
	0, 0, 0, 0, 0, 0, 0, 0,
	1, 0, 0, 0, 0, 0, 0, 1,
	2, 0, 0, 4, 3, 0, 0, 0,
	4, 0, 0, 2, 0, 4, 0, 0,
	0, 2, 4, 0, 3, 0, 2, 5,
]

# ============================================================
# API
# ============================================================

static func count() -> int:
	return NAMES.size()


static func idx(wave: int) -> int:
	return mini(wave - 1, 39)


static func get_wave(wave: int) -> Dictionary:
	var i := idx(wave)
	return {
		name    = NAMES[i],
		hp      = float(HP[i]),
		speed   = float(SPEED[i]),
		count   = COUNT[i],
		bounty  = BOUNTY[i],
		bonus   = BONUS[i],
		flies   = FLIES[i],
		armor   = ARMOR[i],
		special = SPECIAL[i],
	}
