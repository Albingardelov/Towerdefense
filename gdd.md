```
# Maze TD — Game Design Document
**Version 0.2 | Draft**

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
6. Var 10:e våg spawnar flygande fiender som ignorerar mazen helt
7. Räknaren ökar för varje fiende som når fram — nå gränsen och spelet är förlorat

---

## 3. Hjältar — Asagudar

Spelaren väljer en gud innan omgången börjar. Vald gud bestämmer vilka torn spelaren har tillgång till. Alla fyra gudar är upplåsta från start.

Varje guds tornuppsättning skapar en unik maze-estetik.

### ⚡ Tor — Åska & direkt kraft
> Maze-estetik: Täta, symmetriska spiraler
> Färgpalett: Blå och guld

| Tier | Namn | Storlek | Färg | Hex |
|------|------|---------|------|-----|
| Torn 1 | Grundsten | 1×1 | Grå/silver | #8A9BA8 |
| Torn 2 | Åskledare | 1×1 | Blå | #4A90D9 |
| Torn 3 | Stormvakt | 1×1 | Mörkblå | #1A3A6A |
| Ultimate | Mjölner | 2×2 | Guld | #F0C030 |

> Mjölner är guld för att sticka ut tydligt i mazen — ju starkare torn, ju mer distinkt färg.

**Status: Byggs först — fungerar som template för övriga gudar**

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

Spelplanen består av ett rutsystem där torn placeras. Varje torn tar upp minst en ruta. Exakt gridstorlek bestäms under prototyp-fasen.

### 4.2 Offset-placering (kärnan i spelet)

> **Offset-placering är inte en extra feature. Det är den konstnärliga friheten som ger spelet dess identitet.**

Torn kan placeras på gränsen mellan två rutor, så att halva tornet sitter i en ruta och halva i en annan. Detta möjliggör:

- Extremt täta korridorer, nästan pixel-tight
- Organiska spiraler och kurvor som ser handritade ut
- En skill-faktor: att bemästra offset separerar bra builders från dåliga

### 4.3 Pathfinding-regler

Fiender hittar alltid den **kortaste** möjliga vägen genom mazen. Spelarens uppgift är att bygga mazen så slingrig att kortaste vägen ändå blir lång.

Om ett torn blockerar den sista möjliga vägen får det inte placeras där.

---

## 5. Kartor

Start- och slutpunkt är konfigurerbara i koden — olika kartor kräver ingen ny spellogik, bara nya koordinater.

| Karta | Beskrivning | Status |
|-------|-------------|--------|
| Karta 1 — Klassisk | Uppifrån → ner, en ingång, en utgång | Byggs först |
| Karta 2 — Horisontell | Vänster → höger | Framtida |
| Karta 3 — Konvergens | Fyra kanter → mitten (mandala-estetik) | Framtida |
| Karta 4 — Explosion | Mitten → ut mot kanterna | Framtida |

---

## 6. Fiender och Vågor

### 6.1 Vågmönster

| Våg | Typ | Notering |
|-----|-----|----------|
| 1–4 | Markfiender | Följer kortaste vägen genom mazen |
| 5 | Flygande fiender | Ignorerar mazen, flyger rakt |
| 6–9 | Markfiender | |
| 10 | Flygande fiender + Boss | Bossar flyger med flygfienderna |
| 11–14 | Markfiender | |
| 15 | Flygande fiender | |
| 16–19 | Markfiender | |
| 20 | Flygande fiender + Boss | |
| ... | ... | Var 5:e våg = flyg, var 10:e = flyg + boss |

### 6.2 Flygande fiender

Flygande fiender flyger kortaste vägen och ignorerar hela mazen. Det är "ett andra spel ovanpå mazen" — spelaren måste tänka på lufttäckning även när de bygger sin vackra maze.

Tematiskt passar Valkyrior, Sleipner eller Huginn & Muninn som flygande fiender.

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

- Dödade fiender ger guld
- Guld används för att köpa torn (Tier 1–3) och ultimate
- Dyrare torn = kraftfullare effekt och/eller större fotavtryck

Exakta siffror och balansering bestäms under speltest-fasen när Tors tornkit är byggt.

---

## 9. Fiendelogik & Rörelse

### 9.1 Kollision och trängsel

Fiender har faktisk kollision med varandra — de är cirklar som inte kan överlappa. I trånga korridorer betyder det:

- Fiender trycker på varandra och bildar naturliga köer
- Fiender bakifrån bromsas av de framför
- Täta mazes skapar organiskt trafikkaos utan extra kod
- En perfekt tight maze ger spelaren en gratis fördel via trängsel

> En snygg maze straffar fiender dubbelt — längre väg OCH trängsel.

### 9.2 Hastighetsförlust i svängar

Fiender tappar hastighet i proportion till hur skarp sväng de gör. Det belönar mazes med många täta svängar.

| Sväng | Hastighetsmultiplikator |
|-------|------------------------|
| Rakt fram (0°) | × 1.0 |
| Normal sväng (90°) | × 0.7 |
| U-sväng (180°) | × 0.4 |

> En rak korridor låter fiender springa igenom i full hastighet. En snygg spiral saktar ner dem organiskt — utan slow-torn.

---

## 10. Projektiler

Varje torn skjuter en projektil mot närmaste fiende inom räckvidd.

**Logik:**
1. Tornet söker igenom alla aktiva fiender varje frame
2. Närmaste fiende inom range låses som mål
3. En projektil skapas och rör sig mot målet varje frame
4. Vid träff: fienden tar skada, projektilen försvinner

Projektiler följer fienden om den rör sig. I prototypen är projektilen en enda pixel — färg matchar tornets färg.

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
| 1 | Grid + offset-system | ⬅ Nästa |
| 2 | Pathfinding (kortaste väg + blockerings-validering) | Kommande |
| 3 | Tors fyra torn med färger och projektiler | Kommande |
| 4 | Fiender, vågor, räknare | Kommande |
| 5 | Ekonomi och balansering | Kommande |
| 6 | Loki, Oden, Freja | Kommande |
| 7 | Fler kartor, multiplayer, polish | Framtida |

---

## 15. Öppna Frågor

| Fråga | Notering |
|-------|----------|
| Exakta torn-stats och kostnader | Bestäms under balansering |
| Antal vågor totalt — begränsat eller oändligt? | Öppen |
| Fiende-teman och namn | Valkyrior, jättar, troll? |
| Exakt gridstorlek | Bestäms under prototyp |
| Uppgradera på plats eller riva och bygga nytt? | Öppen |
```

Vi ses i helgen! 🛠️