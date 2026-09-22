#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#show raw.where(block: true): it => block(breakable: false, it)
#codly(
  fill: luma(247),
  zebra-fill: none,
  stroke: 0.5pt + luma(170),
  radius: 1pt,
)

= Ergebnisse

Das RUDRA-Paper umfasst drei Evaluationen unterschiedlichen Umfangs,
deren Reproduktion im Folgenden beschrieben wird:

+ die Reproduktion der im Paper veröffentlichten Ergebnisse,
+ die Analyse der kompletten Rust-Standardbibliothek sowie
+ die Analyse des gesamten crates.io-Ökosystems.

Zunächst werden die nötigen Anpassungen an dem von den Autoren bereitgestellten Artefakt beschrieben.
Anschließend werden die drei Evaluationen einzeln vorgestellt und ihre Ergebnisse mit denen des Papers verglichen.
Die dazu verwendeten Datenanalyse-Skripte und Diagramme befinden sich im Verzeichnis 'evaluation' des begleitenden Repositories.

== Setup

Das Artefakt wird in mehreren Docker-Images bereitgestellt,
welche eine reproduzierbare Ausführungsumgebung für alle drei Evaluationen darstellen.
Die dazugehörige Rust-Toolchain stammt aus dem Jahr 2020 (`nightly-2020-08-26`) und wird inzwischen nicht mehr gepflegt.

Die veraltete Toolchain und die inzwischen archivierten Basisimages erschwerten die Reproduktion der Ergebnisse erheblich und machten eine Reihe von Anpassungen an den ursprünglichen Skripten und Dockerfiles erforderlich:

- *Versionskonflikte:* Bei der Auflösung der (transitiven) Abhängigkeiten lud Cargo standardmäßig aktuelle Versionen herunter, welche mit dem Compiler aus dem Jahr 2020 nicht mehr kompilierbar sind. Die benötigten älteren Versionen mussten daher manuell im Lockfile angepinnt werden.
- *Archiviertes Basisimage:* Das Debian-Basisimage ist veraltet und wurde inzwischen archiviert. Die Paketquellen mussten auf #emph[archive.debian.org] umgestellt und die Gültigkeitsprüfung der Release-Dateien deaktiviert werden.

Die Installations-Skripte und Dockerfiles wurden entsprechend angepasst. Den Fix für das archivierte Debian-Basisimage zeigt folgender Ausschnitt des modifizierten Dockerfiles:

#codly(
  languages: (
    bash: (name: "Dockerfile", color: rgb("#008cdb")),
  ),
  skips: ((1, 6),),
)
#text(7pt)[
  ```bash
  RUN sed -i \
      -e 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' \
      -e 's|http://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' \
      /etc/apt/sources.list && \
      echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until
  ```
]

Der abschließende Usability-Test verlief erfolgreich und die Umgebung ließ sich entsprechend reproduzierbar aufbauen.

== Reproduktion der Ergebnisse aus dem Paper

Die erste Evaluation verifiziert die zentralen Ergebniszahlen des Papers.
Das Artefakt enthält für alle von RUDRA gefundenen Bugs jeweils das betroffene Crate sowie einen Eintrag mit der erwarteten Analysekategorie und dem Schweregrad des Bugs.
Das Skript #emph[recreate_bugs.py] lädt für jeden dieser Einträge das Crate in einer festgepinnten Version herunter,
lässt es von RUDRA analysieren und zählt abschließend die erkannten Bugs getrennt nach Analyseverfahren (#emph[SendSyncVariance], #emph[UnsafeDataflow]),
Schweregrad und Sichtbarkeit.
Dabei definieren *visible* Bugs solche, die in der durch das Ziel-Crate bereitgestellten öffentlichen Schnittstelle existieren, wohingegen *internal* Bugs ausschließlich innerhalb des jeweiligen Crates ausgelöst werden können.

Die Logs aus dem Paper konnten mithilfe des bereitgestellten Skripts entsprechend schnell reproduziert werden.
Als Hindernis stellte sich lediglich das veraltete Werkzeug #emph[cargo download] heraus,
welches zum Herunterladen der Crates verwendet wurde und aufgrund von Versionsinkompatibilitäten inzwischen nicht mehr mit der Rust-Toolchain von 2020 funktioniert.
Es wurde durch eine eigene, auf der crates.io-API basierende Download-Routine in Python ersetzt:

#codly(
  languages: (
    python: (name: "Python", color: rgb("#356c99")),
  ),
)
#text(7pt)[
  ```python
  def cargo_download(crate_name, crate_version, out_dir):
      url = f"https://crates.io/api/v1/crates/{crate_name}/{crate_version}/download"

      response = urllib.request.urlopen(url)
      data = response.read()

      out_dir = Path(out_dir)
      out_dir.mkdir(parents=True, exist_ok=True)

      with tarfile.open(fileobj=io.BytesIO(data), mode="r:gz") as tar:
          tar.extractall(path=out_dir)

      members = [m for m in out_dir.iterdir() if m.is_dir()]

      for d in members:
          if (d / "Cargo.toml").exists():
              if d != out_dir:
                  for item in d.iterdir():
                      shutil.move(str(item), str(out_dir))
                  d.rmdir()
              break
  ```
]

#figure(
  image("../res/bug_reproduction.png", width: 100%),
  caption: [
    Reproduktion der Bugs aus dem Paper getrennt nach Analyseverfahren, Schweregrad und Sichtbarkeit.
  ],
) <reproduction>

Die erhaltenen Zahlenwerte sind nahezu identisch mit den Ergebnissen,
die RUDRA im Jahr 2021 erzielte, und werden in @reproduction detailliert gegenübergestellt.
Für #emph[SendSyncVariance] wurden in unserer Ausführung je nach Schweregrad 177, 277 beziehungsweise 306 Bugs reproduziert (Jahr 2021: 178, 279, 308).
Für #emph[UnsafeDataflow] waren es 73, 136 und 194 (Jahr 2021: 73, 136, 194).
Die Abweichung beträgt somit in keiner Kategorie mehr als zwei Bugs und ist insgesamt auf Crates zurückzuführen,
deren Build-Skripte veraltete URLs referenzieren und aufgrund dessen mittlerweile nicht mehr kompilierbar sind.

Zusätzlich wurde der Behebungsstatus aller 165 Bugs untersucht,
für die Bugreports erstellt wurden.
Diesbezüglich wurde jeder Bug gegen die RustSec-Advisory-Datenbank sowie dem jeweiligen Issue-Tracker abgeglichen.
Von den 165 Bugs wurden inzwischen 98 (59,4 %) behoben, 67 (40,6 %) sind jedoch weiterhin offen.

// TODO: median etc

// #figure(
//   image("../../evaluation/bug_fix_status.png", width: 100%),
//   caption: [
//     Behebungsstatus und Behebungszeit der 165 im Paper gemeldeten Bugs.
//   ],
// ) // Fuck this awful img

== Analyse der Rust-Standardbibliothek

Die zweite Evaluation analysiert die gesamte Rust-Standardbibliothek.
Da der Rust-Compiler intern eine Bibliothek für Datenparallelität (#emph[rayon] @rayon) verwendet,
wurde zudem eine alte Version der Crate #emph[rustc-rayon] in die Analyse aufgenommen.
Damit werden sowohl die Kern-Crates #emph[core], #emph[alloc] und #emph[std] als auch die experimentelle #emph[rayon]-Variante abgedeckt.

Auch hier bereiteten die veraltete Toolchain und die fehlende Wartung konkrete Schwierigkeiten.
Da für die Analyse bei dieser Evaluation kein Lockfile bereitgestellt wurde,
musste dieses manuell erstellt werden,
indem die Gesamtheit der benötigten Versionen aller (transitiven) Abhängigkeiten in einer eigenen #emph[Cargo.lock]-Datei festgehalten wurde.
Im Dockerfile wurde die zu analysierende Version von #emph[rustc-rayon] an einen konkreten Git-Commit gepinnt und das selbst erstellte Lockfile in das Image kopiert, wie in dem folgenden Ausschnitt zu sehen ist:

#codly(
  languages: (
    bash: (name: "Dockerfile", color: rgb("#008cdb")),
  ),
  skips: ((1, 10),),
)
#text(7pt)[
  ```bash
  # Grab the sources for rustc's rayon fork for the version used in nightly-2020-08-26.
  RUN git clone https://github.com/rust-lang/rustc-rayon.git \
      && cd rustc-rayon \
      && git checkout ae7bbbd2756

  COPY rustc-rayon-Cargo.lock /rustc-rayon/Cargo.lock
  ```
]

Anhand der von RUDRA erzeugten Ausgabe der gesamten Analyse ließen sich die Behauptungen des RUDRA-Papers erfolgreich verifizieren.
Etwaige Behauptungen bestanden im Wesentlichen aus konkreten Ausschnitten des von RUDRA generierten Reports, die es in der Reproduktion lediglich wiederzufinden galt.

#figure(
  image("../res/stdlib_02_crate_severity.png", width: 100%),
  caption: [
    Befunde der Standardbibliothek-Analyse nach Crate und Schweregrad.
  ],
) <crate-severity>

Zur detaillierten Auswertung der Standardbibliotheksbefunde wurde die RUDRA-Ausgabe vollständig geparst,
wobei alle gefundenen Bugs inklusive Schweregrad,
Analyseverfahren und Beschreibung den jeweiligen Crates zugeordnet wurden.
Die hierbei erhaltenen Ergebnisse sind in dem Balkendiagramm in @crate-severity dargestellt.

Insgesamt lieferte die Analyse 168 Befunde über die vier untersuchten Crates,
von denen 35 als #emph[Error], 69 als #emph[Warning] und 64 als #emph[Info] klassifiziert wurden.
Es entfallen 10 Befunde auf #emph[rayon-core], 70 auf #emph[core], 52 auf #emph[alloc] und 36 auf #emph[std].
Mit 100 Befunden wurde der Großteil der Bugs mithilfe des #emph[UnsafeDataflow]-Verfahrens gefunden, während 68 Befunde auf #emph[SendSyncVariance] zurückgehen.
Die Ergebnisse decken auch die im Paper beschriebenen Sicherheitslücken in der Standardbibliothek und im Compiler ab,
darunter #emph[str::join_generic_copy] (CVE-2020-36323 @CVE202036323),
#emph[io::read_to_end_with_reservation] (CVE-2021-28875 @CVE202128875),
#emph[String::retain] (CVE-2020-36317 @CVE202036317) sowie die 'WorkerLocal'-Implementierung in #emph[rustc-rayon] (rust-lang/rust#81425 @rustlang_81425).

Die vergleichsweise niedrige Buganzahl in der #emph[rustc-rayon]-Crate lässt sich auf das Codevolumen zurückführen, welches hinsichtlich der Zeilenanzahl geringer ausfällt als in den Kern-Crates.
// TODO: ggf ermitteln ...

== Analyse des crates.io-Ökosystems

Die dritte und umfangreichste Evaluation wiederholt die zentrale Kampagne des Papers,
wobei alle Crates der Rust-Package-Registry analysiert werden.
Zum Zeitpunkt der ursprünglichen Analyse belief sich das Crates.io-Ökosystem auf 42.625 Crates, welche im Rahmen der Reproduktion ebenfalls betrachtet wurden.

Die Kampagne stellt hohe Anforderungen an die Hardware:
Für den Download und die Zwischenergebnisse aller Crates werden über 256 GB Speicherplatz benötigt,
und die reine Ausführungszeit beträgt laut den ursprünglichen Angaben etwa zehn Stunden.
In der verwendeten Testumgebung mit einem Intel i9-11900H und 32 GB RAM dauerte die komplette Evaluation über 20 Stunden.
Hinzu kamen erneut technische Hürden, da einige der bereitgestellten Evaluationsskripte nicht ohne Anpassungen funktionierten.
Zusätzlich verursachte das gleichzeitige File-Locking der vielen Projekte auf dem verwendeten WSL-System wiederholt Fehler,
weshalb die Kampagne schließlich auf CachyOS durchgeführt wurde.

Die erzielten Ergebnisse stimmen mit denen aus dem Jahr 2021 nahezu vollständig überein,
wie in der tabellarischen Gegenüberstellung in @campaign-comparison zu erkennen ist.
Von den 42.625 Crates kompilierten in unserer Ausführung 33.175 erfolgreich (2021: 33.223), 6.704 scheiterten bereits an der Kompilierung (2021: 6.656); die übrigen Statusklassen blieben unverändert.
Die #emph[SendSyncVariance]-Analyse meldete 366, 791 sowie 1.174 Berichte für hohe, mittlere bzw. niedrige Präzision (2021: 367, 793, 1.176); die #emph[UnsafeDataflow]-Analyse lieferte mit 137, 434 und 1.214 Berichten exakt die Werte von 2021.

#place(top, scope: "parent", float: true, clearance: 12pt)[
  #figure(
    image("../res/campaign_comparison.png", width: 100%),
    caption: [
      Vergleich der Kampagnen 2021 und 2026 auf der Package-Registry.
    ],
  ) <campaign-comparison>
]

Der einzige festzustellende Unterschied besteht darin, dass 48 Crates,
die 2021 noch erfolgreich analysiert wurden,
heute nicht mehr kompilieren.
Mit einer Abweichung von etwa 0,11% bezogen auf die Gesamtmenge aller Crates ist dies statistisch unerheblich.
Die Ursachen lassen sich dennoch in zwei Gruppen einteilen: 31 Crates scheitern an Build-Skripten mit veralteten oder nicht mehr erreichbaren URLs (etwa HTTP-403-Fehler bei S3-Spiegeln von libsodium, umgezogenen PyTorch-Downloads oder korrupten Archiven) sowie an Git-Commits, die nicht fest referenziert wurden.
Bei den übrigen 17 Crates ist der Fehler auf Hardware-Inkompatibilitäten zurückzuführen,
da der verwendete Prozessor zu modern ist und diese Crates das CPU-Ziel daher nicht bestimmen können.

// #figure(
//   image("../../evaluation/package_breakdown.png", width: 100%),
//   caption: [
//     Ursachenanalyse der 48 zwischen 2021 und 2026 verlorenen Pakete.
//   ],
// ) // fuck this awful img
