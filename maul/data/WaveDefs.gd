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

# HP-kurva: piecewise exponentiell (×1.25/wave W1–15, ×1.14/wave W16–38)
# Modifierad för wave-typ: boss ×1.65, mass ×0.38, fly ×0.40, final boss ×2.5
# Agentanalys: 4 st (WC3-expert, matteexpert, cost-designer, HP-balansör)
const HP := [
	    75,    100,    125,    150,    200,     75,    250,    350,  # W6: fly-introduktion (andrum)
	   200,    550,    350,    800,   1000,    700,   1750,    800,  # W9: mass, W10: andrum, W16: mass-andrum
	  2750,   2250,   1500,   5000,   5000,   3750,   2500,   5000,  # W17: magic immune, W19: fly, W20: boss
	  9000,   7500,   4000,   9000,   9500,  18500,  13500,   7000,  # W25: boss, W27: fly, W30: boss-spike
	 16000,  24000,   6500,  24000,  36000,  30000,   8000,  80000,  # W35: fly-boss, W37: invisible-spike, W40: final boss
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

# Gold per kill — reducerat ~50–65% för att hålla spelaren på 20–30 torn vid wave 30
# (original var 3–4× för generöst: 92 torn vid wave 30, mål 20–30)
const BOUNTY := [
	  3,   3,   4,   4,   4,   5,   6,   7,
	  6,   8,   7,  12,  11,  10,  15,  10,
	 12,  20,  16,  25,  18,  24,  21,  31,
	 38,  33,  36,  39,  44,  50,  48,  54,
	 59,  62,  68,  77,  74,  89,  97, 275,
]

# Gold bonus för avklarad wave — samma reduktionsfaktor (0.35× early, 0.55× late)
const BONUS := [
	 12,  14,  15,  17,  19,  20,  23,  25,
	 27,  32,  34,  38,  41,  45,  49,  54,
	 58,  64,  68,  99,  74,  81,  86,  93,
	132, 100, 109, 118, 125, 185, 135, 146,
	156, 169, 182, 199, 212, 230, 246, 660,
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
