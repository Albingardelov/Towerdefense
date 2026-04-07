class_name TowerDefs

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
	3.5, 4.0, 1.8, 2.0,
	2.5, 4.5, 9.0,
	3.5, 3.5,
	2.8, 1.5,
	3.8,
]

const DAMAGE := [
	85.0, 45.0, 180.0, 40.0, 150.0,
	160.0, 20.0, 35.0, 25.0,
	15.0, 12.0, 60.0, 280.0,
	200.0, 18.0, 150.0,
	22.0, 50.0,
	55.0, 220.0,
	30.0,
]

const FIRERATE := [
	0.60, 1.00, 0.30, 0.90, 0.35,
	0.30, 1.50, 1.40, 0.80,
	1.00, 1.10, 0.70, 0.25,
	0.20, 1.30, 0.40,
	2.00, 0.80,
	0.75, 0.35,
	1.00,
]

const COST := [
	200, 150, 400, 250, 600,
	350, 150, 200, 250,
	100, 200, 400, 700,
	300, 150, 550,
	150, 300,
	200, 500,
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
	0.0, 15.0, 0.0, 0.0,
	0.0, 10.0, 0.0, 0.0,
	0.0, 8.0, 0.0,
	0.0, 0.0,
	0.0, 0.0,
	20.0,
]

const DOT_DUR := [
	0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 3.0, 0.0, 0.0,
	0.0, 3.0, 0.0, 0.0,
	0.0, 4.0, 0.0,
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

static func count() -> int:
	return NAMES.size()
