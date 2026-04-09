# BoI-känslan Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ge Maze TD äkta Binding of Isaac-känsla genom synergier, relics, wave preview, run summary och meta-progression.

**Architecture:** Tre nya datafiler (SynergyDefs, RelicDefs) läggs till. GameState utökas med aktiva synergier och relics. Synergi-effekter appliceras i main.gd:s attack-loop. HUD utökas med toast-notiser, relic-icons, wave preview och en run summary-panel.

**Tech Stack:** Godot 4, GDScript, inga externa beroenden. All testning sker manuellt via Godot-editorn.

---

## Filstruktur

**Skapa:**
- `maul/data/SynergyDefs.gd` — 3 synergi-definitioner med tags och effekter
- `maul/data/RelicDefs.gd` — 6 relic-definitioner (globala passiva)

**Modifiera:**
- `maul/data/TowerDefs.gd` — lägg till `TAGS` konstant (en Array per torn)
- `maul/autoload/GameState.gd` — active_synergies, active_relics, signals, _refresh_synergies(), runs_played, best_wave, save/load
- `maul/main.gd` — synergy-effekter i _tick_towers/_tick_enemies/_apply_damage, _trigger_relic_draft(), wave_gold relic
- `maul/ui/HUD.gd` — synergy toast, relic-strip i top bar, wave preview label, run summary overlay, relic draft overlay

---

## Task 1: TAGS i TowerDefs + SynergyDefs.gd

**Files:**
- Modify: `maul/data/TowerDefs.gd`
- Create: `maul/data/SynergyDefs.gd`

- [ ] **Steg 1: Lägg till TAGS i TowerDefs.gd**

Öppna `maul/data/TowerDefs.gd`. Lägg till konstanten **precis efter `ANIM_FPS`-raden** (sista raden before `static func count()`):

```gdscript
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
	["kaffe"],                         # 13 Ristretto
	["dot", "kaffe"],                  # 14 Cold Brew
	["kaffe"],                         # 15 Chemex
	["gitarr"],                        # 16 Ernie Ball
	["aoe", "gitarr"],                 # 17 Tube Screamer
	["aoe", "muay_thai"],              # 18 Roundhouse
	["muay_thai"],                     # 19 Elbow
	["dot", "slow", "massage"],        # 20 Hot Stone
]
```

- [ ] **Steg 2: Skapa SynergyDefs.gd**

Skapa filen `maul/data/SynergyDefs.gd` med exakt detta innehåll:

```gdscript
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
```

- [ ] **Steg 3: Verifiera i Godot**

Öppna Godot-editorn. Tryck F5 (kör). Spelet ska starta utan fel.  
Förväntat: inga parse-errors, inga "Class not found"-varningar.

- [ ] **Steg 4: Commit**

```bash
cd /home/albin/Documents/Towerdefense
git add maul/data/TowerDefs.gd maul/data/SynergyDefs.gd
git commit -m "feat: add tower TAGS and SynergyDefs data layer"
```

---

## Task 2: RelicDefs.gd

**Files:**
- Create: `maul/data/RelicDefs.gd`

- [ ] **Steg 1: Skapa RelicDefs.gd**

Skapa `maul/data/RelicDefs.gd`:

```gdscript
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
```

- [ ] **Steg 2: Verifiera**

Kör spelet. Inga fel. Commit:

```bash
git add maul/data/RelicDefs.gd
git commit -m "feat: add RelicDefs with 6 global passives"
```

---

## Task 3: Synergy Engine i GameState

**Files:**
- Modify: `maul/autoload/GameState.gd`

- [ ] **Steg 1: Lägg till signals och state-variabler**

I `maul/autoload/GameState.gd`, lägg till direkt **efter `signal draft_ready`-raden** (rad ~55):

```gdscript
signal synergy_activated(syn_id: String, syn_name: String, syn_icon: String)
signal relic_acquired(relic: Dictionary)

var active_synergies: Array[String] = []   # IDs på aktiva synergier
var active_relics:    Array[Dictionary] = []  # Hela relic-dicts

var runs_played: int = 0
var best_wave:   int = 0
```

- [ ] **Steg 2: Lägg till _refresh_synergies()**

I `maul/autoload/GameState.gd`, lägg till **precis före `reset()`-funktionen**:

```gdscript
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
```

- [ ] **Steg 3: Uppdatera reset() för att nollställa nya variabler**

I `reset()`-funktionen, lägg till i slutet (precis **before** `gold_changed.emit(gold)`):

```gdscript
	active_synergies.clear()
	active_relics.clear()
```

- [ ] **Steg 4: Lägg till relic_acquire-helper**

Precis **efter** `_refresh_synergies()`, lägg till:

```gdscript
func acquire_relic(relic: Dictionary) -> void:
	active_relics.append(relic)
	relic_acquired.emit(relic)
```

- [ ] **Steg 5: Verifiera**

Kör spelet. Inga fel. Commit:

```bash
git add maul/autoload/GameState.gd
git commit -m "feat: add synergy engine and relic state to GameState"
```

---

## Task 4: Synergy-effekter i main.gd

**Files:**
- Modify: `maul/main.gd`

Synergier påverkar tre ställen: `_tick_towers` (Disc range), `_tick_enemies` (Slow Roast DoT-multiplikator) och `_apply_damage` (Caffeine Economy guld + anrop till _refresh_synergies).

- [ ] **Steg 1: Anropa _refresh_synergies() när torn placeras/säljs**

I `_handle_tap()`, efter `GameState.towers.append({...})` och efter `GameState.spend_gold(...)`, lägg till:

```gdscript
		GameState._refresh_synergies()
```

I `_on_sell_tower()`, efter `GameState.towers = GameState.towers.filter(...)`, lägg till:

```gdscript
	GameState._refresh_synergies()
```

I `_on_clear_all()`, efter `GameState.towers.clear()`, lägg till:

```gdscript
	GameState._refresh_synergies()
```

- [ ] **Steg 2: Disc Mastery — +20% range på Disc-torn i _tick_towers**

I `_tick_towers()`, hitta raden:
```gdscript
		var range_px: float = TowerDefs.RANGE[t.type] * CELL
```
Ersätt den med:
```gdscript
		var range_px: float = TowerDefs.RANGE[t.type] * CELL
		if GameState.active_synergies.has("disc_mastery") \
				and TowerDefs.TAGS[t.type].has("disc"):
			range_px *= 1.20
		# Relic: Muay Thai +range
		for relic: Dictionary in GameState.active_relics:
			if relic.effect == "muay_range" \
					and TowerDefs.TAGS[t.type].has("muay_thai"):
				range_px += relic.value * float(CELL)
```

- [ ] **Steg 3: Relic disc_damage och guitar_firerate i _tick_towers**

Hitta i `_tick_towers()` raden:
```gdscript
			var dmg: float = TowerDefs.DAMAGE[t.type]
```
Ersätt med:
```gdscript
			var dmg: float = TowerDefs.DAMAGE[t.type]
			for relic: Dictionary in GameState.active_relics:
				if relic.effect == "disc_damage" \
						and TowerDefs.TAGS[t.type].has("disc"):
					dmg *= relic.value
```

Hitta raden:
```gdscript
			t.cooldown = 1.0 / TowerDefs.FIRERATE[t.type]
```
Ersätt med:
```gdscript
			var firerate: float = TowerDefs.FIRERATE[t.type]
			for relic: Dictionary in GameState.active_relics:
				if relic.effect == "guitar_firerate" \
						and TowerDefs.TAGS[t.type].has("gitarr"):
					firerate *= relic.value
			t.cooldown = 1.0 / firerate
```

- [ ] **Steg 4: Slow Roast — DoT ×1.5 på slommade fiender i _tick_enemies**

Hitta i `_tick_enemies()`:
```gdscript
			var creep_gold_dot: int = WaveDefs.get_wave(GameState.wave).bounty
			_apply_damage(e, e["dot_dps"] * delta, creep_gold_dot)
```
Ersätt med:
```gdscript
			var creep_gold_dot: int = WaveDefs.get_wave(GameState.wave).bounty
			var dot_mult := 1.5 if (GameState.active_synergies.has("slow_roast") \
				and e.get("slow_factor", 0.0) > 0.0) else 1.0
			_apply_damage(e, e["dot_dps"] * delta * dot_mult, creep_gold_dot)
```

- [ ] **Steg 5: Relic slow_duration — längre slow vid _apply_damage**

I `_apply_damage()`, hitta:
```gdscript
	if tower_type >= 0 and TowerDefs.SLOW[tower_type] > 0.0:
		e["slow_factor"] = TowerDefs.SLOW[tower_type]
		e["slow_t"]      = TowerDefs.SLOW_DUR[tower_type]
```
Ersätt med:
```gdscript
	if tower_type >= 0 and TowerDefs.SLOW[tower_type] > 0.0:
		e["slow_factor"] = TowerDefs.SLOW[tower_type]
		var slow_dur: float = TowerDefs.SLOW_DUR[tower_type]
		for relic: Dictionary in GameState.active_relics:
			if relic.effect == "slow_duration":
				slow_dur += relic.value
		e["slow_t"] = slow_dur
```

- [ ] **Steg 6: Caffeine Economy — +1 guld per kaffe-kill i _apply_damage**

I `_apply_damage()`, hitta:
```gdscript
		var kg: int = creep_gold
		GameState.add_gold(kg)
```
Ersätt med:
```gdscript
		var kg: int = creep_gold
		if tower_type >= 0 and GameState.active_synergies.has("caffeine_economy") \
				and TowerDefs.TAGS[tower_type].has("kaffe"):
			kg += 1
		GameState.add_gold(kg)
```

- [ ] **Steg 7: Verifiera synergier**

Kör spelet. Starta en run.
1. Köp och placera Morteln (torn 8) + Hot Stone (torn 20).
2. Rota på fiender — de som är slommade ska ta mer DoT-skada (syns inte tydligt ännu, men koden ska köras utan fel).
3. Köp 3 Disc-torn (Destroyer, Buzzz, Aviar). Kontrollera att rangecirkeln blir större på dem.
4. Inga parse-fel i Output-panelen.

```bash
git add maul/main.gd
git commit -m "feat: apply synergy and relic effects in game loop"
```

---

## Task 5: Relic Draft (var 10:e wave)

**Files:**
- Modify: `maul/main.gd`
- Modify: `maul/ui/HUD.gd`

- [ ] **Steg 1: _trigger_relic_draft() i main.gd**

I `main.gd`, hitta `_trigger_draft()`-funktionen. Lägg till en ny funktion **direkt efter den**:

```gdscript
func _trigger_relic_draft() -> void:
	var pool: Array[Dictionary] = []
	for relic: Dictionary in RelicDefs.RELICS:
		var already: bool = false
		for held: Dictionary in GameState.active_relics:
			if held.id == relic.id:
				already = true
				break
		if not already:
			pool.append(relic)
	if pool.is_empty():
		return
	pool.shuffle()
	var offer: Array[Dictionary] = pool.slice(0, mini(3, pool.size()))
	GameState.draft_pending = true
	GameState.relic_draft_ready.emit(offer)
```

- [ ] **Steg 2: Lägg till relic_draft_ready signal i GameState**

I `maul/autoload/GameState.gd`, lägg till direkt **efter `signal draft_ready`-raden**:

```gdscript
signal relic_draft_ready(offer: Array[Dictionary])
```

- [ ] **Steg 3: Ändra wave_completed-koppling i main.gd**

Hitta i `_ready()`:
```gdscript
	GameState.wave_completed.connect(func(wave_num: int, _bonus: int) -> void:
		if wave_num % 5 == 0:
			_trigger_draft())
```
Ersätt med:
```gdscript
	GameState.wave_completed.connect(func(wave_num: int, _bonus: int) -> void:
		if wave_num % 10 == 0:
			_trigger_relic_draft()
		elif wave_num % 5 == 0:
			_trigger_draft())
```

- [ ] **Steg 4: Lägg till wave_gold relic-effekt**

I `main.gd`, hitta `_ready()`-sektionen. Lägg till **efter** `GameState.wave_completed.connect(...)`-blocket:

```gdscript
	GameState.wave_started.connect(func(_wave_num: int, _banner: String) -> void:
		for relic: Dictionary in GameState.active_relics:
			if relic.effect == "wave_gold":
				GameState.add_gold(int(relic.value)))
```

- [ ] **Steg 5: Anslut relic_draft_ready i HUD._connect_signals()**

I `maul/ui/HUD.gd`, hitta `_connect_signals()`. Lägg till i slutet:

```gdscript
	GameState.relic_draft_ready.connect(_on_relic_draft_ready)
	GameState.relic_acquired.connect(_on_relic_acquired)
```

- [ ] **Steg 6: Bygg relic draft overlay i HUD._build_ui()**

I `HUD.gd`, lägg till dessa node-deklarationer **efter** `var _draft_cards: Array[Button] = []`:

```gdscript
var _relic_draft_overlay: Control
var _relic_draft_cards: Array[Button] = []
var _relic_strip_hbox: HBoxContainer
```

I `_build_ui()`, **direkt efter** `cl.add_child(_draft_overlay)` + dess innehåll men **före** start_screen, lägg till:

```gdscript
	# ── Relic draft overlay ───────────────────────────────────────
	_relic_draft_overlay = ColorRect.new()
	(_relic_draft_overlay as ColorRect).color = Color(0.04, 0.05, 0.08, 0.95)
	_relic_draft_overlay.set_anchor(SIDE_LEFT,   0.0)
	_relic_draft_overlay.set_anchor(SIDE_RIGHT,  1.0)
	_relic_draft_overlay.set_anchor(SIDE_TOP,    0.0)
	_relic_draft_overlay.set_anchor(SIDE_BOTTOM, 1.0)
	_relic_draft_overlay.visible = false
	cl.add_child(_relic_draft_overlay)

	var rd_center := CenterContainer.new()
	rd_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_relic_draft_overlay.add_child(rd_center)

	var rd_vbox := VBoxContainer.new()
	rd_vbox.add_theme_constant_override("separation", 14)
	rd_center.add_child(rd_vbox)

	var rd_title := Label.new()
	rd_title.text = "CHOOSE A RELIC"
	rd_title.add_theme_font_size_override("font_size", 18)
	rd_title.add_theme_color_override("font_color", Color(1.0, 0.75, 0.1))
	rd_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rd_vbox.add_child(rd_title)

	var rd_sub := Label.new()
	rd_sub.text = "— global passive —"
	rd_sub.add_theme_font_size_override("font_size", 10)
	rd_sub.add_theme_color_override("font_color", Color(0.40, 0.42, 0.50))
	rd_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rd_vbox.add_child(rd_sub)

	var rd_cards_hbox := HBoxContainer.new()
	rd_cards_hbox.add_theme_constant_override("separation", 12)
	rd_vbox.add_child(rd_cards_hbox)

	for _i in 3:
		var card := Button.new()
		card.custom_minimum_size = Vector2(128, 160)
		card.visible = false
		rd_cards_hbox.add_child(card)
		_relic_draft_cards.append(card)
```

- [ ] **Steg 7: Lägg till _on_relic_draft_ready() och _on_relic_acquired() i HUD**

Lägg till i slutet av HUD.gd (före eller efter `_on_draft_pick`):

```gdscript
func _on_relic_draft_ready(offer: Array[Dictionary]) -> void:
	for i in _relic_draft_cards.size():
		var card: Button = _relic_draft_cards[i]
		if i >= offer.size():
			card.visible = false
			continue
		var rel: Dictionary = offer[i]
		card.visible = true
		card.text = "%s\n%s\n\n%s" % [rel.icon, rel.name, rel.desc]
		card.add_theme_font_size_override("font_size", 13)
		# Disconnect previous connections
		if card.pressed.is_connected(_on_relic_pick.bind(i)):
			card.pressed.disconnect(_on_relic_pick.bind(i))
		card.pressed.connect(_on_relic_pick.bind(offer[i]))
		var rsb := StyleBoxFlat.new()
		rsb.bg_color                       = Color(0.12, 0.10, 0.06)
		rsb.corner_radius_top_left         = 10
		rsb.corner_radius_top_right        = 10
		rsb.corner_radius_bottom_left      = 10
		rsb.corner_radius_bottom_right     = 10
		rsb.border_width_left              = 2
		rsb.border_width_right             = 2
		rsb.border_width_top               = 2
		rsb.border_width_bottom            = 2
		rsb.border_color                   = Color(1.0, 0.75, 0.1, 0.7)
		card.add_theme_stylebox_override("normal",  rsb)
		var rsh := rsb.duplicate() as StyleBoxFlat
		rsh.border_color = Color(1.0, 0.90, 0.3)
		card.add_theme_stylebox_override("hover",   rsh)
		card.add_theme_stylebox_override("pressed", rsh)
	_relic_draft_overlay.visible = true


func _on_relic_pick(relic: Dictionary) -> void:
	GameState.acquire_relic(relic)
	GameState.draft_pending = false
	_relic_draft_overlay.visible = false


func _on_relic_acquired(_relic: Dictionary) -> void:
	_rebuild_relic_strip()
```

- [ ] **Steg 8: Verifiera**

Kör spelet. Slutför wave 10 (eller sänd wave tidigt 10 gånger). Draft-overlay för relic ska visas (3 guld-stylade kort). Klicka ett — overlay stängs, relic sparas i GameState.active_relics. Inga fel i Output.

```bash
git add maul/main.gd maul/ui/HUD.gd maul/autoload/GameState.gd
git commit -m "feat: relic draft every 10th wave with selection UI"
```

---

## Task 6: Relic Strip i HUD + Synergy Toast

**Files:**
- Modify: `maul/ui/HUD.gd`

- [ ] **Steg 1: Relic strip — node-deklaration**

`_relic_strip_hbox` deklarerades redan i Task 5. Nu byggs den.

I `_build_ui()`, **i top_bar-sektionen**, direkt **efter** `outer_hbox.add_child(spacer2)` (den andra spacern), lägg till:

```gdscript
	# Relic strip (höger om spacer2, vänster om right_margin)
	_relic_strip_hbox = HBoxContainer.new()
	_relic_strip_hbox.add_theme_constant_override("separation", 4)
	_relic_strip_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	outer_hbox.add_child(_relic_strip_hbox)
```

- [ ] **Steg 2: _rebuild_relic_strip()**

Lägg till i HUD.gd (kan ligga med övriga private helpers):

```gdscript
func _rebuild_relic_strip() -> void:
	for child in _relic_strip_hbox.get_children():
		child.queue_free()
	for relic: Dictionary in GameState.active_relics:
		var lbl := Label.new()
		lbl.text = relic.icon
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.tooltip_text = relic.name + "\n" + relic.desc
		_relic_strip_hbox.add_child(lbl)
```

- [ ] **Steg 3: Anslut synergy_activated till toast**

I `_connect_signals()`, lägg till:

```gdscript
	GameState.synergy_activated.connect(_on_synergy_activated)
```

- [ ] **Steg 4: Toast-notis för nya synergier**

Lägg till node-deklaration **bland övriga variabler** i HUD.gd:

```gdscript
var _toast_lbl: Label
```

I `_build_ui()`, **precis efter** `cl.add_child(_status_lbl)`:

```gdscript
	_toast_lbl = Label.new()
	_toast_lbl.position = Vector2(0, 72)
	_toast_lbl.set_anchor(SIDE_LEFT,  0.0)
	_toast_lbl.set_anchor(SIDE_RIGHT, 1.0)
	_toast_lbl.add_theme_font_size_override("font_size", 13)
	_toast_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 0.0))
	_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(_toast_lbl)
```

- [ ] **Steg 5: _on_synergy_activated()**

```gdscript
func _on_synergy_activated(syn_id: String, syn_name: String, syn_icon: String) -> void:
	_toast_lbl.text = "%s  SYNERGI: %s" % [syn_icon, syn_name]
	_toast_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	var tw := get_tree().create_tween()
	tw.tween_interval(2.0)
	tw.tween_method(
		func(a: float) -> void:
			_toast_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, a)),
		1.0, 0.0, 0.6
	)
```

- [ ] **Steg 6: Återställ relic strip vid game_restarted**

I `_on_game_restarted()`, lägg till i slutet:

```gdscript
	_rebuild_relic_strip()
```

- [ ] **Steg 7: Verifiera**

Kör spelet. Placera Morteln (8) + Hot Stone (20). Texten "🔥 SYNERGI: Slow Roast" ska dyka upp och fade ut. Placera 3 Disc-torn → "🥏 SYNERGI: Full Bag" toastar. Ta ett relic via wave 10 draft → ikonen syns i top bar.

```bash
git add maul/ui/HUD.gd
git commit -m "feat: relic strip in HUD and synergy toast notifications"
```

---

## Task 7: Wave Preview

**Files:**
- Modify: `maul/ui/HUD.gd`
- Modify: `maul/main.gd`

Visa nästa waves namn, typ och fiendeantal i countdown-rutan innan waven startar.

- [ ] **Steg 1: Lägg till _wave_preview_lbl**

I HUD.gd, **bland node-deklarationerna**:

```gdscript
var _wave_preview_lbl: Label
```

I `_build_ui()`, **precis efter** `cl.add_child(_toast_lbl)`:

```gdscript
	_wave_preview_lbl = Label.new()
	_wave_preview_lbl.set_anchor(SIDE_LEFT,   0.0)
	_wave_preview_lbl.set_anchor(SIDE_RIGHT,  1.0)
	_wave_preview_lbl.set_anchor(SIDE_TOP,    1.0)
	_wave_preview_lbl.set_anchor(SIDE_BOTTOM, 1.0)
	_wave_preview_lbl.set_offset(SIDE_TOP,    -112)
	_wave_preview_lbl.set_offset(SIDE_BOTTOM, -56)
	_wave_preview_lbl.add_theme_font_size_override("font_size", 11)
	_wave_preview_lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.75))
	_wave_preview_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_preview_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(_wave_preview_lbl)
```

- [ ] **Steg 2: Lägg till update_wave_preview() public-metod**

I HUD.gd, lägg till:

```gdscript
func update_wave_preview(next_wave: int) -> void:
	if next_wave > WaveDefs.count():
		_wave_preview_lbl.text = ""
		return
	var wd := WaveDefs.get_wave(next_wave)
	var tags: Array[String] = []
	if wd.flies:
		tags.append("AIR")
	match wd.special:
		WaveDefs.SPECIAL_BOSS:       tags.append("BOSS")
		WaveDefs.SPECIAL_FINAL_BOSS: tags.append("FINAL BOSS")
		WaveDefs.SPECIAL_MASS:       tags.append("SWARM")
		WaveDefs.SPECIAL_MAGIC_IMMUNE: tags.append("MAGIC IMMUNE")
		WaveDefs.SPECIAL_INVISIBLE:  tags.append("INVISIBLE")
	var tag_str: String = "  •  ".join(tags) if not tags.is_empty() else ""
	var suffix := ("  —  " + tag_str) if tag_str else ""
	_wave_preview_lbl.text = "NEXT: %s  ×%d%s" % [wd.name, wd.count, suffix]
```

- [ ] **Steg 3: Anropa update_wave_preview i main.gd**

I `main.gd`, hitta `update_countdown()`-anropet i `_process()`:

```gdscript
		_hud.update_countdown(GameState.wave_countdown, GameState.wave + 1)
```

Ersätt med:

```gdscript
		_hud.update_countdown(GameState.wave_countdown, GameState.wave + 1)
		_hud.update_wave_preview(GameState.wave + 1)
```

- [ ] **Steg 4: Göm preview under pågående wave**

I HUD `_on_wave_started()`, lägg till:

```gdscript
	_wave_preview_lbl.text = ""
```

- [ ] **Steg 5: Verifiera**

Kör spelet. Mellan waves ska texten "NEXT: Tomte ×12" eller liknande visas. Air-waves ska ha "AIR" i sufixet, boss-waves "BOSS".

```bash
git add maul/ui/HUD.gd maul/main.gd
git commit -m "feat: wave preview label shows next wave details during countdown"
```

---

## Task 8: Run Summary Screen

**Files:**
- Modify: `maul/ui/HUD.gd`
- Modify: `maul/autoload/GameState.gd`

En panel som visas vid game over med: wave nådd, torn använda, aktiva synergier, innehavda relics, bäst-wave-rekord.

- [ ] **Steg 1: Node-deklaration i HUD**

```gdscript
var _summary_overlay: Control
var _summary_wave_lbl:    Label
var _summary_towers_lbl:  Label
var _summary_syn_lbl:     Label
var _summary_relic_lbl:   Label
var _summary_best_lbl:    Label
```

- [ ] **Steg 2: Bygg summary overlay i _build_ui()**

Lägg till **precis innan** `cl.add_child(_start_screen)` (summary renderas under start screen):

```gdscript
	# ── Run Summary overlay ─────────────────────────────────────
	_summary_overlay = ColorRect.new()
	(_summary_overlay as ColorRect).color = Color(0.04, 0.05, 0.08, 0.96)
	_summary_overlay.set_anchor(SIDE_LEFT,   0.0)
	_summary_overlay.set_anchor(SIDE_RIGHT,  1.0)
	_summary_overlay.set_anchor(SIDE_TOP,    0.0)
	_summary_overlay.set_anchor(SIDE_BOTTOM, 1.0)
	_summary_overlay.visible = false
	cl.add_child(_summary_overlay)

	var sum_center := CenterContainer.new()
	sum_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_summary_overlay.add_child(sum_center)

	var sum_vbox := VBoxContainer.new()
	sum_vbox.add_theme_constant_override("separation", 10)
	sum_center.add_child(sum_vbox)

	var sum_title := Label.new()
	sum_title.text = "RUN OVER"
	sum_title.add_theme_font_size_override("font_size", 32)
	sum_title.add_theme_color_override("font_color", Color(0.95, 0.25, 0.35))
	sum_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sum_vbox.add_child(sum_title)

	var sum_panel := PanelContainer.new()
	var sum_style := StyleBoxFlat.new()
	sum_style.bg_color                       = Color(0.08, 0.10, 0.15)
	sum_style.corner_radius_top_left         = 12
	sum_style.corner_radius_top_right        = 12
	sum_style.corner_radius_bottom_left      = 12
	sum_style.corner_radius_bottom_right     = 12
	sum_panel.add_theme_stylebox_override("panel", sum_style)
	sum_panel.custom_minimum_size = Vector2(260, 0)
	sum_vbox.add_child(sum_panel)

	var sum_m := MarginContainer.new()
	sum_m.add_theme_constant_override("margin_left",   20)
	sum_m.add_theme_constant_override("margin_right",  20)
	sum_m.add_theme_constant_override("margin_top",    16)
	sum_m.add_theme_constant_override("margin_bottom", 16)
	sum_panel.add_child(sum_m)

	var sum_inner := VBoxContainer.new()
	sum_inner.add_theme_constant_override("separation", 8)
	sum_m.add_child(sum_inner)

	_summary_wave_lbl   = Label.new()
	_summary_towers_lbl = Label.new()
	_summary_syn_lbl    = Label.new()
	_summary_relic_lbl  = Label.new()
	_summary_best_lbl   = Label.new()

	for lbl: Label in [_summary_wave_lbl, _summary_towers_lbl,
			_summary_syn_lbl, _summary_relic_lbl, _summary_best_lbl]:
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.80, 0.82, 0.90))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sum_inner.add_child(lbl)

	_summary_best_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))

	var sum_close := Button.new()
	sum_close.text = "BACK TO MENU"
	sum_close.add_theme_font_size_override("font_size", 16)
	sum_close.custom_minimum_size = Vector2(0, 48)
	var scn := StyleBoxFlat.new()
	scn.bg_color = Color(0.15, 0.18, 0.25)
	scn.corner_radius_top_left    = 8; scn.corner_radius_top_right    = 8
	scn.corner_radius_bottom_left = 8; scn.corner_radius_bottom_right = 8
	sum_close.add_theme_stylebox_override("normal", scn)
	sum_close.pressed.connect(func() -> void:
		_summary_overlay.visible = false
		_start_screen.visible    = true)
	sum_vbox.add_child(sum_close)
```

- [ ] **Steg 3: Lägg till show_run_summary() public-metod**

```gdscript
func show_run_summary() -> void:
	var wave_reached: int = GameState.wave
	_summary_wave_lbl.text = "📊 Wave nådd: %d / 40" % wave_reached

	# Unika torn-typer som placerats (från GameState.towers, men vi behöver historik)
	# Vi visar unlocked_towers istället som proxy
	var tower_names: Array[String] = []
	for idx: int in GameState.unlocked_towers:
		tower_names.append(TowerDefs.NAMES[idx])
	_summary_towers_lbl.text = "🏗 Torn upplåsta: " + ", ".join(tower_names)

	if GameState.active_synergies.is_empty():
		_summary_syn_lbl.text = "🔗 Synergier: —"
	else:
		var syn_names: Array[String] = []
		for sid: String in GameState.active_synergies:
			for syn: Dictionary in SynergyDefs.SYNERGIES:
				if syn.id == sid:
					syn_names.append(syn.icon + " " + syn.name)
		_summary_syn_lbl.text = "🔗 Synergier: " + ", ".join(syn_names)

	if GameState.active_relics.is_empty():
		_summary_relic_lbl.text = "✨ Relics: —"
	else:
		var relic_names: Array[String] = []
		for rel: Dictionary in GameState.active_relics:
			relic_names.append(rel.icon + " " + rel.name)
		_summary_relic_lbl.text = "✨ Relics: " + ", ".join(relic_names)

	_summary_best_lbl.text = "🏆 Bäst: Wave %d  •  Runs: %d" % [
		GameState.best_wave, GameState.runs_played]

	_summary_overlay.visible = true
```

- [ ] **Steg 4: Anropa show_run_summary från main.gd vid game over**

I `main.gd`, i `_check_wave_end()`, hitta:

```gdscript
		GameState.game_over_triggered.emit()
		return
```

Lägg till **direkt före `return`**:

```gdscript
		GameState.runs_played += 1
		if GameState.wave > GameState.best_wave:
			GameState.best_wave = GameState.wave
		_hud.show_run_summary()
```

- [ ] **Steg 5: Göm summary vid restart**

I HUD `_on_game_restarted()`, lägg till:

```gdscript
	_summary_overlay.visible = false
```

- [ ] **Steg 6: Verifiera**

Kör spelet. Låt fiender nå målet (game over). Run Summary ska visas med wave, torn, synergier, relics. "BACK TO MENU" ska ta tillbaka till start screen.

```bash
git add maul/ui/HUD.gd maul/main.gd
git commit -m "feat: run summary overlay on game over"
```

---

## Task 9: Meta-Progression (JSON save)

**Files:**
- Modify: `maul/autoload/GameState.gd`
- Modify: `maul/ui/HUD.gd`

Spara best_wave och runs_played till disk. Visa rekord på start screen.

- [ ] **Steg 1: save_meta() och load_meta() i GameState**

I `maul/autoload/GameState.gd`, lägg till **i slutet av filen**:

```gdscript
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
```

- [ ] **Steg 2: Anropa load_meta() vid _ready() i GameState**

Längst upp i GameState, lägg till en `_ready()` om den inte finns (den saknas förmodligen):

```gdscript
func _ready() -> void:
	load_meta()
```

- [ ] **Steg 3: Anropa save_meta() vid game over i main.gd**

I `_check_wave_end()`, direkt **efter** `GameState.runs_played += 1` och bäst-wave-uppdateringen (lagt till i Task 8), lägg till:

```gdscript
		GameState.save_meta()
```

- [ ] **Steg 4: Visa rekord på start screen i HUD**

I HUD.gd, lägg till node-deklaration:

```gdscript
var _sc_best_lbl: Label
```

I `_build_ui()`, **direkt efter** `svbox.add_child(sc_footer)` (sista label i start screen):

```gdscript
	_sc_best_lbl = Label.new()
	_sc_best_lbl.add_theme_font_size_override("font_size", 11)
	_sc_best_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_sc_best_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	svbox.add_child(_sc_best_lbl)
	_update_best_label()
```

Lägg till metoden:

```gdscript
func _update_best_label() -> void:
	if GameState.best_wave == 0:
		_sc_best_lbl.text = ""
	else:
		_sc_best_lbl.text = "🏆 Best: Wave %d  •  Runs: %d" % [
			GameState.best_wave, GameState.runs_played]
```

I `_on_game_restarted()`, lägg till:

```gdscript
	_update_best_label()
```

- [ ] **Steg 5: Verifiera**

Kör spelet. Spela tills game over. Starta om. Start screen ska visa "🏆 Best: Wave X • Runs: 1". Stäng Godot, öppna igen, bäst-wave ska fortfarande visas.

```bash
git add maul/autoload/GameState.gd maul/ui/HUD.gd
git commit -m "feat: meta-progression save/load with best wave and run count"
```

---

## Self-Review

### Spec coverage

Kontrollerar alla krav från de tre agenterna:

| Krav | Task |
|------|------|
| Tower synergier (Slow Roast, Disc, Caffeine) | Task 1 + 3 + 4 |
| Visuell feedback vid synergi (toast) | Task 6 |
| Relic-system (6 relics, var 10:e wave) | Task 2 + 5 |
| Relic-ikoner i HUD | Task 6 |
| Wave preview (nästa wave-typ) | Task 7 |
| Run summary screen | Task 8 |
| Meta-progression (JSON save) | Task 9 |
| Relic-effekter i spelloopen | Task 4 |

### Placeholder-scan

Inga "TBD" eller "implement later" — varje steg innehåller exakt kod.

### Typkonsistens

- `active_synergies: Array[String]` — IDs används konsekvent i alla tasks
- `active_relics: Array[Dictionary]` — hela relic-dicts, `.effect` och `.value` används konsekvent
- `_refresh_synergies()` anropas i Task 3 (def) och Task 4 (anrop)
- `relic_draft_ready` signal definieras i Task 5 steg 2, används i steg 3
- `_rebuild_relic_strip()` anropas i `_on_relic_acquired()` (Task 5) — definieras i Task 6
