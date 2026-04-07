# Personal Tower Draft System — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ersätt det gudsbaserade tornsystemet med ett personligt draft-system där alla 21 torn (Discgolf, Matlagning, Snus, Kaffe, Gitarr, Muay Thai, Massage) ligger i en gemensam pool och spelaren draftar 1 av 3 slumpmässiga torn var 5:e våg.

**Arkitektur:** TowerDefs skrivs om med 21 nya torn och nya dataarrayar för slow/DoT/lore. GameState får `unlocked_towers` och draft-state. HUD:ens gudvalsskärm ersätts med en draft-overlay som aktiveras via signal från main.gd. Slow och DoT appliceras i `_apply_damage` och tickas i `_tick_enemies`.

**Tech Stack:** Godot 4, GDScript, allt i befintliga filer — ingen ny filstruktur.

---

## Filöversikt

| Fil | Förändring |
|-----|-----------|
| `maul/data/TowerDefs.gd` | Komplett omskrivning — 21 nya torn, nya SLOW/DOT/LORE-arrays |
| `maul/autoload/GameState.gd` | Lägg till `unlocked_towers`, `draft_pending`, ny signal `draft_ready` |
| `maul/main.gd` | Slow/DoT i `_apply_damage` + `_tick_enemies`, draft-trigger i `_on_wave_completed`, nya tornformer i `_draw_tower`, slow-visuell effekt på fiender |
| `maul/ui/HUD.gd` | Ta bort gudval från startskärmen, lägg till `_build_draft_overlay`, koppla `draft_ready`-signal |

---

## Task 1: Skriv om TowerDefs.gd

**Fil:** `maul/data/TowerDefs.gd`

Alla 21 torn, indexerade 0–20. Befintliga arrays (NAMES, SIZES, RANGE, DAMAGE, FIRERATE, COST, AOE, SPLASH, AIR_MULT, FILL, STROKE, ANIM_SHEET, ANIM_ROW, ANIM_FPS) byts ut helt. Fyra nya arrays läggs till: SLOW, SLOW_DUR, DOT, DOT_DUR, LORE.

### Tornlista med stats

| # | Namn | Tema | Cost | Dmg | Range | Fire/s | AOE | Splash | Slow | SlowDur | DoT | DotDur |
|---|------|------|------|-----|-------|--------|-----|--------|------|---------|-----|--------|
| 0 | Destroyer | Disc | 200 | 85 | 7.0 | 0.60 | N | 0.0 | 0.00 | 0.0 | 0 | 0.0 |
| 1 | Buzzz | Disc | 150 | 45 | 4.5 | 1.00 | Y | 0.5 | 0.00 | 0.0 | 0 | 0.0 |
| 2 | Aviar | Disc | 400 | 180 | 2.5 | 0.30 | N | 0.0 | 0.00 | 0.0 | 0 | 0.0 |
| 3 | Hatchet | Disc | 250 | 40 | 4.0 | 0.90 | Y | 0.8 | 0.00 | 0.0 | 0 | 0.0 |
| 4 | Pure | Disc | 600 | 150 | 9.0 | 0.35 | N | 0.0 | 0.00 | 0.0 | 0 | 0.0 |
| 5 | Gjutjärnspannan | Mat | 350 | 160 | 2.5 | 0.30 | Y | 1.2 | 0.00 | 0.0 | 0 | 0.0 |
| 6 | Sous Vide | Mat | 150 | 20 | 4.0 | 1.50 | N | 0.0 | 0.00 | 0.0 | 15 | 3.0 |
| 7 | Woken | Mat | 200 | 35 | 3.0 | 1.40 | Y | 0.4 | 0.00 | 0.0 | 0 | 0.0 |
| 8 | Morteln | Mat | 250 | 25 | 2.5 | 0.80 | Y | 0.6 | 0.40 | 2.0 | 0 | 0.0 |
| 9 | Göteborgs Rapé | Snus | 100 | 15 | 3.5 | 1.00 | N | 0.0 | 0.25 | 2.5 | 0 | 0.0 |
| 10 | General White | Snus | 200 | 12 | 4.0 | 1.10 | N | 0.0 | 0.00 | 0.0 | 10 | 3.0 |
| 11 | Oden's Extreme | Snus | 400 | 60 | 1.8 | 0.70 | Y | 1.0 | 0.50 | 2.0 | 0 | 0.0 |
| 12 | Siberia | Snus | 700 | 280 | 2.0 | 0.25 | N | 0.0 | 0.00 | 0.0 | 0 | 0.0 |
| 13 | Ristretto | Kaffe | 300 | 200 | 2.5 | 0.20 | N | 0.0 | 0.00 | 0.0 | 0 | 0.0 |
| 14 | Cold Brew | Kaffe | 150 | 18 | 4.5 | 1.30 | N | 0.0 | 0.15 | 2.0 | 8 | 4.0 |
| 15 | Chemex | Kaffe | 550 | 150 | 9.0 | 0.40 | N | 0.0 | 0.00 | 0.0 | 0 | 0.0 |
| 16 | Ernie Ball | Gitarr | 150 | 22 | 3.5 | 2.00 | N | 0.0 | 0.00 | 0.0 | 0 | 0.0 |
| 17 | Tube Screamer | Gitarr | 300 | 50 | 3.5 | 0.80 | Y | 0.7 | 0.00 | 0.0 | 0 | 0.0 |
| 18 | Roundhouse | Muay Thai | 200 | 55 | 2.8 | 0.75 | Y | 0.6 | 0.00 | 0.0 | 0 | 0.0 |
| 19 | Elbow | Muay Thai | 500 | 220 | 1.5 | 0.35 | N | 0.0 | 0.00 | 0.0 | 0 | 0.0 |
| 20 | Hot Stone | Massage | 200 | 30 | 3.8 | 1.00 | N | 0.0 | 0.00 | 0.0 | 20 | 3.0 |

- [ ] **Steg 1.1: Skriv om TowerDefs.gd**

```gdscript
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

# Slow: bråkdel av hastighetsminskning (0.0 = ingen slow, 0.5 = 50% långsammare)
const SLOW := [
	0.00, 0.00, 0.00, 0.00, 0.00,
	0.00, 0.00, 0.00, 0.40,
	0.25, 0.00, 0.50, 0.00,
	0.00, 0.15, 0.00,
	0.00, 0.00,
	0.00, 0.00,
	0.00,
]

# Slow-duration i sekunder
const SLOW_DUR := [
	0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 2.0,
	2.5, 0.0, 2.0, 0.0,
	0.0, 2.0, 0.0,
	0.0, 0.0,
	0.0, 0.0,
	0.0,
]

# DoT: skada per sekund
const DOT := [
	0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 15.0, 0.0, 0.0,
	0.0, 10.0, 0.0, 0.0,
	0.0, 8.0, 0.0,
	0.0, 0.0,
	0.0, 0.0,
	20.0,
]

# DoT-duration i sekunder
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

# Oanvända men behålls för bakåtkompatibilitet med _draw_tower animation-refs
const ANIM_SHEET := []
const ANIM_ROW   := []
const ANIM_FPS   := []

static func count() -> int:
	return NAMES.size()
```

- [ ] **Steg 1.2: Commit**
```bash
git add maul/data/TowerDefs.gd
git commit -m "feat: rewrite TowerDefs with 21 personal towers (disc/food/snus/coffee/guitar/muay thai/massage)"
```

---

## Task 2: Lägg till draft-state i GameState

**Fil:** `maul/autoload/GameState.gd`

- [ ] **Steg 2.1: Lägg till nya variabler och signal**

Lägg till direkt efter `var selected_god: int = 0`:

```gdscript
signal draft_ready(offer: Array[int])   # emittas med 3 tornindex

var unlocked_towers: Array[int] = []    # vilka torn spelaren fått via draft
var draft_pending:   bool       = false # väntar på spelarens val
```

- [ ] **Steg 2.2: Uppdatera reset() — nollställ draft-state**

Lägg till i `reset()` efter `selected_god = 0`:

```gdscript
unlocked_towers.clear()
draft_pending = false
```

- [ ] **Steg 2.3: Commit**
```bash
git add maul/autoload/GameState.gd
git commit -m "feat: add unlocked_towers and draft_pending to GameState"
```

---

## Task 3: Slow och DoT-mekanik i main.gd

**Fil:** `maul/main.gd`

Slow och DoT lagras per fiende i deras dict. Slow påverkar rörelsehastigheten i `_tick_enemies`. DoT tickas i en ny funktion.

- [ ] **Steg 3.1: Applicera slow och DoT i `_apply_damage`**

Hitta `func _apply_damage(e: Dictionary, damage: float, creep_gold: int) -> void:` och lägg till slow/DoT-applicering:

```gdscript
func _apply_damage(e: Dictionary, damage: float, creep_gold: int,
		tower_type: int = -1) -> void:
	e.hp -= damage
	# Applicera slow
	if tower_type >= 0 and TowerDefs.SLOW[tower_type] > 0.0:
		e["slow_factor"] = TowerDefs.SLOW[tower_type]
		e["slow_t"]      = TowerDefs.SLOW_DUR[tower_type]
	# Applicera DoT (ersätter befintlig om starkare)
	if tower_type >= 0 and TowerDefs.DOT[tower_type] > 0.0:
		if TowerDefs.DOT[tower_type] >= e.get("dot_dps", 0.0):
			e["dot_dps"] = TowerDefs.DOT[tower_type]
			e["dot_t"]   = TowerDefs.DOT_DUR[tower_type]
	if e.hp <= 0.0:
		e.hp   = 0.0
		e.dead = true
		var kg: int = creep_gold
		GameState.add_gold(kg)
		if not e.get("flying", false):
			GameState.corpses.append({
				pos        = e.pos,
				is_boss    = e.get("is_boss", false),
				face_right = e.get("face_right", true),
				timer      = 0.0,
			})
		e["hit_flash"] = 0.0
	else:
		e["hit_flash"] = 0.15
```

Obs: Ta bort den gamla kroppen av `_apply_damage` och ersätt med koden ovan. Resten av funktionen (corpse-logiken) var redan där — se till att du inte duplicerar den.

- [ ] **Steg 3.2: Skicka `tower_type` från `_tick_projectiles` till `_apply_damage`**

Hitta de två anropen till `_apply_damage` i `_tick_projectiles` och lägg till `p.tower_type`:

```gdscript
# AOE-träff:
_apply_damage(e, p.damage, creep_gold, p.tower_type)
# Singel-träff:
_apply_damage(p.target, p.damage, creep_gold, p.tower_type)
```

- [ ] **Steg 3.3: Ticka slow och DoT i `_tick_enemies`**

Hitta `func _tick_enemies` (sök på `e.wp_idx` eller `e.speed`). Lägg till i loopen över levande fiender, direkt efter `if e.dead: continue`:

```gdscript
# Ticka DoT
if e.get("dot_t", 0.0) > 0.0:
    e["dot_t"] -= delta
    var creep_gold_dot: int = WaveDefs.get_wave(GameState.wave).bounty
    _apply_damage(e, e["dot_dps"] * delta, creep_gold_dot)
    if e.dead:
        continue

# Räkna ner slow
if e.get("slow_t", 0.0) > 0.0:
    e["slow_t"] -= delta
    if e["slow_t"] <= 0.0:
        e["slow_factor"] = 0.0
```

- [ ] **Steg 3.4: Applicera slow på fiendens rörelsehastighet**

Hitta stället i `_tick_enemies` där `e.pos` uppdateras (se efter `move` eller `speed`). Ändra rörelsehastigheten:

```gdscript
var eff_speed: float = e.speed * (1.0 - e.get("slow_factor", 0.0))
```

Ersätt `e.speed` med `eff_speed` vid positionsuppdateringen.

- [ ] **Steg 3.5: Rendera slow-effekt på fiender**

I `_draw_enemy`, lägg till en blå ring runt slowade fiender. Hitta `func _draw_enemy` och lägg till i slutet av funktionen (efter HP-baren):

```gdscript
# Slow-indikator — blå ring
if e.get("slow_t", 0.0) > 0.0:
    var sr: float = 14.0 if e.get("is_boss", false) else 9.0
    draw_arc(e.pos, sr, 0.0, TAU, 16, Color(0.40, 0.65, 1.00, 0.70), 1.5)

# DoT-indikator — orange ring
if e.get("dot_t", 0.0) > 0.0:
    var dr: float = 12.0 if e.get("is_boss", false) else 8.0
    draw_arc(e.pos, dr, 0.0, TAU, 16, Color(1.00, 0.55, 0.15, 0.70), 1.5)
```

- [ ] **Steg 3.6: Commit**
```bash
git add maul/main.gd
git commit -m "feat: add slow and DoT mechanics — applied in _apply_damage, ticked in _tick_enemies"
```

---

## Task 4: Draft-trigger i main.gd

**Fil:** `maul/main.gd`

Draft triggas varje gång en våg slutar och `wave % 5 == 0`. Vid spelets start ges 2 slumpmässiga torn direkt.

- [ ] **Steg 4.1: Koppla `wave_completed`-signal och trigga draft**

Hitta `_hud.tower_selected.connect(...)` i `_ready` och lägg till:

```gdscript
GameState.wave_completed.connect(_on_wave_completed_draft)
```

Lägg sedan till funktionen (t.ex. efter `_on_wave_completed`):

```gdscript
func _on_wave_completed_draft(wave_num: int, _bonus: int) -> void:
    if wave_num % 5 == 0:
        _trigger_draft()


func _trigger_draft() -> void:
    var pool: Array[int] = []
    for i in TowerDefs.count():
        if not GameState.unlocked_towers.has(i):
            pool.append(i)
    pool.shuffle()
    var offer: Array[int] = pool.slice(0, mini(3, pool.size()))
    GameState.draft_pending = true
    GameState.draft_ready.emit(offer)
```

- [ ] **Steg 4.2: Ge 2 startorn när spelet börjar**

Hitta `func _do_start` i HUD.gd (eller platsen i main.gd där `game_started` sätts). I `main.gd`, hitta signalkopplingen för `map_selected` eller var `Pathfinder.rebuild` anropas första gången. Lägg till ett anrop till en ny hjälpfunktion:

```gdscript
func _give_starting_towers() -> void:
    var all: Array[int] = range(TowerDefs.count())
    all.shuffle()
    for i in mini(2, all.size()):
        GameState.unlocked_towers.append(all[i])
```

Anropa `_give_starting_towers()` från `_on_map_selected` eller när `game_started` sätts till `true`.

- [ ] **Steg 4.3: Koppla draft-signal i HUD**

I `HUD._connect_signals()`, lägg till:

```gdscript
GameState.draft_ready.connect(_on_draft_ready)
```

- [ ] **Steg 4.4: Commit**
```bash
git add maul/main.gd maul/ui/HUD.gd
git commit -m "feat: draft trigger — 2 starting towers + offer every 5 waves"
```

---

## Task 5: Draft-overlay i HUD

**Fil:** `maul/ui/HUD.gd`

Draft-overlayern visas ovanpå spelet när `draft_ready` emittas. Spelaren ser 3 kort (ett per erbjudet torn) med namn, tema, stats och lore. Tryck på ett kort → torn läggs till `unlocked_towers` → overlay stängs.

- [ ] **Steg 5.1: Lägg till variabler**

I Node references-sektionen:

```gdscript
var _draft_overlay: Control
var _draft_cards:   Array[Button] = []
```

- [ ] **Steg 5.2: Bygg draft-overlay i `_build_ui`**

Lägg till i slutet av `_build_ui`, precis innan `_start_screen` byggs (start-skärmen ska renderas ovanpå):

```gdscript
# ── Draft overlay ─────────────────────────────────────────────
_draft_overlay = ColorRect.new()
(_draft_overlay as ColorRect).color = Color(0.04, 0.05, 0.08, 0.94)
_draft_overlay.set_anchor(SIDE_LEFT,   0.0)
_draft_overlay.set_anchor(SIDE_RIGHT,  1.0)
_draft_overlay.set_anchor(SIDE_TOP,    0.0)
_draft_overlay.set_anchor(SIDE_BOTTOM, 1.0)
_draft_overlay.visible = false
cl.add_child(_draft_overlay)

var do_vbox := VBoxContainer.new()
do_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
do_vbox.add_theme_constant_override("separation", 14)
do_vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
_draft_overlay.add_child(do_vbox)

var do_title := Label.new()
do_title.text = "CHOOSE YOUR NEXT TOWER"
do_title.add_theme_font_size_override("font_size", 18)
do_title.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0))
do_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
do_vbox.add_child(do_title)

var do_sub := Label.new()
do_sub.text = "— pick 1 —"
do_sub.add_theme_font_size_override("font_size", 10)
do_sub.add_theme_color_override("font_color", Color(0.40, 0.42, 0.50))
do_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
do_vbox.add_child(do_sub)

var do_cards_hbox := HBoxContainer.new()
do_cards_hbox.add_theme_constant_override("separation", 12)
do_vbox.add_child(do_cards_hbox)

# Tre platshållar-knappar — byggs om i _on_draft_ready
for _i in 3:
    var card := Button.new()
    card.custom_minimum_size = Vector2(128, 180)
    card.visible = false
    do_cards_hbox.add_child(card)
    _draft_cards.append(card)
```

- [ ] **Steg 5.3: Implementera `_on_draft_ready`**

```gdscript
func _on_draft_ready(offer: Array[int]) -> void:
    for i in _draft_cards.size():
        var card := _draft_cards[i]
        if i >= offer.size():
            card.visible = false
            continue
        var t := offer[i]
        var stroke: Color = TowerDefs.STROKE[t]

        # Rensa gamla signal-kopplingar
        for conn in card.pressed.get_connections():
            card.pressed.disconnect(conn["callable"])

        # Stil
        var sb := StyleBoxFlat.new()
        sb.bg_color                       = Color(0.06, 0.08, 0.13)
        sb.corner_radius_top_left         = 10
        sb.corner_radius_top_right        = 10
        sb.corner_radius_bottom_left      = 10
        sb.corner_radius_bottom_right     = 10
        sb.border_width_left              = 3
        sb.border_color                   = stroke
        card.add_theme_stylebox_override("normal", sb)
        var sbh := sb.duplicate() as StyleBoxFlat
        sbh.bg_color = Color(stroke.r * 0.18, stroke.g * 0.18, stroke.b * 0.18)
        sbh.border_width_left = 3; sbh.border_width_right = 1
        sbh.border_width_top  = 1; sbh.border_width_bottom = 1
        card.add_theme_stylebox_override("hover",   sbh)
        card.add_theme_stylebox_override("pressed", sbh)

        # Text: tema + namn + stats + lore
        var dps: float = TowerDefs.DAMAGE[t] * TowerDefs.FIRERATE[t]
        var slow_str := "\n🧊 slow %.0f%%" % (TowerDefs.SLOW[t] * 100) if TowerDefs.SLOW[t] > 0 else ""
        var dot_str  := "\n☠ %.0f dps" % TowerDefs.DOT[t] if TowerDefs.DOT[t] > 0 else ""
        card.text = "%s\n%s\n\n⚔ %.0f  📡 %.1ft\n◈ %.0f dps%s%s\n\n💰 %dg\n\n%s" % [
            TowerDefs.THEME[t].to_upper(),
            TowerDefs.NAMES[t],
            TowerDefs.DAMAGE[t], TowerDefs.RANGE[t],
            dps, slow_str, dot_str,
            TowerDefs.COST[t],
            TowerDefs.LORE[t],
        ]
        card.add_theme_font_size_override("font_size", 11)
        card.add_theme_color_override("font_color", Color(stroke.r, stroke.g, stroke.b, 0.95))
        card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if card.has_method("set_autowrap_mode") else 0
        card.visible = true

        card.pressed.connect(func() -> void: _on_draft_pick(t))

    _draft_overlay.visible = true


func _on_draft_pick(tower_idx: int) -> void:
    GameState.unlocked_towers.append(tower_idx)
    GameState.draft_pending = false
    _draft_overlay.visible  = false
    _rebuild_tower_buttons_from_unlocked()
```

- [ ] **Steg 5.4: Commit**
```bash
git add maul/ui/HUD.gd
git commit -m "feat: draft overlay UI — 3 cards with stats, lore, stroke-color styling"
```

---

## Task 6: Uppdatera tornknapparna att använda `unlocked_towers`

**Fil:** `maul/ui/HUD.gd`

`_rebuild_tower_buttons` byggde tornlistan från gud-index. Nu ska den bygga från `GameState.unlocked_towers`.

- [ ] **Steg 6.1: Döp om och uppdatera `_rebuild_tower_buttons`**

```gdscript
func _rebuild_tower_buttons_from_unlocked() -> void:
    for child in _tower_grid.get_children():
        _tower_grid.remove_child(child)
        child.queue_free()
    _tower_btns.clear()

    for i in GameState.unlocked_towers:
        var stroke: Color = TowerDefs.STROKE[i]
        var sb_normal := StyleBoxFlat.new()
        sb_normal.bg_color                       = Color(0.07, 0.09, 0.13)
        sb_normal.corner_radius_top_left         = 6
        sb_normal.corner_radius_top_right        = 6
        sb_normal.corner_radius_bottom_left      = 6
        sb_normal.corner_radius_bottom_right     = 6
        sb_normal.border_width_left              = 3
        sb_normal.border_color                   = stroke
        var sb_pressed := sb_normal.duplicate() as StyleBoxFlat
        sb_pressed.bg_color           = Color(stroke.r * 0.18, stroke.g * 0.18, stroke.b * 0.18)
        sb_pressed.border_width_left  = 3
        sb_pressed.border_width_right = 1
        sb_pressed.border_width_top   = 1
        sb_pressed.border_width_bottom = 1
        sb_pressed.border_color       = stroke
        var sb_hover := sb_normal.duplicate() as StyleBoxFlat
        sb_hover.bg_color = Color(0.10, 0.13, 0.19)
        var btn := Button.new()
        btn.text = "%s\n%s\n💰 %dg" % [
            TowerDefs.NAMES[i],
            _format_tower_stats_short(i),
            TowerDefs.COST[i],
        ]
        btn.toggle_mode               = true
        btn.size_flags_horizontal     = Control.SIZE_EXPAND_FILL
        btn.custom_minimum_size       = Vector2(0, 68)
        btn.alignment                 = HORIZONTAL_ALIGNMENT_LEFT
        btn.add_theme_font_size_override("font_size", 11)
        btn.add_theme_color_override("font_color",         Color(stroke.r, stroke.g, stroke.b, 0.95))
        btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
        btn.add_theme_color_override("font_hover_color",   Color(minf(stroke.r * 1.2, 1.0), minf(stroke.g * 1.2, 1.0), minf(stroke.b * 1.2, 1.0), 1.0))
        btn.add_theme_stylebox_override("normal",  sb_normal)
        btn.add_theme_stylebox_override("pressed", sb_pressed)
        btn.add_theme_stylebox_override("hover",   sb_hover)
        btn.button_down.connect(_on_tower_btn.bind(i))
        _tower_grid.add_child(btn)
        _tower_btns.append(btn)
```

- [ ] **Steg 6.2: Uppdatera alla anrop till gamla `_rebuild_tower_buttons`**

Sök och ersätt i HUD.gd: `_rebuild_tower_buttons(_pending_god)` → `_rebuild_tower_buttons_from_unlocked()`

- [ ] **Steg 6.3: Ta bort gudval från startskärmen**

I `_build_ui`, hitta `# ── Gudval ───` blocket och ta bort hela sektionen (GridContainer med 4 gudknappar). Ta även bort `_god_btns`, `_pending_god` och relaterade signal-handlers.

I `_do_start()`, ta bort `GameState.selected_god = _pending_god` och `_rebuild_tower_buttons(_pending_god)`. Behåll kartval och svårighetsgrad.

- [ ] **Steg 6.4: Commit**
```bash
git add maul/ui/HUD.gd
git commit -m "feat: tower buttons now built from unlocked_towers, god selection removed from start screen"
```

---

## Task 7: Uppdatera `_draw_tower` med 21 former

**Fil:** `maul/main.gd`

Nuvarande `_draw_tower` har former för torn 0–20 (gamla gudar). Ersätt match-armen med 21 nya former som matchar de nya tornens karaktär.

- [ ] **Steg 7.1: Ersätt match-blocket i `_draw_tower`**

```gdscript
match type:
    0:  # Destroyer — cirkel (flying disc)
        draw_circle(Vector2(cx, cy), r, fill)
        draw_arc(Vector2(cx, cy), r, 0.0, TAU, 48, stroke, 1.5)
        draw_line(Vector2(cx - r, cy), Vector2(cx + r, cy), stroke, 1.0)

    1:  # Buzzz — cirkel + inre ring
        draw_circle(Vector2(cx, cy), r, fill)
        draw_arc(Vector2(cx, cy), r, 0.0, TAU, 48, stroke, 1.5)
        draw_arc(Vector2(cx, cy), r * 0.52, 0.0, TAU, 32, stroke, 1.0)

    2:  # Aviar — liten kompakt kvadrat (putter)
        var ar := r * 0.75
        _tdraw(PackedVector2Array([
            Vector2(cx - ar, cy - ar), Vector2(cx + ar, cy - ar),
            Vector2(cx + ar, cy + ar), Vector2(cx - ar, cy + ar),
        ]), fill, stroke, 2.0)
        draw_circle(Vector2(cx, cy), ar * 0.28, stroke)

    3:  # Hatchet — yxform
        _tdraw(PackedVector2Array([
            Vector2(cx,         cy - r),
            Vector2(cx + r*0.7, cy - r*0.2),
            Vector2(cx + r*0.5, cy + r*0.6),
            Vector2(cx - r*0.5, cy + r*0.6),
            Vector2(cx - r*0.7, cy - r*0.2),
        ]), fill, stroke)

    4:  # Pure — smal aerodynamisk diamant
        _tdraw(PackedVector2Array([
            Vector2(cx, cy - r),
            Vector2(cx + r*0.35, cy),
            Vector2(cx, cy + r),
            Vector2(cx - r*0.35, cy),
        ]), fill, stroke)

    5:  # Gjutjärnspannan — cirkel + handtag
        draw_circle(Vector2(cx - r*0.1, cy), r * 0.78, fill)
        draw_arc(Vector2(cx - r*0.1, cy), r * 0.78, 0.0, TAU, 48, stroke, 1.5)
        _tdraw(PackedVector2Array([
            Vector2(cx + r*0.65, cy - r*0.15),
            Vector2(cx + r*1.10, cy - r*0.15),
            Vector2(cx + r*1.10, cy + r*0.15),
            Vector2(cx + r*0.65, cy + r*0.15),
        ]), fill, stroke, 1.5)

    6:  # Sous Vide — avlång rektangel (vakuumpåse)
        _tdraw(PackedVector2Array([
            Vector2(cx - r*0.55, cy - r*0.90),
            Vector2(cx + r*0.55, cy - r*0.90),
            Vector2(cx + r*0.55, cy + r*0.90),
            Vector2(cx - r*0.55, cy + r*0.90),
        ]), fill, stroke)
        draw_line(Vector2(cx - r*0.35, cy - r*0.55),
                  Vector2(cx + r*0.35, cy - r*0.55), stroke, 1.0)

    7:  # Woken — wok-form (halvcirkel)
        var wp := PackedVector2Array()
        for i in 14:
            var a := PI + PI * i / 13.0
            wp.append(Vector2(cx + cos(a) * r, cy + sin(a) * r * 0.7))
        wp.append(Vector2(cx + r, cy))
        wp.append(Vector2(cx - r, cy))
        _tdraw(wp, fill, stroke)

    8:  # Morteln — U-form (mortel)
        var mp := PackedVector2Array()
        for i in 10:
            var a := PI + PI * i / 9.0
            mp.append(Vector2(cx + cos(a) * r * 0.85, cy + sin(a) * r * 0.75))
        mp.append(Vector2(cx + r * 0.85, cy - r * 0.1))
        mp.append(Vector2(cx - r * 0.85, cy - r * 0.1))
        _tdraw(mp, fill, stroke)
        draw_line(Vector2(cx - r, cy - r * 0.1), Vector2(cx + r, cy - r * 0.1), stroke, 1.5)

    9:  # Göteborgs Rapé — rund snusdosa (cirkel)
        draw_circle(Vector2(cx, cy), r, fill)
        draw_arc(Vector2(cx, cy), r, 0.0, TAU, 48, stroke, 1.5)
        draw_arc(Vector2(cx, cy), r * 0.65, 0.0, TAU, 32, stroke, 0.8)
        draw_circle(Vector2(cx, cy), r * 0.12, stroke)

    10: # General White — oktagon (annan snussort)
        _tdraw(_tpoly(cx, cy, r, 8, PI / 8.0), fill, stroke)
        draw_circle(Vector2(cx, cy), r * 0.22, stroke)

    11: # Oden's Extreme — pentagonstjärna (intensiv)
        _tdraw(_tstar(cx, cy, r, r * 0.42, 5, -PI / 2.0), fill, stroke, 2.0)

    12: # Siberia — tjock diamant (tyngst)
        _tdraw(_tpoly(cx, cy, r, 4, 0.0), fill, stroke, 2.5)
        _tdraw(_tpoly(cx, cy, r * 0.50, 4, 0.0), stroke, stroke, 1.5)

    13: # Ristretto — espressokopp (liten kvadrat + fat)
        _tdraw(PackedVector2Array([
            Vector2(cx - r*0.50, cy - r*0.55),
            Vector2(cx + r*0.50, cy - r*0.55),
            Vector2(cx + r*0.50, cy + r*0.30),
            Vector2(cx - r*0.50, cy + r*0.30),
        ]), fill, stroke, 2.0)
        draw_line(Vector2(cx - r*0.70, cy + r*0.30),
                  Vector2(cx + r*0.70, cy + r*0.30), stroke, 1.5)

    14: # Cold Brew — långt glas (smal rektangel)
        _tdraw(PackedVector2Array([
            Vector2(cx - r*0.40, cy - r*0.95),
            Vector2(cx + r*0.40, cy - r*0.95),
            Vector2(cx + r*0.40, cy + r*0.95),
            Vector2(cx - r*0.40, cy + r*0.95),
        ]), fill, stroke)
        draw_line(Vector2(cx - r*0.40, cy + r*0.20),
                  Vector2(cx + r*0.40, cy + r*0.20), stroke, 0.8)

    15: # Chemex — timglasform
        _tdraw(PackedVector2Array([
            Vector2(cx - r*0.70, cy - r*0.95),
            Vector2(cx + r*0.70, cy - r*0.95),
            Vector2(cx + r*0.20, cy - r*0.05),
            Vector2(cx + r*0.55, cy + r*0.95),
            Vector2(cx - r*0.55, cy + r*0.95),
            Vector2(cx - r*0.20, cy - r*0.05),
        ]), fill, stroke)

    16: # Ernie Ball — strängspole (hexagon)
        _tdraw(_tpoly(cx, cy, r, 6, 0.0), fill, stroke)
        for i in 3:
            var a := TAU * i / 3.0
            draw_line(Vector2(cx, cy),
                Vector2(cx + cos(a) * r * 0.80, cy + sin(a) * r * 0.80),
                stroke, 1.0)

    17: # Tube Screamer — pedal (avrundad rektangel)
        _tdraw(PackedVector2Array([
            Vector2(cx - r*0.65, cy - r*0.80),
            Vector2(cx + r*0.65, cy - r*0.80),
            Vector2(cx + r*0.80, cy - r*0.30),
            Vector2(cx + r*0.80, cy + r*0.80),
            Vector2(cx - r*0.80, cy + r*0.80),
            Vector2(cx - r*0.80, cy - r*0.30),
        ]), fill, stroke)
        draw_circle(Vector2(cx, cy - r*0.20), r * 0.25, stroke)

    18: # Roundhouse — kickcirkel (halvmåne + riktningspil)
        var rp := PackedVector2Array()
        for i in 20:
            var a := -PI * 0.1 + TAU * 0.65 * i / 19.0
            rp.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
        rp.append(Vector2(cx, cy))
        _tdraw(rp, fill, stroke)

    19: # Elbow — skarp vinkel (triangel som pekar in)
        _tdraw(PackedVector2Array([
            Vector2(cx,          cy - r),
            Vector2(cx + r,      cy + r * 0.70),
            Vector2(cx,          cy + r * 0.20),
            Vector2(cx - r,      cy + r * 0.70),
        ]), fill, stroke, 2.0)

    20: # Hot Stone — oregelbunden sten (pentagon)
        _tdraw(PackedVector2Array([
            Vector2(cx - r*0.30, cy - r*0.90),
            Vector2(cx + r*0.55, cy - r*0.65),
            Vector2(cx + r*0.90, cy + r*0.20),
            Vector2(cx + r*0.20, cy + r*0.90),
            Vector2(cx - r*0.80, cy + r*0.50),
            Vector2(cx - r*0.85, cy - r*0.30),
        ]), fill, stroke)

    _:  # fallback
        draw_rect(Rect2(px + 1, py + 1, pw - 2, ph - 2), fill)
        draw_rect(Rect2(px + 1, py + 1, pw - 2, ph - 2), stroke, false, 1.5)
```

- [ ] **Steg 7.2: Commit**
```bash
git add maul/main.gd
git commit -m "feat: 21 new tower shapes matching personal themes"
```

---

## Task 8: Städa upp GameState och lösa kompileringsfel

**Fil:** `maul/autoload/GameState.gd`, `maul/main.gd`

- [ ] **Steg 8.1: Ta bort `selected_god` från GameState**

`selected_god` används inte längre. Ta bort variabeldeklarationen och alla `selected_god = 0` i `reset()`.

Sök efter `selected_god` i hela projektet och ta bort alla references:
```bash
grep -rn "selected_god" /home/albin/Documents/Towerdefense/maul/
```

- [ ] **Steg 8.2: Anropa `_give_starting_towers` vid spelstart**

Hitta i `main.gd` var `game_started` sätts till `true` (i `WaveManager.start()` via `GameState`) eller var `_do_start`-logiken landar. Säkerställ att `_give_starting_towers()` anropas exakt en gång när ett nytt spel börjar — inte vid restart.

- [ ] **Steg 8.3: Kör spelet och fixa kompileringsfel**

Starta Godot, öppna Output-panelen och åtgärda eventuella fel. Vanliga problem:
- `_rebuild_tower_buttons` som fortfarande anropas med argument → ersätt med `_rebuild_tower_buttons_from_unlocked()`
- Gamla GOD_TOWERS-references i HUD → ta bort
- `_on_tower_btn` som söker i `TowerDefs.GOD_TOWERS` → ersätt med direkt index

- [ ] **Steg 8.4: Final commit**
```bash
git add -u
git commit -m "chore: clean up god references, fix compilation errors after draft system migration"
```

---

## Checklista efter implementation

- [ ] Spelet startar utan kompileringsfel
- [ ] Startar med 2 slumpmässiga torn i tornlistan
- [ ] Tornen visas med rätt form och STROKE-färg
- [ ] Slow-torn gör fiender synligt långsammare (blå ring)
- [ ] DoT-torn gör fiender skada över tid (orange ring)
- [ ] Draft-overlay visas efter våg 5, 10, 15...
- [ ] Val i draft lägger till tornet i drawer omedelbart
- [ ] Gudvalet är borta från startskärmen
- [ ] Lore-texten visas på draft-korten
