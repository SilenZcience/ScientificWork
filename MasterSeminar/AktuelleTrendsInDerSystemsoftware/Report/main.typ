#import "faithful-acmart/src/lib.typ": *

#set text(lang: "de")

#show: acmart.with(
  format: "sigconf",
  title: [Erkennung von Memory-Safety-Bugs in Rust: Eine Evaluation am Beispiel von RUDRA],
  language: "german",

  authors: (
    (
      name: "Silas A. Kraume",
      email: "Silas.Kraume@hhu.de",
      affiliation: (
        institution: "Heinrich-Heine-Universität",
        city: "Düsseldorf",
        state: "Nordrhein-Westfalen",
        country: "Deutschland",
      ),
    ),
    (
      name: "Léon Lehnen",
      email: "Leon.Lehnen@hhu.de",
      affiliation: (
        institution: "Heinrich-Heine-Universität",
        city: "Düsseldorf",
        state: "Nordrhein-Westfalen",
        country: "Deutschland",
      ),
    ),
  ),

  conference: (
    name: "Master-Seminar",
    venue: "Aktuelle Trends in der Systemsoftware",
  ),

  copyright: "none",
  copyright-year: "SoSe 2026",
  doi: none,

  print-acm-reference: false,
  isbn: none,

  abstract: [
    Rust garantiert Speichersicherheit zur Compilezeit, insofern nicht über das #emph[unsafe]-Keyword eben jene Sicherheitsprüfungen deaktiviert werden.
    Das statische Analysewerkzeug RUDRA @rudra_paper schließt diese Lücke, indem es als Compiler-Erweiterung direkt auf den internen Zwischendarstellungen des Rust-Compilers arbeitet und drei Klassen von Safety-Bugs erkennt: Panic-Safety-Verletzungen, gebrochene Higher-order-Invarianten sowie fehlerhafte Send/Sync-Implementierungen.
    Diese Arbeit dokumentiert die vollständige Reproduktion der im RUDRA-Paper beschriebenen Evaluationen anhand des veröffentlichten Artefakts.
    Dabei lassen sich die Originalergebnisse nahezu exakt nachvollziehen: Die gezielte Bug-Reproduktion weicht je nach Schweregrad um höchstens zwei Funde ab, die Analyse der Rust-Standardbibliothek bestätigt alle behaupteten Sicherheitslücken, inklusive mehrerer CVEs, mit 168 Befunden, und die Kampagne über das gesamte crates.io-Ökosystem von 42.625 Paketen liefert bis auf 48 inzwischen nicht mehr kompilierbare Crates identische Zahlen.
    Die größte Herausforderung ist dabei weniger die Analysetechnik als das Altern der Umgebung. Eine nicht mehr gepflegte Rust-Toolchain aus dem Jahr 2020, archivierte Basisimages und nicht vorhandene Lockfiles erfordern zahlreiche Eingriffe in die bereitgestellten Skripte.
    RUDRA wurde inzwischen archiviert, jedoch leben dessen Ideen im offiziellen Rust-Linter Clippy fort.
    Abschließend ordnet die Arbeit die Ergebnisse in den Kontext aktueller Forschung ein und zeigt mittels Vergleich eines großen Sprachmodells sowohl das Potenzial als auch die Grenzen KI-gestützter Codeanalyse.
  ],
)

#include "sections/introduction.typ"
#include "sections/rudra.typ"
#include "sections/results.typ"
#include "sections/outlook.typ"
#include "sections/conclusion.typ"

#include "sections/repository.typ"
#include "sections/group-distribution.typ"

#bibliography("refs.bib")
