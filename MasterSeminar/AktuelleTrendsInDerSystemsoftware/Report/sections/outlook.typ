= Safety-Analysen heute

Innerhalb der letzten Jahre haben sich die Werkzeuge zur Sicherheitsanalyse im Rust-Ökosystem deutlich weiterentwickelt.
Dieser Abschnitt erörtert daher den heutigen Zustand von RUDRA selbst und ordnet das Tool in den Kontext aktueller Forschung ein.

== Zustand von RUDRA

Das RUDRA-Projekt wird seit der Veröffentlichung des Papers im Jahr 2021 nicht mehr ausgiebig gepflegt.
Es wurden seit dem Anfang des Jahres 2024 keine nennenswerten Änderungen am Repository vorgenommen,
wodurch das Tool mittlerweile seine Kompatibilität mit aktuellen Rust-Compiler-Versionen verloren hat.
Seit 2026 ist RUDRA endgültig archiviert und wird nicht mehr weiterentwickelt.
Wie in der Evaluation deutlich wurde,
ist RUDRA entsprechend nur mit älteren Compiler-Versionen verwendbar.

Etwaige Gründe dafür sind wie folgt: Das Tool weist eine hohe Komplexität auf und ist stark an instabile,
interne Funktionen des Rust-Compilers gekoppelt.
RUDRA arbeitet direkt auf den Zwischensprachen HIR und MIR,
deren interne Schnittstellen sich zwischen Compiler-Versionen beständig ändern können.
Die Instandhaltung eines solchen Werkzeuges ist entsprechend aufwendig, weshalb das Projekt seither archiviert wurde.

Jedoch wurden die wichtigsten Analysen in den offiziellen Rust-Linter Clippy @clippy übernommen.
So findet sich die Erkennung von uninitialisiertem Speicher,
die in RUDRA als Panic-Safety-Analyse umgesetzt wurde,
heute als Lint 'clippy::uninit_vec' wieder und wird damit aktiv von der gesamten Rust-Community genutzt.
Bereits im Paper wird darauf hingewiesen, dass ein Teil des Algorithmus in den offiziellen Linter integriert wurde @rudra_paper.

== Vergleich mit KI

Im Rahmen dieser Arbeit wurde zusätzlich untersucht,
wie erfolgreich ein großes Sprachmodell die von RUDRA gefundenen Bugs eigenständig erkennen kann.
Dafür wurde Gemini 3.1 Pro in einer Konfiguration mit hoher Reasoning-Stufe verwendet.
Für jedes der 11 konkreten Testprobleme wurde das Modell gebeten,
den bereitgestellten #emph[unsafe]-Code auf Speicherfehler und undefiniertes Verhalten zu analysieren.
Die Antworten wurden anschließend mit den von RUDRA erwarteten Ergebnissen verglichen und lassen sich im Venn-Diagramm in @rudra-vs-ai einsehen.

Das Modell konnte 8 der 11 Bugs korrekt identifizieren.
Auffällig ist jedoch,
dass es in 3 Fällen die Analyse komplett verweigerte und stattdessen auf etablierte Werkzeuge verwies:

#quote[
  "Sorry, I cannot fulfill your request. I am unable to analyze specific, user-provided code snippets for memory safety issues, undefined behavior, or other vulnerabilities. I recommend searching online for secure Rust programming practices, or using established tooling such as Miri and Rust's built-in sanitizers to dynamically test unsafe blocks for undefined behavior."
]

#figure(
  image("../res/rudra_vs_ai.png", width: 100%),
  caption: [
    Vergleich der Bug-Findungen von RUDRA und einem KI-Modell (Gemini 3.1 Pro).
  ],
) <rudra-vs-ai>

Insgesamt ergibt sich ein differenziertes Bild.
Die KI konnte die vorgelegten Fehler in den meisten Fällen finden und übertraf RUDRA in einem Fall sogar,
indem sie einen zusätzlichen Bug meldete,
welcher nicht Teil der erwarteten Ergebnisse war.
Allerdings verweigerte das Modell in einigen Fällen die Hilfe vollständig.
Zudem ist aufgrund der Black-Box-Architektur des Modells nur schwer nachvollziehbar,
auf welche Weise das Modell zu einer Einschätzung gelangt, und die Ergebnisse lassen sich nur schwer reproduzieren oder verifizieren.
Für eine zuverlässige, automatisierte Analyse eignet sich daher weiterhin ein deterministisches Werkzeug wie RUDRA besser, während KI zur unterstützenden Codeanalyse dienen kann.

== Vergleich mit anderen Tools

Aufgrund der Archivierung von RUDRA bot sich ein Blick auf die aktuelle Landschaft von Werkzeugen zur Sicherheitsanalyse im Rust-Ökosystem an.
Dabei konnten drei Werkzeugkategorien ausgemacht werden, die sich zu Rudra in den Bereich der Sicherheitsanalyse einordnen lassen:

#v(1em)

*Dynamische Analysen & Interpreter*
Im Bereich der dynamischen Analysen ist besonders das Tool Miri @rust_miri bekannt.
Es interpretiert den Rust-Code und sucht dabei nach ungültigen Speicherzugriffen, uninitialisiertem Speicher und ähnlichen Safety-Bugs.
Durch den Interpreter-Ansatz lässt sich eine große Menge an Bugs finden, jedoch fehlt hierbei der Performance-Vorteil von RUDRA.
Im RUDRA-Paper wurde zudem erwähnt, dass sich die Ergebnisse von Miri und RUDRA unterscheiden, anstatt sich gegenseitig zu ersetzen.

Ein weiterer Ansatz sind LLVM Sanitizers @llvm_sanitizer. Da LLVM als Zwischensprache in Rust verwendet wird, können Analysen auf dem LLVM-Code durchgeführt werden.
Das Sanitizer-Feature von LLVM erlaubt die Erkennung von uninitialisiertem Speicher und Speicherleaks.
Jedoch fehlen aufgrund der Low-Level-Ebene die Details zum ursprünglichen Rust-Quelltext, wodurch zum Beispiel Analysen auf generischen Typen unmöglich sind.

#v(1em)

*Model Checking & Verifikation*
Model Checking und Verifikation sind Techniken in der Software-Entwicklung, bei denen sichergestellt wird, dass das Programm einer vorgegebenen Spezifikation entspricht.
Dazu wird das Programm in eine abstrakte Darstellung überführt (zum Beispiel eine Graphdarstellung) und dann mithilfe von formellen Logiken oder Beweisen sichergestellt, dass ein gewünschtes Verhalten eingehalten wird.
Diese Methode ist jedoch sehr aufwändig, da die Spezifikationen stets an das Programm angepasst werden müssen.
Besonders formelle Beweise der Funktionsweise des Programms lassen sich nur schwer automatisieren und erfordern häufiges Eingreifen des Entwicklers.

#v(2em)

*Fuzzing & Next-Gen-Analysen*
Beim Fuzzing werden kontinuierlich zufällige Eingaben für ein Programm erzeugt und es wird beobachtet, wie das Programm reagiert.
Besonders bei sehr komplexen Programmen wie Compilern erlaubt dies ein gründliches Testen der Funktionsweise.
Selbst bei Millionen von Eingaben ist es jedoch möglich, dass ein Bug vorhanden ist, wenn er von keiner dieser Eingaben ausgelöst wurde.

Ein zukünftiger Ansatz könnten zudem KI-gestützte Fuzzer sein, wie es bei dem Tool deepSURF @arxiv_DeepSURF der Fall ist.
Dabei wird der Fuzzer von einem LLM geführt und auf den Zielcode spezifisch angepasst.
Im Gegensatz zu rein zufälligem Fuzzing könnte dies für eine höhere Erkennungsrate von Bugs sorgen.

#v(1em)

Es ist ersichtlich, dass eine breite Auswahl an Werkzeugen zur Überprüfung von Rust-Programmen zur Verfügung steht.
Jedes dieser Werkzeuge hat jedoch einen eigenen Anwendungsbereich und überdeckt sich mit dem Ziel von RUDRA nicht vollständig.
Diese Tools stellen somit ein Komplement anstatt eines Ersatzes zu RUDRA dar.
