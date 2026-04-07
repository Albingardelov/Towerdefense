class_name SynergyDefs

# Synergier aktiveras automatiskt när spelaren har rätt torn placerade.
# req_tags: kräver minst 1 torn med VARJE tagg i listan
# req_count: kräver minst N torn med den angivna taggen

const SYNERGIES: Array[Dictionary] = [
	{
		"id":    "slow_roast",
		"name":  "Slow Roast",
		"desc":  "Slow + DoT: DoT-skada ×1.5 på slommade fiender",
		"icon":  "🔥",
		"req_tags": ["slow", "dot"],
	},
	{
		"id":    "disc_mastery",
		"name":  "Full Bag",
		"desc":  "3+ Discgolf-torn: +20% räckvidd på alla Disc-torn",
		"icon":  "🥏",
		"req_count": {"disc": 3},
	},
	{
		"id":    "caffeine_economy",
		"name":  "Koffeinberoende",
		"desc":  "2+ Kaffe-torn: varje kaffe-kill ger +1 extra guld",
		"icon":  "☕",
		"req_count": {"kaffe": 2},
	},
]

static func count() -> int:
	return SYNERGIES.size()
