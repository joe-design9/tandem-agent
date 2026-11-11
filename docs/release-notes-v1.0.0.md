# Tandem Agent 1.0.0

**Ein proaktiver persönlicher Agent für iPhone — Liquid Glass, lokales Gedächtnis, Freigaben statt Autopilot.**

Tandem denkt mit, statt nur zu antworten: morgens ein Briefing, über den Tag Scans von Postfach, Kalender, Repos und Gerät, und für alles Riskante eine fertige Entscheidung auf dem Tisch.

## Neu in 1.0.0

### Invite-Preview
- Gatekeeper beim ersten Start: *Tandem Research Preview — Invite Required*
- Founder-Keys `JOEL-VIP`, `TANDEM-2026`, `DUET-FOUNDER`, `LEONIDA-DEV` (case-insensitive)
- Generator in *Mehr → Invite Keys teilen*: Codes im Format `TNDM-XXXX-XXXX` erzeugen, kopieren, teilen, als eingelöst markieren, löschen
- Founder-/VIP-Badge im Profil

### Proaktiver Agent
- Morgen-Briefing mit Wetter, Terminen, offenen Todos und Nachtaktivität
- Hintergrund-Scans als Live-Ticker („Mail-Check vor 15 Min.: 0 dringend", „GitHub: alle Repos grün")
- Dringende Vorschläge mit Ein-Klick-Delegation
- Neue Freigaben entstehen von selbst — nie mehr als drei gleichzeitig

### Human in the Loop
- E-Mails, Zahlungen, Kalenderänderungen und Löschungen nur nach Freigabe
- Volltext-Vorschau, Empfänger, Betreff, Risiko und die Begründung des Agenten in jeder Karte
- Bearbeiten, Ablehnen, Freigeben — jede Entscheidung landet im Protokoll

### Autonome Aufgaben
- Ziele in sichtbare Schritte zerlegt, Live-Fortschritt, Pause und Abbruch
- Verlauf erledigter Läufe mit Zusammenfassung
- Vollständiges Audit-Protokoll

### Agent-Chat
- Streaming-Antworten, Tool-Pills (`mail.search`, `github.repos`, `calendar.events`), Markdown inklusive Tabellen
- Rich Cards mit direkter Aktion
- Simulator antwortet offline aus dem echten App-Zustand

### Backbone
- Anthropic Claude (Opus 4.5, Sonnet 4.5, Haiku 4.5), OpenAI, DeepSeek, OpenRouter, eigener OpenAI-kompatibler Endpoint
- API-Keys ausschließlich im iOS-Keychain
- Simulator-Modus als Standard: die App funktioniert sofort, ohne Key und ohne Netz

### Liquid Glass
- Drei Kulissen: Deep Aurora, Neon Vice, Dark Titanium
- Hell / Dunkel / System, vier Akzente, atmender Glow, Haptik
- Frosted Karten, Lichtkanten, animierte Übergänge

## Installation

1. `TandemAgent-1.0.0.ipa` herunterladen
2. Mit Sideloadly oder AltStore signieren und installieren
3. Invite-Key eintragen — fertig

Die IPA ist unsigniert und benötigt iOS 26 oder neuer.

## Bekannte Grenzen

- Die Invite-Prüfung ist lokal (Preview-Gate für Freunde, keine Server-Authentifizierung)
- Tool-Aufrufe im Chat sind Anzeige; echte Ausführung hängt an den Freigabe-Objekten
- Der Simulator ist regelbasiert, kein Sprachmodell
