= Einführung

Diese Ausarbeitung befasst sich mit dem Analysewerkzeug "RUDRA" für Rust @rudra_paper.
Um die Funktionsweise und Evaluation nachvollziehbar zu machen, bietet dieser Abschnitt eine Einführung in die Thematik und stellt die Problemstellung sowie relevante Hintergründe dar.

== Speichersicherheit in Rust

Die Programmiersprache Rust @rustlang legt großen Wert auf Speichersicherheit sowie die Vermeidung von undefiniertem Verhalten während der Entwicklung.
Hierfür nutzt der Rust-Compiler verschiedenste Analysetechniken und Programmiereinschränkungen, um Sicherheitsgarantien bereits zur Compilezeit zu gewährleisten.

Insbesondere der Borrow-Checker ist ein zentrales Werkzeug des Compilers,
das viele Operationen verhindert, die in anderen Sprachen wie C und C++ üblich sind.
Darunter fällt zum Beispiel die Durchsetzung der Regel #emph[Aliasing XOR Mutability], welche verhindert,
dass zwei oder mehr veränderbare ("mutable") Referenzen auf dieselbe Variable existieren. Zu jedem Zeitpunkt darf höchstens eine schreibbare Referenz existieren, um undefiniertes Verhalten durch Race Conditions zu vermeiden @rust_borrowing.

Neben dem Borrow-Checker bietet Rust zahlreiche weitere Sprachkonzepte und statische Analysen, die zur Speichersicherheit beitragen.
Dazu zählen unter anderem ein striktes Typsystem, Null-Safety, sichere Nebenläufigkeit sowie die garantierte Initialisierung von Variablen.

== Unsafe Code

Es gibt Fälle, in denen die Einschränkungen des Rust-Compilers zur Gewährleistung der Speichersicherheit zu restriktiv sind.
Dies kann unter anderem auftreten, wenn mit low-level Schnittstellen gearbeitet wird, bei denen direkte Speicherzugriffe unabdingbar sind.
Da der Rust-Compiler nicht in der Lage ist,
diese Zugriffe über die Hardwaregrenze hinaus statisch zu verifizieren,
lehnt er sie ab, selbst wenn sie zur Laufzeit sicher wären.

Auch bei der Optimierung leistungskritischer Algorithmen kann es erforderlich sein,
bestimmte Compiler-Garantien zu umgehen.
Lässt sich beispielsweise anderweitig sicherstellen, dass auf eine geteilte Referenz niemals nebenläufig geschrieben wird,
kann der Overhead von Synchronisierungsprimitiven (wie einem Mutex) eingespart werden.

Aus diesem Grund bietet Rust die Möglichkeit,
Sicherheitsüberprüfungen in gezielten Abschnitten manuell zu handhaben: über das Keyword #emph[unsafe].
Wird ein Codeblock, eine Funktion, ein Trait oder eine Implementierung mit #emph[unsafe] markiert,
erlaubt der Compiler potenziell unsichere Operationen (wie das Dereferenzieren von Rohzeigern). Die Verantwortung für die Einhaltung der Sicherheitsinvarianten wird damit auf den Entwickler übertragen.
Dieser muss die Korrektheit des Codes manuell sicherstellen und die Sicherheitsannahmen dokumentieren.
Insbesondere in der Rust-Standardbibliothek sind solche #emph[Safety]-Kommentare vorgeschrieben @std_dev_guide_safety.

// TODO: Code-Beispiel?
// TODO: Graph über Verwendung von unsafe

== Entstehung von Safety-Bugs

Selbst bei genauem Auditing von #emph[unsafe]-Code durch Experten können Fehler nicht vollständig ausgeschlossen werden.
Sicherheitsfehler sind meistens nicht offensichtlich,
sondern entstehen über Umwege im Datenfluss.
Das Paper zu RUDRA versucht daher, die möglichen Ursachen von Safety-Bugs zu erörtern und formal darzustellen.
Die genauen Formalismen sind für diese Arbeit jedoch nicht weiter relevant,
weshalb an dieser Stelle auf das ursprüngliche Paper verwiesen wird.

// TODO: Teilweise doppelt
RUDRA analysiert drei zentrale Kategorien von Safety-Bugs, die typischerweise durch falsche Annahmen über Aufrufer-Code, temporär inkonsistente Zustände oder fehlerhafte Trait-Einschränkungen entstehen:

#v(1em)

*Panic Safety.*
Tritt in Rust ein #emph[Panic] auf, wird der Call-Stack abgewickelt und Destruktoren geben den Speicher frei.
Befindet sich eine Datenstruktur währenddessen in einem temporär inkonsistenten Zwischenzustand (z. B. durch uninitialisierten Speicher), laufen diese Aufräumoperationen blind weiter.
Dies führt zu Speichersicherheitsverletzungen wie Double-Frees oder der Dereferenzierung uninitialisierten Speichers.

#v(1em)

*Higher-Order Safety Invariants.*
Dieser Fehlertyp tritt auf, wenn generische Funktionen fälschlicherweise davon ausgehen, dass sich vom Aufrufer übergebener Code (z. B. Closures oder Trait-Methoden) stets korrekt verhält.
Sind die Traits bzw. Typen unzureichend eingeschränkt, kann unvorhergesehenes Verhalten der übergebenen Funktion die internen Sicherheitsannahmen brechen und zu inkonsistenten Zuständen führen.

#v(1em)

*Send/Sync Variance.*
Ein Send/Sync-Variance-Bug resultiert aus unzureichend eingeschränkten generischen Parametern bei der manuellen Implementierung der Traits #emph[Send] und #emph[Sync].
Wird ein Typ fälschlicherweise als threadsicher deklariert, obwohl seine inneren Werte dies nicht sind, bricht die Thread-Sicherheitsgarantie von Rust und ermöglicht Data Races zur Laufzeit.
