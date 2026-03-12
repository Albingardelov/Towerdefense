```
# Maze TD — Game Design Document
**Version 0.6 | Uppdaterad mars 2026**

---

## 1. Vision & Spelkoncept

Maze TD är ett Tower Defense-spel vars kärna handlar om frihet och estetisk stolthet i maze-byggande. Inspirerat av klassiska Warcraft 3-lägen som Wintermaul och Element TD.

> **Kärnfilosofi:** Spelaren ska känna sig stolt och glad över mazen de byggt.

Det är inte egentligen ett Tower Defense-spel i första hand. Det är ett **maze-byggspel** där TD är ramen. Torn är penseln. Maze är konsten.

---

## 2. Core Loop

1. Spelaren väljer svårighetsgrad och en gud (hjälte)
2. Spelaren placerar torn på gridet för att skapa en maze
3. Fiender spawnar uppifrån och söker sig neråt via kortaste möjliga väg
4. Torn attackerar fiender längs vägen
5. Dödade fiender ger guld — guld används för att köpa fler torn
6. Var 5:e våg spawnar flygande fiender som ignorerar mazen helt; var 10:e tillkommer en boss
7. Räknaren ökar för varje fiende som når fram — nå gränsen och spelet är förlorat

---

## 3. Hjältar — Asagudar

Spelaren väljer en gud innan omgången börjar. Vald gud bestämmer vilka torn spelaren har tillgång till. Alla fyra gudar är upplåsta från start.

Varje guds tornuppsättning skapar en unik maze-estetik.

### ⚡ Tor — Åska & direkt kraft
> Maze-estetik: Täta, symmetriska spiraler
> Färgpalett: Blå och guld

**Status: ✅ Implementerad**

| Tier | Namn | Storlek | Kostnad | Skada | Räckvidd | Eldkraft | AOE | Luftmultiplikator |
|------|------|---------|---------|-------|----------|----------|-----|-------------------|
| Torn 1 | Cornerstone | 1×1 | 100g | 30 | 2.5 | 1.05/s | Splash 0.4 | ×2.0 |
| Torn 2 | Lightning Rod | 1×1 | 250g | 73 | 4.5 | 0.85/s | Nej | ×2.0 |
| Torn 3 | Storm Guard | 1×1 | 600g | 190 | 3.5 | 0.80/s | Nej | ×2.0 |
| Ultimate | Mjolnir | 2×2 | 2000g | 10 | 6.0 | 20.0/s | Nej | ×1.0 |
| Bonus | Tempest | 1×1 | 450g | 65 | 3.5 | 0.55/s | Splash 1.5 | ×1.0 |

> Mjolnir fungerar som ett snabbeldsgevär med låg skada per skott men extremt hög eldtakt.
> Tempest är ett AOE-torn med stor splashradie — lagom mot täta grupper.
> Mjölner är guld för att sticka ut tydligt i mazen — ju starkare torn, ju mer distinkt färg.

**Tornfärger (implementerade):**
| Namn | Fill | Stroke |
|------|------|--------|
| Cornerstone | Grå | Ljussilver |
| Lightning Rod | Mörkblå | Levande blå |
| Storm Guard | Väldigt mörkblå | Ljusblå |
| Mjolnir | Mörkguld | Ljusguld |
| Tempest | Mörklila | Levande lila |

---

### 🐍 Loki — Kaos & gift
> Maze-estetik: Långa, organiska korridorer
> Färgpalett: Grön och lila

| Tier | Namn | Storlek | Färg | Hex |
|------|------|---------|------|-----|
| Torn 1 | Illusionstorn | 1×1 | Mörkgrön | #2A5A2A |
| Torn 2 | Gifttorn | 1×1 | Giftig grön | #6ABF40 |
| Torn 3 | Kaostorn | 1×1 | Lila | #7A3A9A |
| Ultimate | Världsormen | 1×3 | Lysande lila | #C040F0 |

---

### 🐦 Oden — Visdom & räckvidd
> Maze-estetik: Spiralformade, vidsträckta mazes
> Färgpalett: Lila och silver

| Tier | Namn | Storlek | Färg | Hex |
|------|------|---------|------|-----|
| Torn 1 | Vakttorn | 1×1 | Mörkgrå | #4A4A5A |
| Torn 2 | Spejartorn | 1×1 | Silver | #9A9AB0 |
| Torn 3 | Allseende | 1×1 | Djuplila | #4A2A7A |
| Ultimate | Yggdrasil | 2×2 | Vit/silver | #E0E8FF |

---

### 🌸 Freja — Natur & slow
> Maze-estetik: Mjuka kurvor, organiska flöden
> Färgpalett: Rosa och grön

| Tier | Namn | Storlek | Färg | Hex |
|------|------|---------|------|-----|
| Torn 1 | Törnesnår | 1×1 | Mörkgrön | #2A5A30 |
| Torn 2 | Frostvinda | 1×1 | Isblå | #80C8E0 |
| Torn 3 | Naturens vrede | 1×1 | Skogsgrönt | #3A8A40 |
| Ultimate | Bifrost | 1×3 | Rosa/magenta | #F040A0 |

---

### 3.1 Ultimate-tornets designprincip

Ultimate-tornet ska inte bara göra mer skada — det ska **förändra hur spelaren bygger**. Det stora fotavtrycket (2×2 eller 1×3) tvingar spelaren att planera in det från början. Felplacering kan förstöra hela spiralen.

Med offset-systemet kan ett 2×2 eller 1×3 ultimate även placeras offset, vilket skapar ytterligare komplexitet och möjlighet till vackra placeringar.

### 3.2 Mark vs Luft

- Vissa torn skjuter bara marktrupper
- Vissa torn skjuter bara flygande fiender
- Vissa torn skjuter båda (men med reducerad effektivitet på en av dem)

Exakt fördelning per gud bestäms under torndesign-fasen.

---

## 4. Grid och Offset-systemet

### 4.1 Grundgrid

**Implementerat:**
- **16 × 22 rutor**, 30 px per ruta
- Spelyta: 480 × 660 px | UI-panel: 160 px bred (höger)
- Totalt fönster: 640 × 660 px
- Ingång: kolumn 8, rad 0 (topp) | Utgång: kolumn 8, rad 21 (botten)

### 4.2 Offset-placering (kärnan i spelet)

> **Offset-placering är inte en extra feature. Det är den konstnärliga friheten som ger spelet dess identitet.**

Torn kan placeras på gränsen mellan två rutor, så att halva tornet sitter i en ruta och halva i en annan. Detta möjliggör:

- Extremt täta korridorer, nästan pixel-tight
- Organiska spiraler och kurvor som ser handritade ut
- En skill-faktor: att bemästra offset separerar bra builders från dåliga

### 4.3 Pathfinding-regler

**Implementerat:** BFS på dubbel upplösning (32 × 44 sub-grid). Varje helruta delas i 2×2 sub-celler, vilket gör att offset-torn blockerar exakt de sub-celler de täcker.

Fiender hittar alltid den **kortaste** möjliga vägen genom mazen. Spelarens uppgift är att bygga mazen så slingrig att kortaste vägen ändå blir lång.

Om ett torn blockerar den sista möjliga vägen får det inte placeras där (valideras live innan placering).

---

## 5. Kartor

Start- och slutpunkt är konfigurerbara i koden — olika kartor kräver ingen ny spellogik, bara nya koordinater.

| Karta | Beskrivning | Status |
|-------|-------------|--------|
| Karta 1 — Klassisk | Uppifrån → ner, en ingång (topp kol 8), en utgång (botten kol 8) | ✅ Klart |
| Karta 2 — Mandala | Fyra hörn → mitten. Spelaren tvingas bygga en mandala runt centrum | ✅ Klart |
| Karta 3 — Horisontell | Vänster → höger | Framtida |
| Karta 4 — Explosion | Mitten → ut mot kanterna | Framtida |

### Karta 2 — Mandala (detaljer)

- **4 ingångar:** hörnen (0,0), (15,0), (0,21), (15,21)
- **1 utgång:** mitten av kartan (col 8, rad 11)
- **Regel:** alla fyra stigar måste hållas öppna — torn som blockerar någon stig nekas
- **Estetik:** naturligt tvingar spelaren att bygga spiralformade strukturer runt centrum

---

## 6. Fiender och Vågor

### 6.1 Vågmönster

**Implementerat:** 40 unika vågdefinitioner (WC3-inspirerade). Varje våg har namn, HP, hastighet, antal, bounty, våg-bonus, armor-typ och special-flagga.

Speciella vågor:
- **SWARM** (Einherjar v9, Berserker v16) — extra många fiender
- **MAGIC IMMUNE** (Huldra v17, Death Rune v28, Blood Demon v34, Jormungandr v39)
- **INVISIBLE** (Shadow v21, Soul Reaper v37)
- **BOSS** (Rime Giant v20, Ice King v25, Bone King v30, Fafnir v35)
- **FINAL BOSS** (Ymir v40 — 60 000 HP, 500g bounty, 1 200g våg-bonus)
- **AIR WAVE** (Valravn v6, Fossegrim v11, Nokken v14, Sea Serpent v19, Hraesvelgr v23, Winter Wyrm v27, Vidofnir v32, Fafnir v35, Jormungandr v39)

**Konvertering från WC3:** Hastighet = WC3_speed × (30/270). HP = WC3_hp × 0.5.

**Exempeldata:**
- Wave 1 Draugr: 12 st, 75 HP, 30 px/s, 8g bounty
- Wave 9 Einherjar (SWARM): 20 st, 400 HP, 36 px/s
- Wave 40 Ymir (FINAL BOSS): 1 st, 60 000 HP, 24 px/s, divine armor

### 6.2 Flygande fiender

**Implementerat:** Flygfiender flyger direkt från ingång till utgång, ignorerar hela mazen. Ritas som diamanter (4-hörn polygon). Bossar är orange och större (radius 12 vs 7).

- Flygfiender: blå diamant, hastighet × 1.25
- Boss: orange diamant, hastighet × 1.15, 5× guldvärde, radius 12

Tematiskt passar Valkyrior, Sleipner eller Huginn & Muninn som flygande fiender (framtida grafik).

---

## 7. Svårighetsgrad

Spelaren väljer svårighetsgrad innan omgången börjar. Presenteras som en räknare (t.ex. **73 / 100**) — inte som ett liv-system.

| Svårighet | Fiender som får passera | Förlorar vid |
|-----------|------------------------|--------------|
| 🟢 Easy | 100 | Fiende nr 101 |
| 🟡 Medium | 50 | Fiende nr 51 |
| 🔴 Hard | 0 | Första fienden som når fram |

> **Viktigt:** Svårighetsgraden påverkar enbart räknaren. Fiendernas styrka, hastighet och antal är identiska oavsett valt läge. Det är din maze som avgör — inte att spelet fuskar.

---

## 8. Ekonomi

**Implementerat:**

- Startguld: 500g (även vid omstart)
- Dödade fiender ger bounty per kill (8–500g, WC3-baserat, ökar per våg)
- Guldbonus för avslutad våg: 35–1200g (ökar per våg, WC3-baserat)
- Sälja torn: 75% återbetalning (högerklick) — samma som WC3
- "Rensa alla" säljer alla torn med 75% refund
- Guld används för att köpa torn — kostnad 100–2000g

Balansering pågår under speltest-fasen.

---

## 9. Fiendelogik & Rörelse

### 9.1 Rörelse och kollision

Fiender följer waypoints utan kollision (WC3-stil) — de kan överlappa varandra. Spawn-intervall: 0.5s. Fiender rör sig med konstant hastighet utan svängsaktning.

Aktiva fiender reroutes INTE när torn placeras mid-wave — de behåller sina ursprungliga waypoints. Nyspawnade fiender plockar alltid upp den aktuella stigen.

---

## 10. Projektiler

**Implementerat:**

Varje torn skjuter en projektil mot bästa fiende inom räckvidd.

**Targeting-prioritet:**
1. Markfiende längst framme på pathen (högst waypoint-index)
2. Om inga markfiender: flygfiende närmast utgången

**Logik:**
1. Tornet söker igenom alla aktiva fiender varje frame
2. Bäste fiende inom range låses som mål
3. En projektil skapas och rör sig mot målet (180 px/s)
4. Vid träff: fienden tar skada, projektilen försvinner

Projektiler följer fienden om den rör sig. Ritas som en 4px cirkel — färg matchar tornets stroke-färg.

**AOE-torn** (Cornerstone & Tempest): vid träff skapas en explosion-ring och alla fiender inom splashradie tar full skada.

---

## 11. Multiplayer (Framtida)

Spelet börjar som solo-upplevelse. Multiplayer planeras som ett senare tillägg.

- **Kooperativt:** Spelare bygger mazes tillsammans på samma karta
- **Kompetitivt (Maul-stil):** Parallella mazes, kan läcka fiender till motståndarens bana

---

## 12. Visa upp din Maze

Eftersom stolthetskänslan är spelets kärna måste det finnas sätt att visa upp den:

- Inbyggd screenshot-funktion
- Dela maze via länk (framtida)
- Eventuell maze-galleri där spelare visar sina byggelser

---

## 13. Affärsmodell

- Gratis att ladda ner
- Tor helt gratis — hela spelet, alla svårighetsgrader
- Engångsbetalning (~3–5 dollar) för att låsa upp Loki, Oden och Freja
- Ingen reklam. Aldrig. Inga microtransactions.

---

## 14. Utvecklingsplan

| Steg | Vad | Status |
|------|-----|--------|
| 1 | Grid + offset-system | ✅ Klart |
| 2 | Pathfinding (kortaste väg + blockerings-validering) | ✅ Klart |
| 3 | Tors tornkit med färger och projektiler | ✅ Klart (5 torn) |
| 4 | Fiender, vågor, räknare | ✅ Klart |
| 5 | Ekonomi: sälja torn (75%), auto-waves, 40-vågs WC3-data | ✅ Klart |
| 5b | Ljud: skjut-ljud, startsound | ✅ Klart |
| 5c | Sprite-animationer: Orc walk/death som markfiende | ✅ Klart |
| 5d | Per-torn projektilanimationer med glow (HDR + bloom) | ✅ Klart |
| 5e | WorldEnvironment glow + stengolv-textur | ✅ Klart |
| 6 | Gudval + UI för tornuppsättning per gud | ✅ Klart |
| 7 | Loki, Oden, Freja (torn + projektiler) | ✅ Klart (stats + färger; sprite-assets placeholder) |
| 8a | Karta 2 — Mandala (fyra hörn → mitten) | ✅ Klart |
| 8b | Fler kartor, multiplayer, polish | ⬅ Nästa |

---

## 15. Öppna Frågor

| Fråga | Notering |
|-------|----------|
| Exakta torn-stats och kostnader | Grundvärden implementerade, finjustering pågår |
| Antal vågor totalt — begränsat eller oändligt? | 40 definierade, öppet om loopning behövs |
| Uppgradera på plats eller riva och bygga nytt? | Öppen |
| Tempest — hör den till Tor eller en annan gud? | Lila färg passar möjligen Loki bättre |
| Sprite för flygande fiender | Diamant-placeholder kvar, behöver asset |
| HP-bar stil | WC3-stil alltid synlig, kan behöva finjusteras |

## 16. UI-layout (nuläge)

```
┌─────────────────────────┬──────────┐
│                         │ Wave: —  │
│                         │ Gold: 500│
│   Spelyta               │ Esc: 0/50│
│   480 × 660 px          │──────────│
│   (16×22 rutor á 30px)  │ [Torn 1] │
│                         │ [Torn 2] │
│   IN  (topp, kol 8)     │ [Torn 3] │
│   OUT (botten, kol 8)   │ [Mjolnir]│
│                         │ [Tempest]│
│                         │──────────│
│                         │Wave 1 60s│
│                         │[Send Erl]│
│                         │[E][M][H] │
│                         │──────────│
│                         │ Inspect  │
│                         │ info     │
│                         │ Sell:75g │
│                         │[Rensa]   │
└─────────────────────────┴──────────┘
```

**Kontroller:**
- Vänsterklick: placera torn / inspektera torn
- Högerklick: sälj torn (75% återbetalning)
- Hovring: visar ghost + räckviddsring + vägvalidering live
- Vågor startar automatiskt (60s första, 30s därefter)
- "Send Early" skickar nästa våg omedelbart
```