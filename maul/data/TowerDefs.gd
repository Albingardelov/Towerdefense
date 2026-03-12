class_name TowerDefs

# ============================================================
# Gudar
# ============================================================

const GOD_NAMES  := ["Tor", "Loki", "Oden", "Freja"]
const GOD_EMOJIS := ["⚡", "🐍", "🐦", "🌸"]

# Torn-index per gud: Tor=0-4, Loki=5-8, Oden=9-12, Freja=13-16
const GOD_TOWERS := [
	[0, 1, 2, 3, 4],    # Tor
	[5, 6, 7, 8],        # Loki
	[9, 10, 11, 12],     # Oden
	[13, 14, 15, 16],    # Freja
]

# ============================================================
# Torn-data — en rad per torn
# ============================================================

const NAMES := [
	# Tor (0-4)
	"Cornerstone", "Lightning Rod", "Storm Guard", "Mjolnir", "Tempest",
	# Loki (5-8)
	"Mirage", "Venom", "Chaos", "World Serpent",
	# Oden (9-12)
	"Sentinel", "Spyglass", "All-Seeing", "Yggdrasil",
	# Freja (13-16)
	"Thornbriar", "Frost Wind", "Nature's Wrath", "Bifrost",
]

const SIZES := [
	# Tor
	Vector2i(1,1), Vector2i(1,1), Vector2i(1,1), Vector2i(2,2), Vector2i(1,1),
	# Loki
	Vector2i(1,1), Vector2i(1,1), Vector2i(1,1), Vector2i(1,3),
	# Oden
	Vector2i(1,1), Vector2i(1,1), Vector2i(1,1), Vector2i(2,2),
	# Freja
	Vector2i(1,1), Vector2i(1,1), Vector2i(1,1), Vector2i(1,3),
]

const RANGE := [
	# Tor
	2.5, 4.5, 3.5, 6.0, 3.5,
	# Loki — korta-medel räckvidder, kaos-fokus
	3.0, 3.5, 4.0, 5.5,
	# Oden — långa räckvidder, snipar-fokus
	5.5, 7.0, 8.5, 7.0,
	# Freja — korta räckvidder, AOE-fokus
	2.0, 3.5, 3.5, 4.5,
]

const DAMAGE := [
	# Tor
	30.0, 73.0, 190.0, 10.0, 65.0,
	# Loki
	20.0, 45.0, 150.0, 8.0,
	# Oden
	40.0, 95.0, 250.0, 12.0,
	# Freja
	15.0, 55.0, 140.0, 6.0,
]

const FIRERATE := [
	# Tor
	1.05, 0.85, 0.80, 20.0, 0.55,
	# Loki
	1.2, 1.5, 0.6, 18.0,
	# Oden
	0.7, 0.55, 0.45, 15.0,
	# Freja
	2.0, 0.9, 0.85, 22.0,
]

const COST := [
	# Tor
	100, 250, 600, 2000, 450,
	# Loki
	100, 250, 600, 2000,
	# Oden
	100, 250, 600, 2000,
	# Freja
	100, 250, 600, 2000,
]

const AOE := [
	# Tor
	true, false, false, false, true,
	# Loki
	true, false, true, true,
	# Oden
	false, false, false, false,
	# Freja
	true, false, true, false,
]

const SPLASH := [
	# Tor
	0.4, 0.0, 0.0, 0.0, 1.5,
	# Loki
	0.3, 0.0, 1.2, 2.0,
	# Oden
	0.0, 0.0, 0.0, 0.0,
	# Freja
	0.5, 0.0, 1.0, 0.0,
]

const AIR_MULT := [
	# Tor
	2.0, 2.0, 2.0, 1.0, 1.0,
	# Loki
	1.0, 1.0, 1.5, 1.0,
	# Oden — lång räckvidd, bra mot flyg
	2.0, 2.0, 2.0, 1.5,
	# Freja
	1.0, 1.5, 1.0, 1.0,
]

# ============================================================
# Färger
# ============================================================

const FILL := [
	# Tor
	Color(0.280, 0.360, 0.420),   # Cornerstone  — grå
	Color(0.080, 0.220, 0.500),   # Lightning Rod — blå
	Color(0.040, 0.120, 0.300),   # Storm Guard   — mörkblå
	Color(0.500, 0.350, 0.040),   # Mjolnir       — guld
	Color(0.220, 0.060, 0.380),   # Tempest       — lila
	# Loki
	Color(0.100, 0.280, 0.100),   # Illusionstorn — mörkgrön
	Color(0.240, 0.460, 0.090),   # Gifttorn      — giftgrön
	Color(0.320, 0.080, 0.520),   # Kaostorn      — lila
	Color(0.480, 0.020, 0.580),   # Världsormen   — intensiv lila
	# Oden
	Color(0.200, 0.200, 0.280),   # Vakttorn      — mörkgrå
	Color(0.380, 0.380, 0.480),   # Spejartorn    — silver
	Color(0.180, 0.080, 0.360),   # Allseende     — djuplila
	Color(0.800, 0.840, 1.000),   # Yggdrasil     — vit/silver
	# Freja
	Color(0.100, 0.280, 0.110),   # Törnesnår     — mörkgrön
	Color(0.150, 0.400, 0.480),   # Frostvinda    — isblå
	Color(0.120, 0.360, 0.140),   # Naturens vrede — skogsgrönt
	Color(0.480, 0.040, 0.320),   # Bifrost       — magenta
]

const STROKE := [
	# Tor
	Color(0.400, 0.700, 1.000),   # Cornerstone  — elektrisk silver-blå
	Color(0.180, 0.600, 1.000),   # Lightning Rod — levande blå
	Color(0.450, 0.700, 1.000),   # Storm Guard   — ljusblå
	Color(1.000, 0.820, 0.120),   # Mjolnir       — ljusguld
	Color(0.850, 0.420, 1.000),   # Tempest       — levande lila
	# Loki
	Color(0.360, 0.820, 0.360),   # Illusionstorn — ljusgrön
	Color(0.560, 1.000, 0.220),   # Gifttorn      — giftgrön levande
	Color(0.680, 0.220, 0.900),   # Kaostorn      — levande lila
	Color(0.820, 0.160, 1.000),   # Världsormen   — het lila
	# Oden
	Color(0.200, 0.350, 0.900),   # Vakttorn      — djupblå
	Color(0.450, 0.550, 1.000),   # Spejartorn    — mättad silver-blå
	Color(0.500, 0.300, 0.900),   # Allseende     — levande djuplila
	Color(0.600, 0.900, 1.000),   # Yggdrasil     — kosmisk cyan-vit
	# Freja
	Color(0.300, 0.720, 0.320),   # Törnesnår     — ljusgrön
	Color(0.500, 0.820, 0.900),   # Frostvinda    — ljusblå is
	Color(0.280, 0.720, 0.300),   # Naturens vrede — levande grön
	Color(1.000, 0.220, 0.680),   # Bifrost       — levande rosa/magenta
]

# ============================================================
# Animation — nya torn återanvänder befintliga spritesheets
# ============================================================

const ANIM_SHEET := [
	# Tor
	"res://assets/Part 1/03.png",   # Cornerstone  — silver gnista
	"res://assets/Part 2/69.png",   # Lightning Rod — blå flamma
	"res://assets/Part 3/113.png",  # Storm Guard   — isblå
	"res://assets/Part 4/174.png",  # Mjolnir       — guld
	"res://assets/Part 6/273.png",  # Tempest       — lila kaos
	# Loki
	"res://assets/Part 6/273.png",  # Illusionstorn — lila kaos
	"res://assets/Part 3/113.png",  # Gifttorn      — is/grön placeholder
	"res://assets/Part 6/273.png",  # Kaostorn      — lila kaos
	"res://assets/Part 6/273.png",  # Världsormen   — lila
	# Oden
	"res://assets/Part 1/03.png",   # Vakttorn      — silver
	"res://assets/Part 1/03.png",   # Spejartorn    — silver
	"res://assets/Part 2/69.png",   # Allseende     — blå
	"res://assets/Part 1/03.png",   # Yggdrasil     — vit/silver
	# Freja
	"res://assets/Part 3/113.png",  # Törnesnår     — natur/is
	"res://assets/Part 3/113.png",  # Frostvinda    — is
	"res://assets/Part 3/113.png",  # Naturens vrede — natur
	"res://assets/Part 6/273.png",  # Bifrost       — colorful
]

# Rad i spritesheet (använd bara bekräftade rader: P1→0, P2→2, P3→1, P4→3, P6→0)
const ANIM_ROW := [
	# Tor
	0, 2, 1, 3, 0,
	# Loki
	0, 1, 0, 0,
	# Oden
	0, 0, 2, 0,
	# Freja
	1, 1, 1, 0,
]

const ANIM_FPS := [
	# Tor
	6.0, 8.0, 7.0, 10.0, 5.0,
	# Loki
	7.0, 9.0, 6.0, 12.0,
	# Oden
	5.0, 5.0, 4.0, 10.0,
	# Freja
	10.0, 7.0, 8.0, 14.0,
]

static func count() -> int:
	return NAMES.size()
