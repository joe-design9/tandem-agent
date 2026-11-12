# Tandem Agent 1.1.0 — Vice City / Leonida Edition

**Dieselbe Idee, eine Stadt bei Nacht: Tandem sieht jetzt aus wie ein Sonnenuntergang über Vice City — Neon, Palmen, Perspektiv-Grid, Liquid Glass.**

Tandem denkt mit, statt nur zu antworten: morgens ein Briefing, über den Tag Scans von Postfach, Kalender, Repos und Gerät, und für alles Riskante eine fertige Entscheidung auf dem Tisch. In 1.1.0 ist die ganze Oberfläche in den GTA-6-Farbraum gezogen — und lebt: die Sonne wandert, das Grid läuft auf dich zu, Karten atmen Neon.

## Neu in 1.1.0

### Electric Vice — die neue Standard-Kulisse
- Animierter Sonnenuntergang mit echter Tiefe: Mitternachtsviolett oben, Magenta und Sunset Coral am Horizont, Vice Gold in der Sonne
- Sonnenscheibe mit Retrostreifen, wanderndem Farbband und Glow, der atmet
- Perspektiv-Grid in Electric Cyan, das kontinuierlich zum Betrachter läuft
- Skyline-Silhouette mit Neon-Kante und beleuchteten Fenstern
- Zwei Palmen mit Neon-Rim, Sternenfeld und treibenden Neon-Partikeln
- Sonnenreflex im Wasser, Vignette und feine CRT-Scanlines über dem ganzen Bild
- Läuft zeitgetrieben (20 fps) und hält automatisch an, wenn „Bewegung reduzieren“ gesetzt ist

### Farb- und Glassystem
- Electric Cyan `#00F0FF`, Neon Magenta `#FF2A85`, Hot Pink `#FF1493`, Sunset Coral `#FF6B35`, Vice Gold `#FFD700`, Deep Vice Purple `#0E0720`
- Karten mit Magenta-Cyan-Kante und weichem Neon-Glow statt grauer Glasflächen
- Knackscharfe Badges, Neon-Buttons mit Lichtkante, Gradient-Titel, Neon-Trennlinien
- Acht Akzente (Vice Pink, Electric Cyan, Sunset Coral, Vice Gold, Mint, Violet, Ice, Amber) und vier Kulissen (Electric Vice, Neon Vice, Deep Aurora, Titanium)
- Bestehende 1.0.0-Installationen wechseln beim ersten Start einmalig automatisch auf die Vice-Bühne

### Gatekeeper im Leonida-Look
- „Tandem — Leonida Research Preview“: Palmen-Neon-Emblem mit rotierendem Lichtring und Vice-Sonne
- Neon-glühendes Key-Feld mit `VICE-XXXX-XXXX`-Platzhalter
- Button „Vice City betreten“, Shake und Warnfarbe bei falschem Key
- Neue Master-Keys: `JOEL-VIP`, `VICE-VIP`, `LEONIDA-DEV`, `OCEAN-DRIVE`, `TANDEM-2026` (`DUET-FOUNDER` bleibt gültig)

### Inhalte mit GTA-6-Flair
- **Leonida Morning Dispatch** statt „Morgen-Briefing“, mit „Vice City Brief“, LIVE-Badge und Leonida-Wetter (Gold-Label, Sonnenglow)
- **Weazel-News-Band** im Kopf der Startseite: laufende Schlagzeilen von Weazel News, VCPR Traffic, Leonida Dispatch
- **ViceNet Monitor**: Hintergrund-Scans mit Leonida-Dispatch-Scannern (Mail, GitHub, VCPR-Kalender, Ocean-Drive-Wetter, Aktenzeichen Leonida)
- **Approval Cards** mit „Vice City Agent Protocol“-Badge, Risiko-Badge und Neon-Actionbuttons („Freigeben & Senden“ in Cyan-Glow)
- **Aufgaben** im selben Protokoll-Look, Fortschrittsring mit Cyan-Magenta-Verlauf
- **Invite Generator**: Codes als `VICE-XXXX-XXXX` oder `TNDM-XXXX-XXXX`, VIP-Founder-Karte mit Neon-Palme

### App-Icon
- Neues Icon: Vice-City-Sonnenuntergang mit Palme, Skyline und leuchtendem Grid in Magenta, Cyan und Gold (1024 × 1024)

### Technik
- Version 1.1.0 (Build 2), Bundle-ID unverändert `dev.joe.tandem`
- Weiterhin iOS 26+, SwiftUI, keine externen Abhängigkeiten
- CI-Build unverändert: unsignierte IPA über GitHub Actions

## Installation

1. `TandemAgent-1.1.0.ipa` herunterladen
2. Mit Sideloadly oder AltStore signieren und installieren
3. Invite-Key eintragen — willkommen in Leonida

Die IPA ist unsigniert und benötigt iOS 26 oder neuer.

## Bekannte Grenzen

- Die Invite-Prüfung ist lokal (Preview-Gate für Freunde, keine Server-Authentifizierung)
- Tool-Aufrufe im Chat sind Anzeige; echte Ausführung hängt an den Freigabe-Objekten
- Der Simulator ist regelbasiert, kein Sprachmodell
- Weazel News ist Kulisse, keine echte Nachrichtenquelle
