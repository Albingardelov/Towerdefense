class_name RelicDefs

# Relics är globala passiva effekter som erbjuds var 10:e wave.
# "effect"-fältet används av main.gd för att applicera effekten.
# Möjliga effect-strängar:
#   disc_damage      — Disc-torn ×value skada
#   wave_gold        — +value guld vid wave-start
#   slow_duration    — +value sekunder på alla slow-effekter
#   guitar_firerate  — Gitarr-torn ×value eldhastighet
#   muay_range       — Muay Thai-torn +value räckvidd (i celler)
#   snus_pierce      — Snus-torn ignorerar armor (value ignoreras)

const RELICS: Array[Dictionary] = [
	{
		"id":    "disc_focus",
		"name":  "Discgolfarens fokus",
		"desc":  "Alla Discgolf-torn: +25% skada",
		"icon":  "🥏",
		"effect": "disc_damage",
		"value":  1.25,
	},
	{
		"id":    "caffeine_boost",
		"name":  "Koffeinstöt",
		"desc":  "+30 guld i början av varje wave",
		"icon":  "☕",
		"effect": "wave_gold",
		"value":  30.0,
	},
	{
		"id":    "slow_extension",
		"name":  "Massörens lugn",
		"desc":  "Alla slow-effekter varar +2 sekunder längre",
		"icon":  "💆",
		"effect": "slow_duration",
		"value":  2.0,
	},
	{
		"id":    "guitar_amp",
		"name":  "Gitarrförstärkning",
		"desc":  "Gitarr-torn: +30% eldhastighet",
		"icon":  "🎸",
		"effect": "guitar_firerate",
		"value":  1.30,
	},
	{
		"id":    "ring_master",
		"name":  "Ringkonst",
		"desc":  "Muay Thai-torn: +1.5 cells räckvidd",
		"icon":  "🥊",
		"effect": "muay_range",
		"value":  1.5,
	},
	{
		"id":    "snus_pierce",
		"name":  "Snustolerans",
		"desc":  "Snus-torn ignorerar rustning (full skada)",
		"icon":  "🟤",
		"effect": "snus_pierce",
		"value":  1.0,
	},
]

static func count() -> int:
	return RELICS.size()
