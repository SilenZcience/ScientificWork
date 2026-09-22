= Das Tool RUDRA

RUDRA ist ein statisches Analysewerkzeug, das darauf abzielt,
die zuvor beschriebenen Fehler in Rust-Programmen zu erkennen.

== Design

Einer der Hauptaspekte von RUDRA ist es,
automatisch auf beliebigen Rust-Programmen ausgeführt werden zu können,
ohne vorheriges Eingreifen und Konfigurieren seitens des Nutzers zu erfordern.
Dies ist besonders wichtig, um große Mengen an Programmen ohne manuellen Aufwand zu analysieren.
Aus diesem Grund gab es verschiedene Anforderungen an das Design des Tools:

#v(1em)

*Unterstützung für generische Typen.*
RUDRA muss generische Typen analysieren können,
ohne deren konkrete Instanziierung zu kennen.
Dafür kombiniert das System die internen Compiler-Zwischensprachen (HIR #footnote[High-Level Intermediate Representation] <HIR> und MIR #footnote[Mid-Level Intermediate Representation] <MIR>) @rudra_paper, anstatt auf Low-Level-Repräsentationen (LLVM #footnote[Low Level Virtual Machine] <LLVM>) zurückzugreifen.

#v(1em)

*Skalierbarkeit.*
Das Ziel besteht in der Überprüfung aller Pakete in der Rust-Paket-Registry,
was eine Balance zwischen Analysegenauigkeit und Ausführungszeit erfordert.
Das System agiert vollautomatisch und erfordert keinerlei Annotationen oder Eingriffe durch Paketentwickler.

#v(1em)

*Anpassbare Präzision.*
Da False Positives bei schnellen Analysen nicht auszuschließen sind,
erlaubt RUDRA die direkte Steuerung der Präzision.
Je nach Präzisionsstufe (Low, Medium, High) werden bestimmte Analysen übersprungen oder gelockert.

== Funktionsweise von RUDRA

Um die Designziele umzusetzen, wurde RUDRA als Compiler-Erweiterung entwickelt und hat somit Zugriff auf die internen Datenstrukturen und Code-Repräsentationen zur Kompilierzeit.
Der Ablauf erfolgt in zwei Schritten:

+ *Sammeln von Informationen.* Zuerst werden relevante Informationen über das Zielprogramm gesammelt. Dabei wird die HIR @HIR verwendet, da zu diesem Zeitpunkt noch die ursprüngliche Code-Struktur und Positionen von #emph[`unsafe`]-Blöcken bekannt sind.

+ *Durchführung der Analysealgorithmen.* Im zweiten Schritt werden die Analysealgorithmen auf der MIR @MIR durchgeführt. Die MIR ist weitaus abstrakter und eignet sich daher besser für effiziente Analysen. Da in diesem Schritt detaillierte Informationen über die Code-Struktur bereits verworfen wurden, wird auf die zuvor gesammelten Informationen zurückgegriffen.

Auf diese Weise kann RUDRA parallel zum Rust-Compiler arbeiten und Analysen effizient durchführen.
Aufgrund der Arbeit auf dieser Abstraktionsebene kann RUDRA jedes kompilierbare Programm analysieren, unabhängig von dessen Umfang und Struktur.

== Implementierung

Die Implementierung von RUDRA basiert zum Zeitpunkt des Papers auf der Rust-Compiler-Version #emph[`rustc-nightly-2020-08-26`] und umfasst ca. 4.300 Zeilen Code.
Es werden zwei Binaries bereitgestellt: #emph[`rudra`] als eigenständiges Analysewerkzeug und #emph[`cargo-rudra`] als Cargo-Integration, die es ermöglicht, das Tool in den normalen Build-Prozess einzubetten.
Der vollständige Quelltext befindet sich auf GitHub#footnote[#link("https://github.com/sslab-gatech/Rudra")] und ist dort öffentlich zugänglich.

Durch die Kommandozeilenargumente #emph[`-Zrudra-enable-*`] und #emph[`-Zrudra-disable-*`] lassen sich die drei Analysemodule ('unsafe-destructor', 'send-sync-variance', 'unsafe-dataflow') individuell aktivieren oder deaktivieren.
Für die Präzisionssteuerung stehen die Stufen #emph[`-Zsensitivity-high`] (nur #emph[`Error`]), #emph[`-Zsensitivity-med`] (#emph[`Error`] und #emph[`Warning`]) sowie #emph[`-Zsensitivity-low`] (alle Befunde) zur Verfügung.
Im Standardmodus sind die #emph[`SendSyncVariance`]- und #emph[`UnsafeDataflow`]-Analysen aktiviert, während #emph[`UnsafeDestructor`] deaktiviert ist.
Das Tool lässt sich mithilfe von Docker @docker_website ausführen und erlaubt die Analyse beliebiger Zielpakete.
Dabei wird das Zielpaket ohne Abhängigkeiten analysiert, um eine redundante Analyse derselben Abhängigkeiten bei einer großen Menge von Paketen zu vermeiden.

#pagebreak()
