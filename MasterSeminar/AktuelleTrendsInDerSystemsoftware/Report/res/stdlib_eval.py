import re
import os
from collections import defaultdict

import matplotlib.pyplot as plt
import numpy as np

# parser
REPORT_PATH = os.path.join(os.path.dirname(__file__), "rudra-std-report.txt")

severity_counts = defaultdict(int)
category_counts = defaultdict(int)
crate_severity = defaultdict(lambda: defaultdict(int))
crate_category = defaultdict(lambda: defaultdict(int))
ssv_subcat_counts = defaultdict(int)
udf_subcat_counts = defaultdict(int)

FINDING_RE = re.compile(
    r"^(Error|Warning|Info)\s+"
    r"\((SendSyncVariance|UnsafeDataflow):(?:/[A-Za-z]+)+\):\s+(.*)"
)


seen = set()
current_crate = "unknown"

CRATE_MARKERS = {
    "rayon-core": "rayon-core",
    "library/core": "core",
    "library/alloc": "alloc",
    "library/std": "std",
}


def detect_crate_from_path(path_line):
    for marker, crate in CRATE_MARKERS.items():
        if marker in path_line:
            return crate
    return None


with open(REPORT_PATH, encoding="utf-8", errors="replace") as f:
    all_lines = [l.rstrip("\n") for l in f]

i = 0
while i < len(all_lines):
    line = all_lines[i]
    m = FINDING_RE.match(line)

    if m:
        path_line = all_lines[i + 1] if i + 1 < len(all_lines) else ""
        crate = detect_crate_from_path(path_line) or current_crate
        current_crate = crate

        level = m.group(1)
        full_cat = line.split("(")[1].split(")")[0]
        top_cat = m.group(2)
        parts = full_cat.split("/")
        subcats = parts[1:] if len(parts) > 1 else []

        severity_counts[level] += 1
        category_counts[top_cat] += 1
        crate_severity[crate][level] += 1
        crate_category[crate][top_cat] += 1

        if top_cat == "SendSyncVariance" and subcats:
            ssv_subcat_counts[subcats[0]] += 1
        elif top_cat == "UnsafeDataflow" and subcats:
            udf_subcat_counts[subcats[0]] += 1

    i += 1

total = sum(severity_counts.values())

print(f"Total findings: {total}")
for lvl in ("Error", "Warning", "Info"):
    print(f"  {lvl}: {severity_counts[lvl]}")
print()
for c in ("rayon-core", "core", "alloc", "std"):
    s = crate_severity[c]
    print(f"  {c}: {sum(s.values())}  (E={s['Error']}, W={s['Warning']}, I={s['Info']})")

print()
print("SendSyncVariance sub-categories:")
for k, v in sorted(ssv_subcat_counts.items(), key=lambda x: -x[1]):
    print(f"  {k}: {v}")
print()
print("UnsafeDataflow sub-categories:")
for k, v in sorted(udf_subcat_counts.items(), key=lambda x: -x[1]):
    print(f"  {k}: {v}")

# ── Style ───────────────────────────────────────────────────────────────
C_ERROR = "#C44E52"
C_WARN = "#DD8452"
C_INFO = "#4C72B0"
C_CAT1 = "#55A868"
C_CAT2 = "#4C72B0"
BG = "#FAFAFA"

plt.rcParams.update({
    "figure.facecolor": BG,
    "axes.facecolor": BG,
    "axes.grid": False,
    "font.family": "sans-serif",
    "font.size": 11,
})

crates = ["rayon-core", "core", "alloc", "std"]
sevs = ["Error", "Warning", "Info"]

OUT_DIR = os.path.dirname(__file__)

# Zusammenfassung
fig = plt.figure(figsize=(8, 2.8), facecolor="white")
ax = fig.add_axes([0, 0, 1, 0.75])
ax.axis("off")

col_labels = ["Crate", "Fehler", "Warnung", "Info", "Gesamt"]
cell_text = []
cell_colours = []
for c in crates:
    row = [c]
    row_cols = ["white"]
    for s in sevs:
        v = crate_severity[c][s]
        row.append(str(v))
        if s == "Error":
            row_cols.append("#FFDDDD" if v > 0 else "white")
        elif s == "Warning":
            row_cols.append("#FFF3DD" if v > 0 else "white")
        else:
            row_cols.append("#DDDDFF" if v > 0 else "white")
    t = sum(crate_severity[c].values())
    row.append(str(t))
    row_cols.append("#E8E8E8")
    cell_text.append(row)
    cell_colours.append(row_cols)

totals_row = ["Total"]
totals_cols = ["#D0D0D0"]
for s in sevs:
    totals_row.append(str(severity_counts[s]))
    totals_cols.append("#D0D0D0")
totals_row.append(str(total))
totals_cols.append("#D0D0D0")
cell_text.append(totals_row)
cell_colours.append(totals_cols)

table = ax.table(
    cellText=cell_text,
    colLabels=col_labels,
    cellColours=cell_colours,
    colColours=["#D0D0D0"] * 5,
    loc="center",
    cellLoc="center",
)
table.auto_set_font_size(False)
table.set_fontsize(11)
table.scale(1, 1.5)
for (row, col), cell in table.get_celld().items():
    cell.set_edgecolor("#CCCCCC")
    if row == 0:
        cell.set_text_props(fontweight="bold")
    if col == 0 and row > 0:
        cell.set_text_props(ha="left")

fig.text(0.5, 0.92, "Rudra STL Evaluation", fontsize=16, fontweight="bold", ha="center")
fig.text(0.5, 0.82, f"{total} Ergebnisse über 4 Crates (rayon-core, core, alloc, std)",
         ha="center", fontsize=11, color="#555555", fontstyle="italic")
fig.savefig(os.path.join(OUT_DIR, "stdlib_01_summary.png"), dpi=400, bbox_inches="tight", facecolor="white")
plt.close(fig)

#Stacked bar chart
fig, ax = plt.subplots(figsize=(8, 5), facecolor="white")

x = np.arange(len(crates))
width = 0.55
e_vals = [crate_severity[c]["Error"] for c in crates]
w_vals = [crate_severity[c]["Warning"] for c in crates]
i_vals = [crate_severity[c]["Info"] for c in crates]

ax.bar(x, e_vals, width, label="Fehler", color=C_ERROR, edgecolor="white")
ax.bar(x, w_vals, width, bottom=e_vals, label="Warnung", color=C_WARN, edgecolor="white")
ax.bar(x, i_vals, width,
       bottom=[e + w for e, w in zip(e_vals, w_vals)],
       label="Info", color=C_INFO, edgecolor="white")

for idx in range(len(crates)):
    total_c = e_vals[idx] + w_vals[idx] + i_vals[idx]
    ax.text(idx, total_c + 0.5, str(total_c), ha="center", va="bottom",
            fontsize=14, fontweight="bold")

ax.set_xticks(x)
ax.set_xticklabels(crates, fontsize=12, fontweight="bold")
ax.tick_params(axis='y', labelsize=14)
ax.set_ylabel("Ergebnisse", fontsize=13, fontweight="bold")
ax.set_title("Ergebnisse nach Crate und Schweregrad", fontsize=14, fontweight="bold", pad=10)
ax.legend(loc="upper left", fontsize=14, frameon=True, fancybox=True)
ax.spines[["top", "right"]].set_visible(False)
ax.set_axisbelow(True)
ax.yaxis.grid(True, color="#E0E0E0", linewidth=0.6)
fig.tight_layout()
fig.savefig(os.path.join(OUT_DIR, "stdlib_02_crate_severity.png"), dpi=200, bbox_inches="tight", facecolor="white")
plt.close(fig)

# pie chart
fig, ax = plt.subplots(figsize=(6, 6), facecolor="white")

cat_labels = ["SendSyncVariance", "UnsafeDataflow"]
cat_vals = [category_counts[c] for c in cat_labels]
cat_cols = [C_CAT1, C_CAT2]

wedges, texts, autotexts = ax.pie(
    cat_vals, labels=cat_labels,
    autopct=lambda p: f"{p:.1f}%\n({int(round(p * total / 100))})",
    colors=cat_cols, startangle=90, textprops={"fontsize": 11},
    wedgeprops={"edgecolor": "white", "linewidth": 2},
)
for t in autotexts:
    t.set_fontsize(10)
    t.set_fontweight("bold")
ax.set_title("Analysekategorie", fontsize=14, fontweight="bold", pad=15)
fig.tight_layout()
fig.savefig(os.path.join(OUT_DIR, "stdlib_03_category_pie.png"), dpi=200, bbox_inches="tight", facecolor="white")
plt.close(fig)

# SendSyncVariance sub-categories
fig, ax = plt.subplots(figsize=(8, 4), facecolor="white")

ssv_labels = sorted(ssv_subcat_counts.keys(), key=lambda k: ssv_subcat_counts[k], reverse=True)
ssv_vals = [ssv_subcat_counts[k] for k in ssv_labels]
y_ssv = np.arange(len(ssv_labels))

bars = ax.barh(y_ssv, ssv_vals, color="#55A868", edgecolor="white", height=0.6)
for bar, v in zip(bars, ssv_vals):
    ax.text(bar.get_width() + 0.3, bar.get_y() + bar.get_height() / 2,
            str(v), va="center", ha="left", fontsize=10, fontweight="bold")

ax.set_yticks(y_ssv)
ax.set_yticklabels(ssv_labels, fontsize=10)
ax.invert_yaxis()
ax.set_xlabel("Gefundene Probleme")
ax.set_title("SendSyncVariance - Unterkategorien", fontsize=14, fontweight="bold", pad=10)
ax.spines[["top", "right"]].set_visible(False)
ax.set_axisbelow(True)
ax.xaxis.grid(True, color="#E0E0E0", linewidth=0.6)
fig.tight_layout()
fig.savefig(os.path.join(OUT_DIR, "stdlib_04_ssv_subcats.png"), dpi=200, bbox_inches="tight", facecolor="white")
plt.close(fig)

# UnsafeDataflow sub-categories
fig, ax = plt.subplots(figsize=(8, 4), facecolor="white")

udf_labels = sorted(udf_subcat_counts.keys(), key=lambda k: udf_subcat_counts[k], reverse=True)
udf_vals = [udf_subcat_counts[k] for k in udf_labels]
y_udf = np.arange(len(udf_labels))

bars = ax.barh(y_udf, udf_vals, color="#4C72B0", edgecolor="white", height=0.6)
for bar, v in zip(bars, udf_vals):
    ax.text(bar.get_width() + 0.3, bar.get_y() + bar.get_height() / 2,
            str(v), va="center", ha="left", fontsize=10, fontweight="bold")

ax.set_yticks(y_udf)
ax.set_yticklabels(udf_labels, fontsize=10)
ax.invert_yaxis()
ax.set_xlabel("Gefundene Probleme")
ax.set_title("UnsafeDataflow - Unterkategorien", fontsize=14, fontweight="bold", pad=10)
ax.spines[["top", "right"]].set_visible(False)
ax.set_axisbelow(True)
ax.xaxis.grid(True, color="#E0E0E0", linewidth=0.6)
fig.tight_layout()
fig.savefig(os.path.join(OUT_DIR, "stdlib_05_udf_subcats.png"), dpi=200, bbox_inches="tight", facecolor="white")
plt.close(fig)

print(f"\nSaved 5 charts to {OUT_DIR}")
