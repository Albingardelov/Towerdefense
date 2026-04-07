# Maze TD — Claude-instruktioner

## Läs alltid GDD i början av varje session

Läs [gdd.md](gdd.md) **innan du gör något annat**. Den är källan till sanning om spelets design, implementationsstatus och öppna frågor.

## Håll GDD:n uppdaterad

När vi implementerar något nytt eller ändrar design — uppdatera GDD:n direkt. Specifikt:

- Markera steg i **Sektion 14 (Utvecklingsplan)** som ✅ klart när de är klara
- Uppdatera stats, storlekar och beteenden i relevanta sektioner
- Lägg till nya öppna frågor i **Sektion 15** om de dyker upp
- Uppdatera versionsnummer och datum i rubriken

## Projektet

- **Motor:** Godot 4, GDScript
- **Huvudfil:** [maul/main.gd](maul/main.gd) — all spellogik i en fil
- **Scen:** [maul/main.tscn](maul/main.tscn)
- **Språk:** Kommunicera på svenska med användaren

## Kodstil

- All spellogik i `main.gd` — undvik att splittra i separata filer om det inte är nödvändigt
- Konstanter med `const`, variabler med `var`, typannoteringar där det hjälper läsbarheten
- Sektionskommentarer (`# ====...====`) för att dela upp koden
