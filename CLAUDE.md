# Maze TD — Claude-instruktioner

## Arbetsflöde & Källor

1. **Läs alltid `gdd.md` först:** Den är projektets "Source of Truth".
2. **Håll GDD uppdaterad:** Vid varje implementerad feature eller ändrad balans (stats/kostnad), uppdatera `gdd.md`.
3. **Statuskoll:** Kontrollera Utvecklingsplanen (Sektion 14) innan påbörjat arbete.

När vi implementerar något nytt eller ändrar design:
- Markera steg i **Sektion 14 (Utvecklingsplan)** som ✅ klart när de är klara
- Uppdatera stats, storlekar och beteenden i relevanta sektioner
- Lägg till nya öppna frågor i **Sektion 15** om de dyker upp
- Uppdatera versionsnummer och datum i rubriken

## Teknisk Arkitektur

- **Motor:** Godot 4 (GDScript)
- **Huvudfil:** [maul/main.gd](maul/main.gd) — all spellogik i en fil
- **Scen:** [maul/main.tscn](maul/main.tscn)
- **Data:** `wintermaul_data.json` används för att definiera vågor (WC3-konverterad data)
- **Grid:** 16x22 celler (30px/st). Sub-grid för pathfinding (32x44) för att hantera **Offset-systemet**
- **Pathfinding:** BFS-algoritm som körs på sub-gridet. Validitetskoll sker *innan* tornplacering

## Kodstil & Principer

- **Språk:** Variabler och logik på engelska. Kommunikation med användaren på svenska.
- **Struktur:** Följ Godots standard: `_ready()`, `_process(delta)`, sedan interna metoder (prefixade med `_`), sist publika helpers.
- **Typad GDScript:** Använd alltid `-> void`, `: int`, `: String` etc.
- **Signals:** Använd signaler för UI-uppdateringar för att hålla logiken frikopplad från gränssnittet.
- All spellogik i `main.gd` — undvik att splittra i separata filer om det inte är nödvändigt
- Konstanter med `const`, variabler med `var`, typannoteringar där det hjälper läsbarheten
- Sektionskommentarer (`# ====...====`) för att dela upp koden

## Kärnprinciper (The Maze TD Way)

- **Offset är heligt:** Varje ny funktion (som nya tornstorlekar) måste fungera med sub-grid-systemet och inte bryta pathfindingen.
- **Visuell feedback:** Tornets `stroke`-färg dikterar projektilens färg. Glow (HDR/Bloom) är centralt för estetiken.
- **Ingen "fusk-svårighet":** Svårighetsgrad påverkar endast liv-räknaren, aldrig fiendens stats.

## Kommandon & Genvägar

- **Debug:** Använd `print_debug()` för kritiska fel i pathfindingen.
- **Refactoring:** Vid ändring av torn-stats, kontrollera tabellerna i `gdd.md` sektion 3 först.
