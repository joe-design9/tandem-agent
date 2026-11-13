# Tandem Agent 1.4.0 — Siri AI Edition

**Kein API-Key, kein Setup, kein „Lokal“-Etikett. Tandem ist jetzt ein Siri-Agent: Die Engine läuft auf dem Gerät, versteht Smalltalk, und du kannst sie mit „Hey Siri, frag Tandem nach meinem Briefing“ aufrufen.**

1.3.0 hat aufgeräumt. 1.4.0 gibt Tandem das Gehirn, das es versprochen hat — ohne Key.

---

## Siri und Shortcuts (App Intents)

Tandem bringt drei native Intents mit. Sie liegen in **`TandemAgent/Core/TandemIntents.swift`**, laufen im App-Prozess und lesen denselben Zustand, den du auf dem Bildschirm siehst — kein Netz, kein Konto, kein Server.

| Intent | Was er tut |
| --- | --- |
| **BriefingIntent** | Liest den Tag vor: Wetter und Temperatur, nächster Termin, wie viele Freigaben auf dich warten, wie viele Läufe unterwegs sind, der erste offene Punkt aus dem Briefing. |
| **RepoCheckIntent** | Prüft `gta6-hub`, `tandem-agent`, `playtest-vault` und `gta-vi-news`, nennt den Stand und schreibt den Lauf ins Audit-Log. |
| **QuickTaskIntent** | Legt mit einem Satz einen Auftrag an und startet den Lauf. Der Parameter „Auftrag“ wird von Siri erfragt, wenn du ihn weglässt. |

**Feste Siri-Phrasen** (`TandemShortcutsProvider`, ein `AppShortcutsProvider`):

- „Frag Tandem nach meinem Briefing“
- „Was steht heute an laut Tandem“
- „Lass Tandem meine Repos prüfen“
- „Prüfe meine Repos mit Tandem“
- „Leg einen Auftrag in Tandem an“
- „Neuer Auftrag für Tandem“

Die Shortcuts erscheinen automatisch in der **Kurzbefehle-App**, in **Spotlight** und bei **Siri** — ohne dass du etwas einrichtest. Zusätzlich sind alle drei Aktionen als „Aktion hinzufügen“ in eigenen Kurzbefehlen und Automationen verfügbar (z. B. Briefing jeden Morgen um 7:00 als Ansage).

---

## Die Engine: Siri AI (On-Device)

`DemoBrain` heißt jetzt **`OnDeviceBrain`** und steht in **`TandemAgent/Services/OnDeviceBrain.swift`**. Der Name war ehrlich: Es war eine Demo. Jetzt ist es die Engine, die ab Werk antwortet — und sie verhält sich wie ein Assistent, nicht wie ein Formular.

### Was vorher kaputt war

Die alte Erkennung suchte Teilstrings. `„hi“` wurde nur erkannt, wenn ein Leerzeichen dahinter stand — also ging ein nacktes **„Hi“** in den Fallback, und der Fallback baute **immer** einen Plan: `plan.build → memory.sync → web.scan`. Vier Schritte für ein „Hi“. Genau das ist jetzt weg.

### Was jetzt gilt

Zwei Regeln, fest im Code:

1. **Ein Satz Smalltalk ist ein Satz Smalltalk.** Begrüßungen, Dank, Gelächter, Verabschiedungen und Fragen nach dem Befinden bekommen eine Antwort — keinen Lauf.
2. **Eine Aufgabe entsteht nur bei einer Handlungsaufforderung.** Der Planer läuft ausschließlich, wenn die Nachricht mit einem Imperativ beginnt oder einen eindeutigen Auftrag enthält („starte“, „prüf“, „überwache“, „erstell“, „kümmere dich“ …). Fragen beginnen mit „wie“, „was“, „warum“, „wann“ — die werden beantwortet, nicht ausgeführt.

| Du schreibst | Tandem antwortet |
| --- | --- |
| „Hi“ · „Moin“ · „Hey Joel“ | „Moin Joel! Was steht an? Ich habe dein Briefing und deine Repos im Blick.“ — darunter Termin, Freigaben, Läufe, ungelesene Mails. |
| „Danke“ | „Gern, Joel. Dafür bin ich da — auch um drei Uhr nachts.“ |
| „Wie geht's?“ | Kurzer Status: woran er gerade arbeitet, was als Nächstes ansteht, was auf dein Ja wartet. |
| „Lol“ · „geil“ · „ok“ | Locker zurück, ohne Plan. |
| „Was kannst du?“ | Was auf dem Gerät geht — und dass Siri dieselbe Engine aufruft. |
| „Wie spät ist es?“ | Uhrzeit und Tag, ohne Werkzeug. |
| „Erzähl mir was über Quantenphysik“ | Ehrliche Antwort: dafür reicht die lokale Engine nicht, statt einer erfundenen Aufgabe. |
| „Prüf meine Repos“ | **Auftrag.** CI-Audit mit `repo.check → ci.inspect`, Karte im Chat, Lauf im Aufgaben-Tab. |
| „Überwache die GTA-6-News“ | **Auftrag.** Dauerlauf mit `web.scan → news.rank → brief.compose`. |

### Menschlicher Ton

- Die Begrüßung richtet sich nach der Uhrzeit: „Moin“ bis 11, „Hallo“ bis 17, „Guten Abend“ bis 22.
- Antworten tragen echte Zahlen aus dem App-Zustand („**1 Freigabe** auf deinem Tisch · **1 Lauf** unterwegs“), keine Floskeln.
- Kurze Bestätigungen variieren leicht („Immer.“, „Gern, Joel.“, „Klar.“), damit zehn Danksagungen nicht zehnmal gleich klingen.
- Fragen, die die Engine nicht belegen kann, sagt sie offen — und nennt, was sie stattdessen sicher weiß.

---

## Oberfläche

- **Chat-Kopfzeile:** Unter „Tandem“ steht jetzt **„Siri AI“** statt „Lokal“.
- **Heute:** Kopfzeile zeigt „Siri AI“ statt „Lokal“.
- **Mehr → Modell:** Die Standard-Engine heißt **„Siri AI (On-Device)“** mit dem Untertitel „Apple Intelligence · ohne Key, ohne Netz“. Sie ist ab Werk aktiv.
- **Onboarding:** „Siri AI (On-Device) übernimmt den ersten Lauf — ohne Key, ohne Netz.“
- **Verbindungstest:** meldet „Siri AI (On-Device) bereit — kein Key, kein Netz nötig.“
- **Werkzeug-Zeile im Chat:** zeigt bei der On-Device-Engine „Siri AI (On-Device)“ als Quelle.

---

## Technik

- Version **1.4.0 (Build 5)**, Bundle-ID unverändert `dev.joe.tandem`, iOS 26+
- **Neu:** `Core/TandemIntents.swift` (drei Intents + `AppShortcutsProvider` + Siri-Leser auf dem Store)
- **Neu:** `Services/OnDeviceBrain.swift` (ersetzt `Services/DemoBrain.swift`, komplett neu geschrieben)
- **`TandemStore.shared`:** eine Instanz für App, Siri und Shortcuts — die Intents schreiben in denselben Zustand, den die App anzeigt (Aufträge aus Siri erscheinen sofort im Aufgaben-Tab)
- Repo-Liste der Engine an die echten Projekte angepasst: `gta6-hub`, `tandem-agent`, `playtest-vault`, `gta-vi-news`
- Keine neuen Abhängigkeiten, kein Package Manager, kein Netzwerkzugriff
- **`.github/workflows/build-ipa.yml` unverändert** (0 Zeilen Diff): derselbe unsignierte CI-Build, derselbe Release-Upload

---

## Installation

1. `TandemAgent-1.4.0.ipa` aus den Releases laden
2. Mit Sideloadly oder AltStore signieren und installieren
3. Einladungscode eingeben — Tandem antwortet sofort, ohne Key
4. Optional: „Hey Siri, frag Tandem nach meinem Briefing“

---

## Bekannte Grenzen

- Die On-Device-Engine ist regelbasiert, kein Sprachmodell. Sie beantwortet Fragen zu Tag, Wetter, Repos, Postfach, Freigaben und Gedächtnis aus dem App-Zustand — alles darüber hinaus sagt sie offen.
- Die Werkzeuge sind weiterhin lokal simuliert: Sie lesen den App-Zustand, gehen aber nicht ins Netz und führen keine echten Mails, Zahlungen oder Commits aus.
- Die Siri-Phrasen sind fest hinterlegt; frei formulierte Sätze versteht Siri nur im Rahmen dieser Phrasen und der Shortcuts-App.
- Ein echtes Modell (Claude, GPT, DeepSeek, OpenRouter, eigener Endpoint) lässt sich in *Mehr → Modell* weiterhin dazuschalten — nötig ist das nicht mehr.
