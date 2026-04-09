class_name TowerDefs

const ATTACK_NORMAL := 0
const ATTACK_PIERCE := 1
const ATTACK_MAGIC  := 2
const ATTACK_SIEGE  := 3
const ATTACK_CHAOS  := 4
const ATTACK_HERO   := 5

const NAMES := [
	"Destroyer", "Buzzz", "Aviar", "Hatchet", "Pure",
	"Gjutjärnspannan", "Sous Vide", "Woken", "Morteln",
	"Göteborgs Rapé", "General White", "Oden's Extreme", "Siberia",
	"Ristretto", "Cold Brew", "Chemex",
	"Ernie Ball", "Tube Screamer",
	"Roundhouse", "Elbow",
	"Hot Stone",
]

const THEME := [
	"Discgolf", "Discgolf", "Discgolf", "Discgolf", "Discgolf",
	"Matlagning", "Matlagning", "Matlagning", "Matlagning",
	"Snus", "Snus", "Snus", "Snus",
	"Kaffe", "Kaffe", "Kaffe",
	"Gitarr", "Gitarr",
	"Muay Thai", "Muay Thai",
	"Massage",
]

const LORE := [
	"Distance driver. Du vet vad du gör.",
	"Midrange. Förutsägbar. Pålitlig. Lite tråkig.",
	"Puttern. Så nära måste du vara för att verkligen mena det.",
	"Overstable. Skär rakt igenom.",
	"Latitude 64. Ren linje. Inga ursäkter.",
	"Ärvd från mormor. Tyngre än karma.",
	"62 grader i 4 timmar. Ingen stress.",
	"Het panna. Snabba rörelser. Eld.",
	"Maler ner allt. Sakta.",
	"En klassiker. Klibbar fast. Precis som den.",
	"Premium. Gör ont lite längre.",
	"För mycket. Alltid för mycket.",
	"Den starkaste matchen. Du byggde en maze för att slippa känna.",
	"Liten. Brutal. Ingen tid för mjölk.",
	"Tar 18 timmar. Dödar sakta.",
	"Tar tid. Värt det.",
	"Super Slinky .009. Snabb och tunn.",
	"Ibanez TS9. Lite mer av allt.",
	"8 weapons. Den här är favoriten.",
	"I clinch. Det här är personligt.",
	"62 grader på ryggen. Avslappnat helvete.",
]

const SIZES := [
	Vector2i(1,1), Vector2i(1,1), Vector2i(1,1), Vector2i(1,1), Vector2i(1,1),
	Vector2i(1,1), Vector2i(1,1), Vector2i(1,1), Vector2i(1,1),
	Vector2i(1,1), Vector2i(1,1), Vector2i(1,1), Vector2i(1,1),
	Vector2i(1,1), Vector2i(1,1), Vector2i(1,1),
	Vector2i(1,1), Vector2i(1,1),
	Vector2i(1,1), Vector2i(1,1),
	Vector2i(1,1),
]

const RANGE := [
	7.0, 4.5, 2.5, 4.0, 9.0,
	2.5, 4.0, 3.0, 2.5,
	3.5, 4.0, 3.0, 4.0,  # Oden's Extreme: 1.8→3.0, Siberia: 2.0→4.0
	2.5, 4.5, 9.0,
	3.5, 3.5,
	2.8, 3.0,  # Elbow: 1.5→3.0
	3.8,
]

const DAMAGE := [
	85.0, 38.0, 220.0, 40.0, 200.0,  # Buzzz: 45→38, Pure: 150→200
	160.0, 20.0, 35.0, 25.0,
	20.0, 20.0, 60.0, 360.0,  # Göteborgs Rapé: 15→20, Siberia: 280→360
	40.0, 18.0, 175.0,         # Ristretto: 80→40, Chemex: 150→175
	22.0, 50.0,
	55.0, 220.0,
	30.0,
]

const FIRERATE := [
	0.60, 1.00, 0.30, 0.90, 0.47,  # Pure: 0.35→0.47 (DPS 52.5→70.5)
	0.30, 1.50, 1.40, 0.80,
	1.00, 1.10, 0.70, 0.25,
	0.80, 1.30, 0.40,               # Ristretto: 0.20→0.80 (espresso DoT applicator)
	2.00, 0.80,
	0.75, 0.35,
	1.00,
]

const ATTACK_TYPE := [
	ATTACK_PIERCE, # 0  Destroyer
	ATTACK_SIEGE,  # 1  Buzzz (AOE)
	ATTACK_PIERCE, # 2  Aviar
	ATTACK_SIEGE,  # 3  Hatchet (AOE)
	ATTACK_PIERCE, # 4  Pure
	ATTACK_SIEGE,  # 5  Gjutjärnspannan (AOE)
	ATTACK_MAGIC,  # 6  Sous Vide (DoT)
	ATTACK_SIEGE,  # 7  Woken (AOE)
	ATTACK_MAGIC,  # 8  Morteln (slow/aoe)
	ATTACK_NORMAL, # 9  Göteborgs Rapé (slow)
	ATTACK_MAGIC,  # 10 General White (DoT)
	ATTACK_MAGIC,  # 11 Oden's Extreme (slow/aoe)
	ATTACK_CHAOS,  # 12 Siberia (big single-hit)
	ATTACK_MAGIC,  # 13 Ristretto (DoT)
	ATTACK_MAGIC,  # 14 Cold Brew (DoT)
	ATTACK_PIERCE, # 15 Chemex (anti-air multiplier)
	ATTACK_PIERCE, # 16 Ernie Ball
	ATTACK_SIEGE,  # 17 Tube Screamer (AOE)
	ATTACK_SIEGE,  # 18 Roundhouse (AOE)
	ATTACK_NORMAL, # 19 Elbow
	ATTACK_MAGIC,  # 20 Hot Stone (DoT/slow)
]

const COST := [
	200, 150, 300, 200, 400,   # Hatchet: 250→200, Pure: 600→400
	350, 150, 200, 125,        # Morteln: 175→125
	125, 200, 300, 500,        # Oden's Extreme: 400→300, Siberia: 700→500
	250, 150, 350,             # Ristretto: 200→250, Chemex: 550→350
	150, 200,                  # Tube Screamer: 300→200
	200, 400,                  # Elbow: 500→400
	200,
]

const AOE := [
	false, true,  false, true,  false,
	true,  false, true,  true,
	false, false, true,  false,
	false, false, false,
	false, true,
	true,  false,
	false,
]

const SPLASH := [
	0.0, 0.5, 0.0, 0.8, 0.0,
	1.2, 0.0, 0.4, 0.6,
	0.0, 0.0, 1.0, 0.0,
	0.0, 0.0, 0.0,
	0.0, 0.7,
	0.6, 0.0,
	0.0,
]

const AIR_MULT := [
	2.0, 1.0, 2.0, 1.0, 2.0,
	1.0, 1.0, 1.0, 1.0,
	1.0, 1.0, 1.0, 1.0,
	1.0, 1.0, 2.0,
	1.0, 1.0,
	1.0, 1.0,
	1.0,
]

const SLOW := [
	0.00, 0.00, 0.00, 0.00, 0.00,
	0.00, 0.00, 0.00, 0.40,
	0.25, 0.00, 0.50, 0.00,
	0.00, 0.15, 0.00,
	0.00, 0.00,
	0.00, 0.00,
	0.00,
]

const SLOW_DUR := [
	0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 2.0,
	2.5, 0.0, 2.0, 0.0,
	0.0, 2.0, 0.0,
	0.0, 0.0,
	0.0, 0.0,
	0.0,
]

const DOT := [
	0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 10.0, 0.0, 0.0,   # Sous Vide: 15→10/s
	0.0, 20.0, 0.0, 0.0,
	15.0, 8.0, 0.0,         # Ristretto: 25→15/s
	0.0, 0.0,
	0.0, 0.0,
	12.0,                   # Hot Stone: 20→12/s
]

const DOT_DUR := [
	0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 3.0, 0.0, 0.0,
	0.0, 3.0, 0.0, 0.0,
	2.0, 4.0, 0.0,  # Ristretto: 0→2s DoT duration
	0.0, 0.0,
	0.0, 0.0,
	3.0,
]

const FILL := [
	Color(0.05, 0.12, 0.35), Color(0.05, 0.30, 0.15), Color(0.35, 0.30, 0.05),
	Color(0.25, 0.08, 0.05), Color(0.05, 0.05, 0.35),
	Color(0.20, 0.12, 0.05), Color(0.05, 0.20, 0.28), Color(0.30, 0.15, 0.02),
	Color(0.25, 0.20, 0.05),
	Color(0.05, 0.20, 0.08), Color(0.22, 0.22, 0.25), Color(0.18, 0.05, 0.02),
	Color(0.05, 0.08, 0.20),
	Color(0.28, 0.12, 0.02), Color(0.10, 0.15, 0.22), Color(0.20, 0.16, 0.08),
	Color(0.12, 0.02, 0.28), Color(0.05, 0.22, 0.04),
	Color(0.28, 0.05, 0.05), Color(0.28, 0.10, 0.02),
	Color(0.25, 0.08, 0.08),
]

const STROKE := [
	Color(0.20, 0.60, 1.00), Color(0.30, 1.00, 0.50), Color(1.00, 0.85, 0.20),
	Color(1.00, 0.30, 0.20), Color(0.55, 0.55, 1.00),
	Color(0.80, 0.65, 0.40), Color(0.20, 0.85, 0.90), Color(1.00, 0.55, 0.10),
	Color(0.75, 0.85, 0.20),
	Color(0.30, 0.90, 0.40), Color(0.85, 0.85, 0.95), Color(1.00, 0.25, 0.15),
	Color(0.60, 0.80, 1.00),
	Color(0.90, 0.50, 0.20), Color(0.40, 0.65, 1.00), Color(0.95, 0.80, 0.40),
	Color(0.85, 0.30, 1.00), Color(0.30, 1.00, 0.25),
	Color(1.00, 0.30, 0.20), Color(1.00, 0.55, 0.20),
	Color(1.00, 0.50, 0.35),
]

const ANIM_SHEET: Array = []
const ANIM_ROW:   Array = []
const ANIM_FPS:   Array = []

const TAGS: Array[Array] = [
	["disc"],                          # 0  Destroyer
	["disc", "aoe"],                   # 1  Buzzz
	["disc"],                          # 2  Aviar
	["disc", "aoe"],                   # 3  Hatchet
	["disc"],                          # 4  Pure
	["aoe", "matlagning"],             # 5  Gjutjärnspannan
	["dot", "matlagning"],             # 6  Sous Vide
	["aoe", "matlagning"],             # 7  Woken
	["slow", "aoe", "matlagning"],     # 8  Morteln
	["slow", "snus"],                  # 9  Göteborgs Rapé
	["dot", "snus"],                   # 10 General White
	["slow", "aoe", "snus"],           # 11 Oden's Extreme
	["snus"],                          # 12 Siberia
	["dot", "kaffe"],                  # 13 Ristretto
	["dot", "kaffe"],                  # 14 Cold Brew
	["kaffe"],                         # 15 Chemex
	["gitarr"],                        # 16 Ernie Ball
	["aoe", "gitarr"],                 # 17 Tube Screamer
	["aoe", "muay_thai"],              # 18 Roundhouse
	["muay_thai"],                     # 19 Elbow
	["dot", "slow", "massage"],        # 20 Hot Stone
]

static func count() -> int:
	return NAMES.size()
