# Testleiter — verifizieren ohne Geld, ohne PC, ohne Android-Gerät

Ausgangslage: ein iPhone 14, die Claude-App, ein GitHub-Konto. Sonst nichts.
Kein Mac, kein Android-Gerät, kein bezahltes Entwicklerkonto.

Das ist kein Hindernis, sondern eine Einschränkung mit einer sehr guten Lösung —
solange die Schnittstellenschicht aus `ARCHITEKTUR.md` von Anfang an steht.
Ohne sie funktioniert nichts hiervon.

---

## Stufe 0 — CI-Prüfungen · bei jedem Push · kein Gerät

Läuft in GitHub Actions auf Linux, verbraucht wenige Minuten, kostet nichts.

**Statische Analyse.** `flutter analyze` mit strengen Regeln in
`analysis_options.yaml`. Bricht bei jedem Befund.

**Unit-Tests.** Vor allem die Interpreter. Das ist der Teil mit der höchsten
Fehlerdichte und dem geringsten Testaufwand: Ein Satz geht rein, eine Struktur
kommt raus. Zwölf realistische Beispielsätze je App sind Pflicht, nicht Kür.
„zweiundzwanzig fünfzig bei Rewe" muss zuverlässig 22,50 € ergeben.

**Widget-Tests.** Einzelne Komponenten in Isolation.

**Golden Tests.** Flutter rendert Widgets zu PNG und meldet jede Pixelabweichung.
Damit werden Layout-Regressionen sichtbar, ohne dass jemand etwas ansieht.
Für jede App mindestens: Startbildschirm, Liste, Detail — je hell und dunkel.
Die erzeugten Bilder werden als Artefakt abgelegt und sind auf dem iPhone
im Browser ansehbar.

**Fängt:** Logikfehler, Layout-Brüche, Regressionen, Formatierungsfehler.
Grob die Hälfte aller Fehler, bevor irgendjemand etwas anfasst.

---

## Stufe 1 — Web-Build · bei jedem Push · rund vier Minuten · **der wichtigste Kanal**

`flutter build web` in der Action, Deploy zu **Cloudflare Pages**. Der Nutzer
öffnet die URL in Safari auf dem iPhone und bedient die App wirklich.

**Warum Cloudflare Pages und nicht GitHub Pages:** GitHub Pages verlangt für
private Repositories ein bezahltes Konto. Cloudflare Pages ist kostenlos, kommt
mit privaten Repos zurecht, hat kein Übertragungslimit und erzeugt für jeden
Branch eine eigene Vorschau-URL. Einrichtung ist vollständig vom Handy aus
möglich. Falls das Repo öffentlich sein darf, geht GitHub Pages genauso.

**Was hier vollständig testbar ist:**
- sämtliche Bildschirme, Navigation, Zustandsverwaltung
- das Segment-Datenmodell samt Erweitern bestehender Einträge
- die komplette Interpreter- und Auswertungslogik
- alle Exportformate inklusive PDF-Erzeugung
- Suche, Sortierung, Filter, Theming, Schriftgrößen
- die reservierte Bannerfläche und der Abstand zum Aufnahmeknopf

**Was nicht:** sherpa-onnx, ML Kit, native Kamera, Dateisystem, Werbung, Käufe.

Grob **zwei Drittel der tatsächlichen Arbeit.** Für die Stub-Implementierungen
gilt: `WebStubSttEngine` liefert hinterlegten Beispieltext mit einstellbarer
Verzögerung, damit auch Ladezustände und Fehlerfälle geprüft werden können —
nicht nur der Erfolgsfall.

**Manuelle Prüfliste je App**, vom Nutzer auf dem iPhone durchzugehen:
1. Neuen Eintrag anlegen, Stub-Transkript erscheint
2. Denselben Eintrag um ein zweites Segment erweitern, Reihenfolge stimmt
3. Interpreter-Ergebnis prüfen — Felder korrekt gefüllt
4. Eintrag suchen, finden, öffnen
5. Alle vier Exporte auslösen, Dateien öffnen sich und sind vollständig
6. Fluchttür-Export prüfen: enthält er wirklich alles?
7. Hell und dunkel umschalten, Schriftgröße hoch, nichts bricht
8. Auf schmalem Fenster: Bannerfläche kollidiert mit nichts

---

## Stufe 2 — Firebase Test Lab · bei jedem Merge · Gratis-Kontingent

Echte Android-Hardware in Googles Rechenzentrum, ohne ein Gerät zu besitzen.
Der Gratis-Tarif enthält ein tägliches Kontingent an Testläufen; das reicht bei
einem Merge pro Tag bequem. Die genaue Höhe des Kontingents vor Einrichtung
in der Firebase-Konsole prüfen, sie ändert sich gelegentlich.

**Robo-Test:** krabbelt selbständig durch die App und liefert Video,
Screenshots und Absturzprotokolle — alles im Browser auf dem iPhone ansehbar.
Fängt genau das, was der Web-Build nicht sieht: Berechtigungsdialoge,
Speicherprobleme, Abstürze in nativen Plugins, Verhalten bei Drehung.

**Integrationstests:** dieselben `integration_test`-Läufe wie in Stufe 0,
aber auf echten Geräten mit echtem Android.

Kein bezahltes Konto nötig — ein Firebase-Projekt auf dem Gratis-Tarif genügt.

---

## Stufe 3 — später, wenn Geld da ist

Nicht jetzt einrichten, aber in der CI bereits vorbereiten, damit später nur
ein Schalter fehlt:

| Kanal | Kosten | Was er zusätzlich bringt |
|---|---|---|
| TestFlight über Codemagic | 99 $/Jahr Apple | natives iOS auf dem eigenen iPhone, alle Plugins echt |
| Firebase App Distribution | 0 € | braucht ein Android-Gerät, sonst nutzlos |
| Gebrauchtes Android-Gerät | 60–120 € | Werbung, Kauf, Modellgröße, Mikrofonqualität |

**Reihenfolge, wenn Geld kommt:** zuerst 25 $ Play Console (schaltet
Veröffentlichung und den Zwölf-Tester-Lauf frei), dann das Android-Gerät,
zuletzt das Apple-Konto. Begründung: Android ist die Auslieferungsplattform,
iOS ist zunächst nur Testkanal — und für den Testkanal leisten die Stufen 0
bis 2 vorerst genug.

---

## Was diese Leiter nicht kann

Ehrlich benannt, damit später keine Überraschung entsteht:

- **Qualität der Parakeet-Erkennung** bei echten Aufnahmen, echten Mikrofonen,
  Hintergrundgeräuschen. Nur auf echter Hardware beurteilbar.
- **Ladezeit und Speicherverhalten** des 640-MB-Modells auf Mittelklassegeräten.
- **Verhalten von Werbung und Kaufabwicklung.** Nicht simulierbar, aber auch
  nicht nötig, solange kein Konto existiert.
- **Kamera-Pipeline unter realen Lichtverhältnissen.** Der Web-Stub prüft die
  Logik, nicht die Bildqualität.

Alles davon betrifft die letzten zwanzig Prozent vor der Veröffentlichung.
Die ersten achtzig sind mit den Stufen 0 bis 2 vollständig abgedeckt — und
genau die stehen jetzt an.

---

## Einmalige Einrichtung durch den Nutzer

Drei Dinge, alle vom Handy aus, alle kostenlos:

1. **GitHub-Repository** anlegen (privat), Claude Code damit verbinden.
2. **Cloudflare-Konto** anlegen, Pages-Projekt mit dem Repo verbinden,
   Build-Befehl und Ausgabeverzeichnis eintragen.
3. **Firebase-Projekt** auf dem Gratis-Tarif anlegen, Dienstkonto-Schlüssel
   erzeugen und als GitHub-Secret hinterlegen.

Danach läuft die gesamte Leiter automatisch bei jedem Push.
