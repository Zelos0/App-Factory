# KARTEI — Karten und Ausweise, geordnet

| | |
|---|---|
| Flavor | `kartei` |
| Kern | `lens` |
| Paket-ID | `de.zeta.kartei` |
| Store-Titel | KARTEI — Kundenkarten offline |
| Band | II |
| Umsetzungsstufe | 3 (Band II) |
| Preisklasse | Werkzeug |

## Zielgruppe

Alle mit vollem Portemonnaie: Kundenkarten, Mitgliedsausweise, Versicherungskarten, Visitenkarten.

## Der auslösende Moment

An der Kasse nach der Kundenkarte gefragt, die zu Hause liegt. Oder eine Visitenkarte, die in der Jackentasche verschwindet und nie in den Kontakten landet.

## App-spezifische Funktionen

- Karte an der Kasse in voller Helligkeit anzeigen, Barcode scanbar
- Vorder- und Rückseite je Karte
- **Sensible Karten hinter Biometriesperre**, einzeln wählbar
- Widget mit den drei meistgenutzten Karten
- Ablauferinnerung für Ausweise und Versicherungskarten
- Kein Konto, keine Synchronisation, keine Partnerangebote

## Pipeline — die zwanzig Prozent

- Barcode und QR-Code der Karte automatisch erfasst und wiedergabefähig
- Firmen- und Namenserkennung über Texterkennung
- Visitenkarten in Kontaktfelder zerlegt, direkt ins Adressbuch übernehmbar
- Ablaufdaten erkannt und als Erinnerung angelegt

## Export

PDF-Übersicht, ZIP der Bilder, VCF der Kontakte

## Risiko / Auflage

Keine Zahlungskarten und keine amtlichen Ausweise als Ersatzdokument bewerben. Ablage von Bildern, nicht Ersatz des Originals.

## Preisgestaltung

| Stufe | Preis |
|---|---|
| Grundversion | gratis + Banner |
| Werbefrei | 1,49 € |
| Pro — Einführung | 1,99 € |
| Pro — Zielpreis | 3,99 € |

## Konkurrenz

Karten-Sammel-Apps mit Konto, Cloud-Synchronisation und Werbung für Handelspartner. Der Vorbehalt vieler Nutzer betrifft genau diese Datenweitergabe.

## Gestaltung

| Rolle | Farbe |
|---|---|
| Violett | `#3B1470` |
| Lila-Weiß | `#FAF5FF` |
| Akzent | `#A78BFA` |
| Tiefe | `#1E1B4B` |

**Typografie.** Kartenname groß und kontrastreich — im Laden bei schlechtem Licht ablesbar.

**Leitmotiv.** Kartenfächer. Karten liegen leicht überlappend gestapelt und fächern beim Antippen auf.

**Startbildschirm.** Die Karten als aufgefächerter Stapel mit echten Bildern. Suchfeld oben. Ein Knopf zum Hinzufügen.

## Offen — von `konzept-zu-bauplan` zu klären

- Zwölf Beispielsätze für den Interpreter: vier normal, drei Engine-Fehler,
  zwei unvollständig, zwei Grenzfall, einer leer. Stehen in keinem Band.
- Feldschema für `Entry.data` — welche Schlüssel der Interpreter füllt.
- Welche der genannten Funktionen zur Gratisversion gehören und welche zur
  Pro-Stufe. Die Bände legen nur fest, dass Aufnehmen, Transkribieren,
  Suchen und Exportieren immer kostenlos bleiben.
