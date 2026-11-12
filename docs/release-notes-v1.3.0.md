# Tandem Agent 1.3.0 — Handcrafted & Butterweich

**Radikal aufgeräumt: keine Blurs, keine Canvas-Körnung, keine Neon-Badges, keine schwebende Kapsel über dem Eingabefeld. Statt Kulisse gibt es jetzt ein ruhiges, monochromes Arbeitswerkzeug — ein Akzent, klare Abläufe, flache Flächen.**

1.2.0 hat dem Agenten eine Engine gegeben. 1.3.0 nimmt ihm das Theater weg.

## Performance

- **Canvas-Körnung entfernt.** Der Rauschfilter zeichnete bei jedem Neuaufbau 900 Einzelpixel — im Scrollen ein Dauerläufer auf der CPU.
- **Animierte Lichtkegel entfernt.** Die drei Ellipsen mit `blur(radius: 34)` und `repeatForever`-Skalierung sind komplett raus. Damit fallen pro Frame drei großflächige Blur-Passes und drei Endlos-Animationen weg.
- **Doppelte Schatten entfernt.** Glas-Karten hatten zwei Schatten (`radius: 20` plus `radius: 26` mit Akzentfarbe). Jede Karte hat nur noch einen leisen, schwarzen Schatten.
- **Statischer Hintergrund.** Ein einziger LinearGradient, kein Blur, keine Animation, kein Canvas. Karten sind flache Flächen (`Color(white: 0.12)`) mit 0.5-pt Haarlinie — nichts, was beim Scrollen nachgerechnet wird.
- **Listen statt verschachtelter Scroll-Container.** Aufgaben, Freigaben, Gedächtnis und Einstellungen laufen als native `List`/`Form`; der Chat als `LazyVStack`.

## Icons und Farbe

- **Keine zehn Farben mehr.** Magenta, Mint, Coral, Gold und Cyan sind aus den Icons verschwunden. Alle SF Symbols sind monochrom (Weiß/Grau), gleiche Strichstärke, keine farbigen Pillen mehr dahinter.
- **Ein Akzent.** Warmes Sand markiert nur aktive Zustände: laufender Lauf, Freigabe-Button, Eingabe-Fokus, aktueller Wert. Fehler und Löschen sind das einzige weitere Farbsignal.
- **Status ohne Kirmes.** Status-Chips sind Text mit einem kleinen Punkt, keine leuchtenden Kapseln.

## Screens

### Heute
- Ruhige Begrüßung: „Guten Tag, Joel“, darunter Datum und Engine.
- Eine Übersichtskarte: Fokus des Tages, Zahlen zu Freigaben/Läufen/Ereignissen, Wetterzeile.
- Offene Freigaben und laufende Aufgaben als klare Listenzeilen mit Status-Symbol und Dauer.
- Drei Schnellstart-Aktionen (GTA-6-News, GitHub CI, Morgen-Briefing).
- Zuletzt geprüfte Quellen als leise Liste. Kein Laufband, kein Emblem, keine Telemetrie-Chips.

### Chat
- Verlauf wie in iMessage: eigene Nachrichten rechts in einer ruhigen Fläche, Antworten links als Text.
- Werkzeug-Ausführungen sind **eine Zeile**: „2 Schritte ausgeführt“. Ein Tipp klappt Werkzeugnamen, Kurzstatus und Ergebnis auf.
- Leerzustand erklärt den Ablauf in drei Schritten: Ziel → Plan → Ergebnis.
- **Tab-Leiste im Chat ausgeblendet**, damit das Eingabefeld ganz unten am Bildschirmrand sitzt. Keine Kapsel, kein Rahmen, kein Balken über dem Feld — nur eine weiche Fläche.
- Oben links ein Zurück-Pfeil, damit die Navigation ohne Tab-Leiste eindeutig bleibt.

### Aufgaben
- Segmentierte Ansicht: Aktiv, Verlauf, Protokoll.
- Jede Zeile zeigt Titel, Status-Chip und Dauer; aufklappen zeigt Schritte mit Werkzeugnamen, Pause/Abbrechen und die letzten Protokollzeilen.

### Freigaben
- Offene Entscheidungen mit Typ, Risiko, Betrag und vollständiger Vorschau (Empfänger, Betreff, Text).
- Ein klarer Hauptknopf („Freigeben“, bei Mails „Freigeben & senden“), daneben Bearbeiten und Ablehnen.
- Entschiedene Freigaben als schlichte Liste darunter.

### Gedächtnis
- Profil, Themen mit Fakten (Wischen zum Löschen, „Fakt hinzufügen“), verbundene Dienste mit Schaltern, Kontrolle zum Leeren und Sperren.
- Alles im nativen `Form`-Format, keine Karten mit Neon-Kanten.

### Einstellungen
- Reines iOS-`Form`: Modell, Zugang, Darstellung (Bühne und Akzent), Verhalten, Standard-Autonomie, Über.
- KI-Provider: Anbieterliste, Modellwahl, Key (Keychain), Verbindungstest — ohne Marketing-Banner.

### Gatekeeper und Onboarding
- „Willkommen bei Tandem — bitte gib deinen Einladungscode ein.“ Ein Feld, ein Button, dezenter Hinweis `Code: JOEL-VIP`.
- Kein Clearance-Sprech, kein Emblem, keine Code-Liste im Gate.
- Onboarding in zwei ruhigen Schritten: Prinzipien, dann Name/Stadt/Rolle.

## Texte

- Deutsche, klare Sätze. Keine Marketing-Worthülsen, kein Sci-Fi-Sprech („Autonomous Agent“, „Security Clearance“, „Clearance Gate“ sind raus).
- Werkzeugnamen bleiben technisch (`repo.check`, `mail.send`), stehen aber nur dort, wo sie helfen.

## App-Icon

- 1024 × 1024, tiefes Schwarz mit feinem Verlauf, zwei hauchdünne ineinandergreifende Ringe (Elfenbein und Sand). Kein Glow, keine Knoten, kein Emblem.

## Technik

- Version **1.3.0 (Build 4)**, Bundle-ID unverändert `dev.joe.tandem`, iOS 26+
- Design-System neu aufgebaut: `Palette`, `TandemTheme`, `AccentChoice` (sechs ruhige Töne), `Card`, `RowLabel`, `StatusTag`, `PrimaryButtonStyle`
- Alte Zustände bleiben gültig; die Darstellung wird einmalig auf Obsidian/Sand migriert (`tandem.calmMigration`)
- CI unverändert: unsignierte IPA über GitHub Actions

## Installation

1. `TandemAgent-1.3.0.ipa` herunterladen
2. Mit Sideloadly oder AltStore signieren und installieren
3. Einladungscode eingeben — der Agent läuft sofort, auch ohne API-Key

## Bekannte Grenzen

- Werkzeuge sind lokal simuliert: Sie lesen den App-Zustand, gehen aber nicht ins Netz und führen keine echten Mails, Zahlungen oder Commits aus. Die Freigabe-Objekte sind die Naht, an der echte Integrationen später andocken.
- Die Invite-Prüfung bleibt lokal (Preview-Gate, keine Server-Authentifizierung).
- Echte Modelle antworten im Chat; die Task-Engine plant und protokolliert weiterhin lokal.
