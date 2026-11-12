# Tandem — Agent

**Ein persönlicher Agent für iPhone — 1.3.0 „Handcrafted & Butterweich“: radikal aufgeräumt, monochrom, ruhig. Ziel rein, Plan raus, Werkzeuge laufen, alles Riskante wartet auf dein Ja.**

Tandem ist kein Chatfenster mit Extras. Du gibst ein Ziel, der Agent plant Schritte, ruft Werkzeuge auf (`web.scan`, `repo.check`, `mail.triage`, `memory.sync`) und legt dir alles Riskante als fertige Entscheidung auf den Tisch — die du mit einem Tipp freigibst oder ablehnst.

> Tandem ist eine **Research Preview**. Der Zugang hängt an einem Invite-Code, nicht an einem App-Store-Account.

---

## Was drin ist

| Bereich | Was es tut |
| --- | --- |
| **Heute** | Begrüßung, ein Überblick (Fokus, Freigaben, Läufe, Ereignisse), offene Entscheidungen, laufende Aufgaben und drei Wege, den Agenten direkt loszuschicken. |
| **Agent-Engine** | Ziel rein: Absicht erkennen → Schritte planen → Werkzeuge aufrufen → Ergebnis synthetisieren. Läufe überleben einen App-Neustart, lassen sich pausieren und abbrechen. |
| **Werkzeug-Registry** | Lesend: `web.scan`, `web.read`, `news.rank`, `repo.check`, `ci.inspect`, `mail.triage`, `mail.rank`, `calendar.read`, `calendar.plan`, `memory.sync`, `weather.read`, `brief.compose`, `doc.write`. Schreibend nur nach Freigabe: `mail.send`, `calendar.create`, `pay.charge`, `github.artifacts.delete`. |
| **Freigaben** | E-Mails, Zahlungen, Kalender, Löschungen: Tandem bereitet vor, führt aber **nichts** ohne dein Ja aus. Empfänger, Betreff, Volltext, Betrag und Begründung stehen in der Vorschau. |
| **Aufgaben** | Aktiv, Verlauf und Protokoll in einer Liste. Titel, Status-Chip, Dauer; Schritte und Protokoll klappen auf Wunsch auf. |
| **Chat** | Ruhiger Verlauf wie in iMessage. Werkzeuge erscheinen als eine Zeile („3 Schritte ausgeführt“) und klappen sich auf Tipp auf. Streaming und Markdown inklusive Tabellen. |
| **Gedächtnis** | Profil, Projekte, Familie, Vorlieben, Arbeitsrhythmus — jeder Fakt sichtbar, ergänzbar, löschbar. Liegt lokal. |
| **Invite-Codes** | Codes erzeugen, kopieren, teilen, löschen. Jeder Code schaltet eine Installation frei. |
| **Multi-Provider** | Anthropic Claude, OpenAI, DeepSeek, OpenRouter und jeder OpenAI-kompatible eigene Endpoint. Keys im iOS-Keychain. |
| **Simulator** | Läuft **ohne API-Key** und ohne Netz: erkennt Absichten, baut Pläne, ruft Werkzeuge gegen den echten App-Zustand auf und antwortet daraus. Direkt nach dem Sideloading benutzbar. |
| **Design** | Tiefes Obsidian-Schwarz, eine Fläche pro Karte, monochrome SF Symbols, genau ein warmer Akzent für aktive Zustände. Keine Blurs, keine Animationen im Hintergrund, keine Neon-Rahmen. |

---

## Invite-Code

Beim ersten Start steht die ruhige Willkommensseite: **„Willkommen bei Tandem — bitte gib deinen Einladungscode ein.“**

- **Immer gültig:**
  - `JOEL-VIP`
  - `VICE-VIP`
  - `LEONIDA-DEV`
  - `OCEAN-DRIVE`
  - `TANDEM-2026`
  - `DUET-FOUNDER`
- **Generierte Codes**: Format `TNDM-XXXX-XXXX`, erzeugt in *Mehr → Invite-Codes*.
- Eingabe ist case-insensitive, der Status wird dauerhaft gespeichert.

> Die Prüfung passiert lokal im Gerät. Das ist ein Preview-Gate für Freunde — keine Server-Authentifizierung. Wer die IPA auseinandernimmt, findet die Codes; für eine echte Beta gehört ein Backend davor.

---

## Installation (Sideloadly / AltStore)

1. `TandemAgent-1.3.0.ipa` aus den [Releases](https://github.com/joe-design9/tandem-agent/releases/latest) laden.
2. In Sideloadly (oder AltStore) mit der eigenen Apple-ID signieren und aufs iPhone schieben.
3. App öffnen → Einladungscode eintragen → loslegen.

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
zip -qry TandemAgent-1.3.0.ipa Payload
```

---

## API-Keys

`Mehr → Modell` → Anbieter wählen → Key eintragen → **Key sichern** → **Verbindung testen**.

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
├── Design/         Glass (Palette, Flächen, Typografie, Haptik), RichText (Markdown + Tabellen)
├── Features/       InviteGate, Onboarding, Home, Approvals, Tasks, Chat, Memory, Settings, InviteKeys
└── Services/       AIService (Streaming, 5 Provider), DemoBrain (Agenten-Simulator), Keychain
.github/workflows/  build-ipa.yml (unverändert: unsignierte IPA, Release-Upload)
```

**Sicherheitsmodell:** `AgentEngine` führt einen Plan schrittweise aus und schreibt jeden Werkzeugaufruf in ein `AgentLogEntry`-Protokoll. Sensible Werkzeuge geben keine Wirkung zurück, sondern ein `ApprovalRequest` — der Lauf endet dann auf dem Tisch statt in der Welt. `ApprovalRequest` hat `pending → executed | rejected`, jede Entscheidung schreibt ein `AuditEvent`. Der Chat kann Aktionen nur *vorschlagen*: die Ausführung hängt am Freigabe-Objekt, nicht am Text des Modells.

---

## Changelog

### 1.3.0 — 12. November 2026 · Handcrafted & Butterweich
- **Performance:** Canvas-Körnung (900 Pixel-Loops), animierte Blur-Ellipsen (`repeatForever`, `blur(radius: 34)`) und doppelte Schatten auf jeder Karte entfernt. Der Hintergrund ist jetzt ein einziger statischer Verlauf; Karten sind flache Flächen mit Haarlinie. Scrollen läuft ohne Metal-Last.
- **Design:** Alle Neon-Badges, Telemetrie-Laufbänder, Embleme und Glow-Ränder raus. Monochrome SF Symbols mit einheitlicher Strichstärke, ein Akzent (Sand) nur für aktive Zustände, native große Titel, großzügiges Spacing.
- **Heute:** Ruhige Begrüßung, eine Übersichtskarte, Freigaben und Läufe als klare Listen, drei Schnellstart-Aktionen.
- **Chat:** iMessage-naher Verlauf, Werkzeug-Ausführung als eine dezente, aufklappbare Zeile („2 Schritte ausgeführt“). Tab-Leiste im Chat ausgeblendet, Eingabe sitzt unten am Rand — ohne Kapsel, ohne Rahmen.
- **Aufgaben:** Native Liste mit Status-Chip und Dauer; Schritte, Aktionen und Protokoll klappen pro Lauf auf.
- **Einstellungen:** Reines iOS-`Form` mit gruppierten Abschnitten für Modell, Zugang, Darstellung, Verhalten, Autonomie.
- **Gatekeeper:** „Willkommen bei Tandem“, ein Feld, ein Button, dezenter Hinweis `Code: JOEL-VIP`.
- **Icon:** Neues 1024×1024-Icon — tiefes Schwarz, zwei feine ineinandergreifende Ringe.
- Version 1.3.0 (Build 4).

### 1.2.0 — 12. November 2026 · The Autonomous Agent
- **Agent-Engine:** Ziel → Absicht → Plan → Werkzeuge → Synthese; Läufe mit Pause, Abbruch und Wiederaufnahme nach Neustart
- **Werkzeug-Registry:** 22 Werkzeuge, lesend und schreibend; sensible Schritte erzeugen eine Freigabe statt einer Wirkung
- **Audit Log pro Lauf:** jeder Schritt mit Zeitstempel, Werkzeug und Ergebnis, aufklappbar im Läufe-Tab
- **Chat mit Werkzeug-Karten:** Planung → Tool → Ergebnis, animierte Zustände
- **Design-Overhaul:** Synthwave-Grid, Vektor-Sonne, Palmen und Scanlines entfernt; Obsidian-Bühne, atmende Lichtkegel, echtes Liquid Glass, Condensed-Typografie, dark-only
- **LEONIDA CLEARANCE GATE** mit Clearance-Liste
- **KI-Provider-Banner** mit Claude, OpenAI, DeepSeek, OpenRouter und „Testen“ pro Anbieter
- Neues Emblem-Icon
- Version 1.2.0 (Build 3), Zustand v3

### 1.1.0 — 12. November 2026 · Vice City / Leonida Edition
- Neue Standard-Kulisse **Electric Vice**: animierter Sonnenuntergang, laufendes Perspektiv-Grid, Skyline, Palmen, Sternenstaub, Neon-Partikel, Scanlines
- GTA-6-Farbraum durch die ganze App; Neon-Kanten und Glow auf allen Karten
- Gatekeeper als **Leonida Research Preview** mit Palmen-Neon-Emblem
- Invite-Codes im Vice-Style (`VICE-XXXX-XXXX` / `TNDM-XXXX-XXXX`)
- Neues App-Icon und Version 1.1.0 (Build 2)

### 1.0.0 — 11. November 2026
- Erste vollständige Version: Briefing, Freigaben, Aufgaben, Chat, Gedächtnis, Einstellungen
- Invite-Gatekeeper + Key-Generator
- Liquid Glass in drei Kulissen, Hell/Dunkel
- Multi-Provider-Backbone mit Keychain-Keys und Offline-Simulator
- GitHub-Actions-Build: unsignierte IPA

---

Gebaut für **Joel** (@joe-design9). Tandem ist ein eigenständiges Produkt — inspiriert von der Idee eines autonomen Agenten, nicht eine Kopie.
