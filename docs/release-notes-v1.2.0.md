# Tandem Agent 1.2.0 — The Autonomous Agent

**Aus dem Assistenten wird ein Agent: Ziel rein, Plan raus, Werkzeuge laufen — und alles Riskante hält an, bis du ja sagst. Dazu ein Design, das nicht mehr nach Synthwave-Kulisse aussieht, sondern nach Produkt: Obsidian-Schwarz, echtes Liquid Glass, Rockstar-Typografie.**

1.1.0 war eine Bühne. 1.2.0 ist die Engine dahinter.

## Der Agent

### Autonome Task-Engine (`AgentEngine`)
- Ein Ziel genügt: „überwache die GTA-6-News“, „prüfe meine GitHub CI Pipelines“, „stelle mein Morgen-Briefing zusammen“.
- Der Lauf hat eine echte Struktur: **Ziel analysieren → Absicht bestimmen → Schritte planen → Werkzeuge aufrufen → Ergebnis synthetisieren**.
- `TaskPlanner` erkennt die Absicht aus mehreren Signalen statt aus einem Stichwort und bindet jeden Schritt an ein Werkzeug.
- `AgentEngine` führt die Schritte aus, schreibt jeden Aufruf ins Protokoll, respektiert Pause und Abbruch und nimmt nach einem App-Neustart angefangene Läufe wieder auf.
- Abgeschlossene Läufe wandern mit Zusammenfassung in den Verlauf, jedes benutzte Werkzeug erscheint im globalen Protokoll.

### Werkzeuge (`ToolRegistry`)
- **Lesend:** `web.scan`, `web.read`, `news.rank`, `repo.check`, `ci.inspect`, `mail.triage`, `mail.rank`, `calendar.read`, `calendar.plan`, `memory.sync`, `weather.read`, `brief.compose`, `doc.write`
- **Schreibend, aber gesperrt bis Freigabe:** `mail.draft` / `mail.send`, `calendar.create`, `pay.charge`, `github.artifacts.delete`
- **Meta:** `plan.build`, `approval.queue`, `result.synthesis`
- Jedes Werkzeug liefert eine Kurzzeile für die Status-Pille, Protokollzeilen und — wo nötig — eine fertige Freigabe.

### Human in the Loop
- Sensible Schritte erzeugen automatisch eine **Approval Card** mit Empfänger, Betreff, Volltext, Betrag, Risiko und Begründung.
- Klare Aktionen: **[Freigeben]**, **[Freigeben & Senden]**, **[Ablehnen]** — nichts geht ohne dein Ja raus.
- Doppelte Vorschläge werden zusammengehalten, der Tisch läuft nicht über (maximal vier offene Freigaben).

### Live-Fortschritt und Audit Log
- Animierte Status-Pillen (läuft, pausiert, erledigt, abgebrochen), Fortschrittsbalken pro Lauf.
- Jeder Schritt zeigt sein Werkzeug (`repo.check`, `mail.draft`, …) und sein Ergebnis.
- **Aufklappbares Ausführungsprotokoll** pro Aufgabe: Zeitstempel, Werkzeuge, Zwischenergebnisse, Freigaben — bis zu 80 Einträge pro Lauf.

## Der Chat

- **Werkzeug-Karten statt Textwüste:** `[Planung aktiv…]` → `[Tool: repo.check]` → `[Ergebnis]`, jede Karte mit eigenem Icon, Status und Resultat.
- Der Simulator ist kein Keyword-Matcher mehr: Er erkennt Absichten, baut Pläne, streamt Zwischenschritte und antwortet mit Bezug auf Köln, deine Projekte, GTA 6 und deine Playtests — mit trockenem Humor.
- Delegation direkt aus dem Chat: „überwache …“, „prüfe …“, „starte …“ legt einen echten Lauf an und verlinkt ihn im Chat.
- Streaming, Stopp, Denk-Indikator und Rich Cards bleiben.

## Das Design

- **Synthwave raus:** keine Gridlines, keine gestreifte Vektor-Sonne, keine Palmen, keine Scanlines, kein CRT-Look.
- **Obsidian-Bühne:** Tiefschwarz `#08050D` / `#0B0714` mit zwei weichen, organisch atmenden Lichtkegeln in Neon-Magenta und Electric-Cyan, feiner Körnung und ruhiger Vignette.
- **Echtes Liquid Glass:** `.ultraThinMaterial` mit 0.5-pt Kantenlicht, tiefem Kontrast und knackiger Lesbarkeit; Akzentfarben nur noch als leiser Tint, nicht als Leuchtreklame.
- **Typografie:** SF Pro Display, schmale schwere Headlines (condensed), weit gesperrte Kleinbuchstaben für Labels, mono Werkzeugnamen — klare Apple-/Rockstar-Hierarchie.
- **Dark by design:** Die Bühne bleibt immer dunkel, weil weiße Typografie auf Glas nur dort funktioniert.
- Vier Kulissen (Obsidian Vice, Neon Nocturne, Deep Aurora, Titanium) und acht Akzente bleiben, jetzt als Lichtstimmungen statt als Effektfeuerwerk.

## Der Gatekeeper

- **LEONIDA CLEARANCE GATE**: Emblem aus zwei Leucht-Ringen und sechs Knoten, Titel in schwerer Condensed-Schrift, Clearance-Codes als elegante Liste zum Einsetzen.
- Codes: `JOEL-VIP` (Founder), `VICE-VIP` (VIP), `LEONIDA-DEV` (Developer), `OCEAN-DRIVE` (Guest). `TANDEM-2026` und `DUET-FOUNDER` bleiben gültig.
- Der Gatekeeper heißt jetzt, was er tut: Clearance freigeben, nicht „Vice City betreten“.

## Echte KI in Sekunden

- Prominentes Banner in **Mehr → KI-Provider**: Claude, OpenAI, DeepSeek und OpenRouter, jeweils mit Modellreihe, Key-Status und direkter **„Testen“**-Aktion.
- Ein Tipp auf eine Zeile wählt den Anbieter und öffnet die Modellwahl; ein Key schaltet die volle Agenten-Power frei (Streaming, langer Kontext).
- Keys liegen weiterhin ausschließlich im iOS-Keychain. Ohne Key bleibt der Simulator aktiv.

## App-Icon

- Neues 1024 × 1024-Icon: Obsidian-Schwarz, zwei hauchdünne Leucht-Ringe (Magenta innen, Cyan außen) mit sechs Knoten und einem hellen Kern. Keine Clip-Art, keine Sonne, kein Grid.

## Technik

- Version **1.2.0 (Build 3)**, Bundle-ID unverändert `dev.joe.tandem`, iOS 26+
- Neue Dateien: `Core/ToolRegistry.swift`, `Core/AgentEngine.swift`
- Zustand v3 (`tandem-state-v3.json`) mit Aufgaben-Protokoll; alte Demo-Zustände werden beim ersten Start frisch aufgebaut
- CI unverändert: unsignierte IPA über GitHub Actions

## Installation

1. `TandemAgent-1.2.0.ipa` herunterladen
2. Mit Sideloadly oder AltStore signieren und installieren
3. Clearance-Code eingeben — der Agent läuft sofort, auch ohne API-Key

## Bekannte Grenzen

- Werkzeuge sind lokal simuliert: Sie lesen den App-Zustand, gehen aber nicht ins Netz und führen keine echten Mails, Zahlungen oder Commits aus. Die Freigabe-Objekte sind die Naht, an der echte Integrationen später andocken.
- Die Invite-Prüfung bleibt lokal (Preview-Gate, keine Server-Authentifizierung).
- Echte Modelle antworten im Chat; die Task-Engine plant und protokolliert weiterhin lokal.
