# Steckbriefe — die 26 Apps

Quelle: „Voice-First App-Portfolio" (Band I, elf Apps auf `capture_core`) und
„App-Portfolio Band II" (fünfzehn Apps: fünf weitere auf `capture_core`, acht
auf `lens_core`, zwei auf beiden). Stand beider Bände: August 2026.

Diese Dateien sind die **Eingabe für `konzept-zu-bauplan`**. Der Skill liest
einen Steckbrief und erzeugt daraus `docs/baupläne/<flavor>.md`; erst dieser
Bauplan ist die Eingabe für `app-derive`.

Ein Steckbrief enthält, was in den Bänden steht — nicht mehr. Wo ein Band
etwas offenlässt, bleibt es offen; `konzept-zu-bauplan` fragt danach, statt
zu raten. Insbesondere die zwölf Beispielsätze je Interpreter (Pflicht nach
`konzept-zu-bauplan` Schritt 8) stehen in keinem Band und entstehen erst dort.

## Reihenfolge der Umsetzung

Die Bände legen zwei Reihenfolgen fest, eine je Kern. `vox` steht zuerst,
weil daraus alles Übrige entsteht.

| Stufe | Apps | Begründung aus den Bänden |
|---|---|---|
| 1 | vox | enthält den vollständigen Sprach-Kern |
| 2 | onira, kassa, ritus | Consumer-Volumen, breite Suchbegriffe, schneller Rezensionsaufbau |
| 3 | fahrtlog, anamnese | höhere Preisklasse, engere Zielgruppe |
| 4 | werkbuch | höchster Deckungsbeitrag, kleinster Markt |
| 5 | lingua, terra, nido | Nischen mit starker Bindung |
| 6 | akut | kein Umsatz, sondern Reichweite — wirkt erst mit anderen Apps |

Band II setzt für den Kamera-Kern eigene Prioritäten: zuerst `prisma` und
`folio` (größtes Suchvolumen, schwächste Konkurrenz, sie bauen `lens_core`),
dann `uebergabe` und `archiv` (höchster Einzelnutzen), danach `litera`,
`tolk`, `kartei`, `palette` als günstige Ableitungen. `schwaerze` und
`signum` brauchen die ausgereifte PDF-Schicht und kommen später. `garage`,
`stunde`, `herd`, `inventar` sind jederzeit einschiebbar. `hantel` zuletzt
oder gar nicht — einziger Markt mit funktional überlegener Konkurrenz.

## Namen

Flavor-Namen folgen ARCHITEKTUR.md Abschnitt 9: Kleinbuchstaben, ASCII, keine
Umlaute. Zwei Namen weichen deshalb von der Schreibweise der Bände ab:

| Band | Flavor | Paket-ID |
|---|---|---|
| ÜBERGABE | `uebergabe` | `de.zeta.uebergabe` |
| SCHWÄRZE | `schwaerze` | `de.zeta.schwaerze` |

## Übersicht

| Flavor | Kern | Thema | Launch | Ziel | Band |
|---|---|---|---|---|---|
| vox | capture | Sprachnotizen ohne Umwege | 2,49 € | 4,99 € | I |
| onira | capture | Träume festhalten, bevor sie verblassen | 2,49 € | 4,99 € | I |
| kassa | capture | Ausgaben ansagen statt eintippen | 2,49 € | 4,99 € | I |
| ritus | capture | Gewohnheiten und Medikamente per Zuruf | 2,49 € | 4,99 € | I |
| fahrtlog | capture | Fahrten ansagen, während man fährt | 4,99 € | 9,99 € | I |
| werkbuch | capture | Baustellendokumentation mit Handschuhen | 9,99 € | 19,99 € | I |
| anamnese | capture | Was man dem Arzt sagen wollte | 4,99 € | 9,99 € | I |
| nido | capture | Das erste Jahr mit einer freien Hand | 2,49 € | 4,99 € | I |
| lingua | capture | Sprechen, sehen, korrigieren | 2,49 € | 4,99 € | I |
| terra | capture | Aufzeichnen, wo kein Netz ist | 2,49 € | 4,99 € | I |
| akut | capture | Der Vertrauensanker | gratis | gratis | I |
| garage | capture | Werkstattbuch fürs eigene Fahrzeug | 2,49 € | 4,99 € | II |
| uebergabe | capture | Die Kaution retten | 4,99 € | 9,99 € | II |
| stunde | capture | Zeiterfassung im Vorbeigehen | 4,99 € | 9,99 € | II |
| hantel | capture | Zwischen den Sätzen ansagen | 2,49 € | 4,99 € | II |
| herd | capture | Rezepte, wie sie erzählt werden | 2,49 € | 4,99 € | II |
| prisma | lens | Scannen ohne Gegenleistung | 1,99 € | 2,99 € | II |
| folio | lens | Dokumente scannen, ohne zu zahlen | 2,49 € | 4,99 € | II |
| litera | lens | Text aus allem herausholen | 1,99 € | 3,99 € | II |
| tolk | lens | Übersetzen ohne Netz | 1,99 € | 3,99 € | II |
| schwaerze | lens | Weggeben, ohne alles preiszugeben | 2,99 € | 5,99 € | II |
| signum | lens | Ausfüllen und unterschreiben, ohne Drucker | 2,99 € | 5,99 € | II |
| kartei | lens | Karten und Ausweise, geordnet | 1,99 € | 3,99 € | II |
| palette | lens | Farben aus der Welt holen | 1,99 € | 3,99 € | II |
| inventar | both | Hausrat, bevor etwas passiert | 4,99 € | 9,99 € | II |
| archiv | both | Papier, das sich selbst meldet | 4,99 € | 9,99 € | II |

Sechzehn Apps auf `capture_core`, acht auf `lens_core`, zwei auf beiden.

## Preisarchitektur

Aus Band I, gilt für beide Bände. Der Zielpreis wird erst nach Aufbau von
Sozialbeweis gezogen, nicht zum Start.

| Klasse | Apps | Werbefrei | Pro Launch | Pro Ziel | Auslöser für die Erhöhung |
|---|---|---|---|---|---|
| Consumer | vox, onira, kassa, ritus, lingua, terra, nido | 1,49 € | 2,49 € | 4,99 € | 300 Rezensionen bei 4,5+ |
| Semi-Pro | fahrtlog, anamnese | 1,99 € | 4,99 € | 9,99 € | 150 Rezensionen bei 4,5+ |
| Beruflich | werkbuch | — | 9,99 € | 19,99 € | 80 Rezensionen bei 4,5+ |
| Vertrauensanker | akut | dauerhaft gratis | — | — | kein Kauf vorgesehen |

Ausdrücklich nicht: kein Abo, keine Interstitials, keine Rewarded Videos,
keine Funktionssperre im Kern. Aufnehmen, transkribieren, suchen und
exportieren funktionieren in der Gratisversion vollständig — bezahlt wird für
Qualität, nicht für Zugang.

## Apps mit Auflagen

Neun Steckbriefe tragen einen Abschnitt „Risiko / Auflage". Diese Auflagen
sind bindend und gehören in den Bauplan, nicht in die Store-Beschreibung
allein:

| Flavor | Auflage in einem Satz |
|---|---|
| onira | Abgrenzung zur vorhandenen Konkurrenz in den ersten beiden Screenshots |
| ritus | keine Wirkungsaussagen, keine Dosierungsempfehlungen |
| fahrtlog | als Fahrtenprotokoll vermarkten, nicht als finanzamtskonformes Fahrtenbuch |
| anamnese | keine Diagnose, keine Behandlungsempfehlung, Lokalspeicherung benennen |
| akut | wird nie verkauft und trägt keine Werbung |
| hantel | realistische Erwartung: solide Mitte statt Durchbruch |
| uebergabe | Dokumentationshilfe, nicht Rechtsdokument |
| tolk | Positionierung nur über Netzunabhängigkeit, nicht über Qualität |
| schwaerze | technische Entfernung zusichern, keine Rechtssicherheit |
| signum | keine Aussagen zu qualifizierten elektronischen Signaturen |
| kartei | Ablage von Bildern, kein Ersatz des Originals |
| inventar | keine Aussagen zur Deckung oder Regulierungspraxis |
| archiv | erkannte Frist ist ein Vorschlag, keine Rechtsauskunft |
