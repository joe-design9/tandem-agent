# Tandem — Agent

**Ein autonomer persönlicher Agent für iPhone — 1.2.0 „The Autonomous Agent“: echte Task-Engine mit Werkzeugen, Obsidian-Dark-Mode mit Liquid Glass, lokales Gedächtnis, Freigaben statt Autopilot.**

Tandem ist kein Chatfenster mit Extras. Du gibst ein Ziel, der Agent plant Schritte, ruft Werkzeuge auf (`web.scan`, `repo.check`, `mail.triage`, `memory.sync`) und legt dir alles Riskante als fertige Entscheidung auf den Tisch — die du mit einem Tipp freigibst oder ablehnst.

> Tandem ist eine **Research Preview**. Der Zugang hängt an einem Invite-Key, nicht an einem App-Store-Account.

---

## Was drin ist

| Bereich | Was es tut |
| --- | --- |
| **Morgen-Briefing** | Wetter, Termine, offene Todos und Nachtaktivität in einer Karte. Ein Tipp baut es neu. |
| **Agent-Engine** | Ziel rein: Absicht erkennen → Schritte planen → Werkzeuge aufrufen → Ergebnis synthetisieren. Läufe überleben einen App-Neustart, lassen sich pausieren und abbrechen. |
| **Werkzeug-Registry** | Lesend: `web.scan`, `web.read`, `news.rank`, `repo.check`, `ci.inspect`, `mail.triage`, `mail.rank`, `calendar.read`, `calendar.plan`, `memory.sync`, `weather.read`, `brief.compose`, `doc.write`. Schreibend nur nach Freigabe: `mail.send`, `calendar.create`, `pay.charge`, `github.artifacts.delete`. |
| **Freigaben (Human in the Loop)** | E-Mails, Zahlungen, Kalender, Löschungen: Tandem bereitet vor, führt aber **nichts** ohne dein Ja aus. Empfänger, Betreff, Volltext, Betrag, Risiko und Begründung stehen in der Karte — mit [Freigeben] und [Ablehnen]. |
| **Autonome Läufe** | Status-Pillen, Fortschritt, Schritte mit Werkzeugnamen und ein aufklappbares Ausführungsprotokoll (Audit Log) mit Zeitstempeln. |
| **Agent-Chat** | Werkzeug-Karten statt Textwüste: `[Planung aktiv…]` → `[Tool: repo.check]` → `[Ergebnis]`. Streaming, Markdown inklusive Tabellen und Rich Cards mit direkter Aktion. |
| **Gedächtnis** | Profil, Projekte, Familie, Vorlieben, Arbeitsrhythmus — jeder Fakt sichtbar, ergänzbar, löschbar. Liegt lokal. |
| **Invite-Keys** | Founder-Zugänge plus Generator: Codes erzeugen, kopieren, teilen, als eingelöst markieren, löschen. |
| **Multi-Provider** | Anthropic Claude, OpenAI, DeepSeek, OpenRouter und jeder OpenAI-kompatible eigene Endpoint. Keys im iOS-Keychain. |
| **Simulator** | Läuft **ohne API-Key** und ohne Netz: erkennt Absichten, baut Pläne, ruft Werkzeuge gegen den echten App-Zustand auf und antwortet daraus. Direkt nach dem Sideloading benutzbar. |
| **Rockstar Dark Mode** | Obsidian `#08050D`, zwei organisch atmende Lichtkegel in Neon-Magenta und Cyan, echtes Liquid Glass (`.ultraThinMaterial`, 0.5-pt Kantenlicht), schwere Condensed-Typografie. Kein Grid, keine Sonne, keine Scanlines. Vier Lichtstimmungen, acht Akzente. |

---

## Invite-Key

Beim ersten Start steht das **LEONIDA CLEARANCE GATE**.

- **Clearance-Codes** (die ersten vier schalten zusätzlich das Founder-Badge frei):
  - `JOEL-VIP` (Founder)
  - `VICE-VIP` (VIP)
  - `LEONIDA-DEV` (Developer)
  - `OCEAN-DRIVE` (Guest)
  - `TANDEM-2026`
  - `DUET-FOUNDER` (aus 1.0.0 weiter gültig)
- **Generierte Keys**: Format `VICE-XXXX-XXXX` oder `TNDM-XXXX-XXXX`, erzeugt in *Mehr → Invite Keys teilen*. Jeder Code schaltet eine Installation frei.
- Eingabe ist case-insensitive, der Status wird dauerhaft gespeichert.

> Die Prüfung passiert lokal im Gerät. Das ist ein Preview-Gate für Freunde — keine Server-Authentifizierung. Wer die IPA auseinandernimmt, findet die Keys; für eine echte Beta gehört ein Backend davor.

---

## Installation (Sideloadly / AltStore)

1. `TandemAgent-1.2.0.ipa` aus den [Releases](https://github.com/joe-design9/tandem-agent/releases/latest) laden.
2. In Sideloadly (oder AltStore) mit der eigenen Apple-ID signieren und aufs iPhone schieben.
3. App öffnen → Invite-Key eintragen → loslegen.

Die IPA ist **unsigniert** (CI-Build ohne Zertifikat) und braucht iOS 26 oder neuer.

---

## Selbst bauen

```bash
git clone https://github.com/joe-design9/tandem-agent.git
cd tandem-agent
open TandemAgent.xcodeproj
```

- SwiftUI, iOS 26.0 Deployment Target, Swift-6.2-Toolchain
- Bundle-ID `dev.joe.tandem`
- Keine externen Abhängigkeiten, kein Package Manager, kein Netzwerk im Simulator-Modus

Unsignierte IPA bauen (wie in der CI):

```bash
xcodebuild -project TandemAgent.xcodeproj -scheme TandemAgent \
  -configuration Release -sdk iphoneos \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
mkdir Payload && cp -R build/Build/Products/Release-iphoneos/Tandem.app Payload/
zip -qry TandemAgent-1.2.0.ipa Payload
```

---

## API-Keys

`Mehr → Backbone` → Anbieter wählen → Key eintragen → **Sichern** → **Verbindung testen**.

| Anbieter | Modelle | Key |
| --- | --- | --- |
| Tandem Simulator | lokal, regelbasiert | keiner |
| Anthropic Claude | Opus 4.5, Sonnet 4.5, Haiku 4.5 | `sk-ant-…` |
| OpenAI | GPT-4o, GPT-4.1, o4-mini | `sk-…` |
| DeepSeek | Chat, Reasoner | `sk-…` |
| OpenRouter | Claude, GPT, Gemini, Llama | `sk-or-…` |
| Eigener Endpoint | beliebig, OpenAI-kompatibel | optional |

Keys liegen ausschließlich im Keychain (`kSecClassGenericPassword`, `AfterFirstUnlock`) und gehen nur an den gewählten Anbieter. Ohne Key schaltet Tandem automatisch auf den Simulator — die App funktioniert also immer.

---

## Aufbau

```
TandemAgent/
├── App/            TandemApp, RootView, Tabs, Toast, QA-Overlay
├── Core/           Models, TandemStore (Zustand), AgentEngine (Ausführung), TaskPlanner, ToolRegistry, InviteKeys
├── Design/         Glass (Obsidian-Bühne, Glasflächen, Typografie, Haptik), RichText (Markdown + Tabellen)
├── Features/       InviteGate, Onboarding, Home, Approvals, Tasks, Chat, Memory, Settings, InviteKeys
└── Services/       AIService (Streaming, 5 Provider), DemoBrain (Agenten-Simulator), Keychain
.github/workflows/  build-ipa.yml, qa-screenshots.yml
```

**Sicherheitsmodell:** `AgentEngine` führt einen Plan schrittweise aus und schreibt jeden Werkzeugaufruf in ein `AgentLogEntry`-Protokoll. Sensible Werkzeuge geben keine Wirkung zurück, sondern ein `ApprovalRequest` — der Lauf endet dann auf dem Tisch statt in der Welt. `ApprovalRequest` hat `pending → executed | rejected`, jede Entscheidung schreibt ein `AuditEvent`. Der Chat kann Aktionen nur *vorschlagen*: die Ausführung hängt am Freigabe-Objekt, nicht am Text des Modells.

---

## Changelog

### 1.2.0 — 12. November 2026 · The Autonomous Agent
- **Agent-Engine:** Ziel → Absicht → Plan → Werkzeuge → Synthese; Läufe mit Pause, Abbruch und Wiederaufnahme nach Neustart
- **Werkzeug-Registry:** 22 Werkzeuge, lesend und schreibend; sensible Schritte erzeugen eine Freigabe statt einer Wirkung
- **Audit Log pro Lauf:** jeder Schritt mit Zeitstempel, Werkzeug und Ergebnis, aufklappbar im Läufe-Tab
- **Chat mit Werkzeug-Karten:** Planung → Tool → Ergebnis, animierte Zustände
- **Design-Overhaul:** Synthwave-Grid, Vektor-Sonne, Palmen und Scanlines entfernt; Obsidian-Bühne, atmende Lichtkegel, echtes Liquid Glass, Condensed-Typografie, dark-only
- **LEONIDA CLEARANCE GATE** mit Clearance-Liste (`JOEL-VIP`, `VICE-VIP`, `LEONIDA-DEV`, `OCEAN-DRIVE`)
- **KI-Provider-Banner** mit Claude, OpenAI, DeepSeek, OpenRouter und „Testen“ pro Anbieter
- Neues Emblem-Icon (Obsidian, zwei Leucht-Ringe, sechs Knoten)
- Version 1.2.0 (Build 3), Zustand v3

### 1.1.0 — 12. November 2026 · Vice City / Leonida Edition
- Neue Standard-Kulisse **Electric Vice**: animierter Sonnenuntergang, laufendes Perspektiv-Grid, Skyline, Palmen, Sternenstaub, Neon-Partikel, Scanlines
- GTA-6-Farbraum durch die ganze App: Cyan, Magenta, Coral, Gold auf Mitternachtsviolett; Neon-Kanten und Glow auf allen Karten
- Gatekeeper als **Leonida Research Preview** mit Palmen-Neon-Emblem und glühendem Key-Feld
- **Leonida Morning Dispatch**, **Weazel-News-Band**, **ViceNet Monitor**, „Vice City Agent Protocol“ auf Freigaben
- Invite-Codes im Vice-Style (`VICE-XXXX-XXXX` / `TNDM-XXXX-XXXX`), VIP-Founder-Karte mit Neon-Palme
- Neues App-Icon (Vice-Sunset, Palme, Grid) und Version 1.1.0 (Build 2)

### 1.0.0 — 11. November 2026
- Erste vollständige Version: Briefing, Freigaben, Aufgaben, Chat, Gedächtnis, Einstellungen
- Invite-Gatekeeper + Key-Generator mit Founder-Badge
- Liquid Glass in drei Kulissen, Hell/Dunkel
- Multi-Provider-Backbone mit Keychain-Keys und Offline-Simulator
- GitHub-Actions-Build: unsignierte IPA + Simulator-Screenshots

---

Gebaut für **Joel** (@joe-design9). Tandem ist ein eigenständiges Produkt — inspiriert von der Idee eines autonomen Agenten, nicht eine Kopie.
