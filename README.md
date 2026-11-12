# Tandem — Agent

**Ein proaktiver persönlicher Agent für iPhone — jetzt in der Leonida Edition: Liquid Glass im Vice-City-Sonnenuntergang, lokales Gedächtnis, Freigaben statt Autopilot.**

Tandem ist kein Chatfenster mit Extras. Es ist ein Agent, der im Hintergrund mitdenkt: morgens ein Briefing, über den Tag Scans von Postfach, Kalender, Repos und Gerät, und für alles Riskante eine fertige Entscheidung auf dem Tisch — die du mit einem Tipp freigibst oder ablehnst.

> Tandem ist eine **Research Preview**. Der Zugang hängt an einem Invite-Key, nicht an einem App-Store-Account.

---

## Was drin ist

| Bereich | Was es tut |
| --- | --- |
| **Morgen-Briefing** | Wetter, Termine, offene Todos und Nachtaktivität in einer Karte. Ein Tipp baut es neu. |
| **Proaktive Engine** | Hintergrund-Scans als Ticker: „Mail-Check vor 15 Min.: 0 dringend", „GitHub: alle Repos grün". Neue Vorschläge landen von selbst auf dem Tisch. |
| **Freigaben (Human in the Loop)** | E-Mails, Zahlungen, Kalender, Löschungen: Tandem bereitet vor, führt aber **nichts** ohne dein Ja aus. Empfänger, Betreff, Volltext, Risiko und Begründung stehen in der Karte. |
| **Autonome Aufgaben** | Ein Ziel, sichtbare Schritte, Live-Fortschritt, Pause und Abbruch. Dazu Verlauf und vollständiges Protokoll. |
| **Agent-Chat** | Streaming-Antworten, Tool-Pills (`mail.search`, `github.repos`, `calendar.events`), Markdown inklusive Tabellen und Rich Cards mit direkter Aktion. |
| **Gedächtnis** | Profil, Projekte, Familie, Vorlieben, Arbeitsrhythmus — jeder Fakt sichtbar, ergänzbar, löschbar. Liegt lokal. |
| **Invite-Keys** | Founder-Zugänge plus Generator: Codes erzeugen, kopieren, teilen, als eingelöst markieren, löschen. |
| **Multi-Provider** | Anthropic Claude, OpenAI, DeepSeek, OpenRouter und jeder OpenAI-kompatible eigene Endpoint. Keys im iOS-Keychain. |
| **Simulator** | Läuft **ohne API-Key** und ohne Netz: liest den echten App-Zustand (Freigaben, Aufgaben, Briefing, Gedächtnis) und antwortet daraus. Direkt nach dem Sideloading benutzbar. |
| **Liquid Glass** | Electric Vice: animierter Sonnenuntergang, Perspektiv-Grid, Palmen, Neon-Partikel. Karten mit Magenta-Cyan-Kante und atmendem Glow. Vier Kulissen (Electric Vice, Neon Vice, Deep Aurora, Titanium), acht Akzente, Hell/Dunkel/System, Haptik. |

---

## Invite-Key

Beim ersten Start steht der Gatekeeper: *Tandem — Leonida Research Preview*.

- **Founder-Keys** (schalten zusätzlich das Founder-/VIP-Badge frei):
  - `JOEL-VIP`
  - `VICE-VIP`
  - `LEONIDA-DEV`
  - `OCEAN-DRIVE`
  - `TANDEM-2026`
  - `DUET-FOUNDER` (aus 1.0.0 weiter gültig)
- **Generierte Keys**: Format `VICE-XXXX-XXXX` oder `TNDM-XXXX-XXXX`, erzeugt in *Mehr → Invite Keys teilen*. Jeder Code schaltet eine Installation frei.
- Eingabe ist case-insensitive, der Status wird dauerhaft gespeichert.

> Die Prüfung passiert lokal im Gerät. Das ist ein Preview-Gate für Freunde — keine Server-Authentifizierung. Wer die IPA auseinandernimmt, findet die Keys; für eine echte Beta gehört ein Backend davor.

---

## Installation (Sideloadly / AltStore)

1. `TandemAgent-1.1.0.ipa` aus den [Releases](https://github.com/joe-design9/tandem-agent/releases/latest) laden.
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
zip -qry TandemAgent-1.1.0.ipa Payload
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
├── Core/           Models, TandemStore (Zustand + Engine), TaskPlanner, InviteKeys
├── Design/         Glass (Kulissen, Glasflächen, Haptik), RichText (Markdown + Tabellen)
├── Features/       InviteGate, Onboarding, Home, Approvals, Tasks, Chat, Memory, Settings, InviteKeys
└── Services/       AIService (Streaming, 5 Provider), DemoBrain, Keychain
.github/workflows/  build-ipa.yml, qa-screenshots.yml
```

**Sicherheitsmodell:** `TandemStore` führt jede Aktion über einen Freigabe-Zustand. `ApprovalRequest` hat `pending → executed | rejected`, jede Entscheidung schreibt ein `AuditEvent`. Aufgaben laufen in `TaskPlanner`-Schritten und halten bei riskanten Schritten an. Der Chat kann Aktionen nur *vorschlagen*: Tool-Aufrufe sind Anzeige, die Ausführung hängt am Freigabe-Objekt.

---

## Changelog

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

Gebaut für **Joel** (@joe-design9). Tandem ist ein eigenständiges Produkt — inspiriert von der Idee eines proaktiven Agenten, nicht eine Kopie.
