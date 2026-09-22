import matplotlib.pyplot as plt
import numpy as np

pkg_labels = [
    "Packages Okay",
    "Early Compile Errors",
    "Lint Compile Errors",
    "Empty Target",
    "Metadata Error",
    "Only macOS Error",
]
pkg_2021 = [33223, 6656, 3, 1974, 751, 18]
pkg_2026 = [33175, 6704, 3, 1974, 751, 18]

sv_labels = ["High", "Medium", "Low"]
sv_2021 = [367, 793, 1176]
sv_2026 = [366, 791, 1174]

ud_labels = ["High", "Medium", "Low"]
ud_2021 = [137, 434, 1214]
ud_2026 = [137, 434, 1214]

all_labels = pkg_labels + ["", "SendSyncVariance"] + sv_labels + ["", "UnsafeDataFlow"] + ud_labels
all_2021   = pkg_2021   + [None] + [None]          + sv_2021   + [None] + [None]           + ud_2021
all_2026   = pkg_2026   + [None] + [None]          + sv_2026   + [None] + [None]           + ud_2026
all_delta  = [b - a if a is not None else None for a, b in zip(all_2021, all_2026)]

# sometimes higher is better, sometimes inverted
higher_is_better = [True, False, False, False, False, False,
                    None,
                    None,
                    False, False, False,
                    None,
                    None,
                    False, False, False]


def delta_colour(d, hib):
    if d is None or d == 0 or hib is None:
        return "white"
    good = (d > 0) if hib else (d < 0)
    return "#DDFFDD" if good else "#FFDDDD"

fig = plt.figure(figsize=(14, 6), facecolor="white")
fig.suptitle("2021 vs 2026 Kampagnenvergleich (Crates.io)", fontsize=18, fontweight="bold", y=0.97)
fig.text(0.5, 0.91, "42.625 Crates pro Kampagne analysiert",
         ha="center", fontsize=12, color="#555555", fontstyle="italic")

ax_table = fig.add_axes([0.05, 0.03, 0.9, 0.86])
ax_table.axis("off")

col_labels = ["", "2021", "2026", "Δ", "%"]
cell_text = []
cell_colours = []

for i, lab in enumerate(all_labels):
    if lab == "":
        cell_text.append(["", "", "", "", ""])
        cell_colours.append(["white"] * 5)
    elif all_2021[i] is None:
        # section header
        cell_text.append([lab, "", "", "", ""])
        cell_colours.append(["#E8E8E8"] * 5)
    else:
        d = all_delta[i]
        sign = "+" if d > 0 else ""
        pct = d / all_2021[i] * 100 if all_2021[i] != 0 else 0
        cell_text.append([lab, f"{all_2021[i]:,}".replace(",", "."), f"{all_2026[i]:,}".replace(",", "."), f"{sign}{d:,}".replace(",", "."), f"{pct:+.2f}%".replace(".", ",")])
        dc = delta_colour(d, higher_is_better[i])
        cell_colours.append(["white", "white", "white", dc, dc])

table = ax_table.table(
    cellText=cell_text,
    colLabels=col_labels,
    cellColours=cell_colours,
    colColours=["#D0D0D0"] * 5,
    loc="center",
    cellLoc="center",
)
table.auto_set_font_size(False)
table.set_fontsize(11)
table.scale(1, 1.55)
for (row, col), cell in table.get_celld().items():
    cell.set_edgecolor("#CCCCCC")
    if row == 0:
        cell.set_text_props(fontweight="bold")
    if col == 0 and row > 0:
        cell.set_text_props(ha="left")

plt.savefig("campaign_comparison.png", dpi=200, bbox_inches="tight", pad_inches=0.1, facecolor="white")

fig_delta, ax = plt.subplots(figsize=(8, 5), facecolor="white")

labels_d = []
vals_d = []
hib_d = []
for lab, d, hib in reversed(list(zip(all_labels, all_delta, higher_is_better))):
    if d is not None and d != 0:
        labels_d.append(lab)
        vals_d.append(d)
        hib_d.append(hib)

y = np.arange(len(labels_d))
colours = ["#55A868" if ((v > 0) if h else (v < 0)) else "#C44E52" for v, h in zip(vals_d, hib_d)]
bars = ax.barh(y, vals_d, color=colours, edgecolor="white", height=0.55)

for bar, v in zip(bars, vals_d):
    sign = "+" if v > 0 else ""
    ax.text(v + (0.8 if v > 0 else -0.8), bar.get_y() + bar.get_height() / 2,
            f" {sign}{v}", va="center", ha="left" if v > 0 else "right",
            fontsize=11, fontweight="bold", clip_on=False)

ax.axvline(0, color="black", linewidth=0.8)
ax.set_xlim(left=min(vals_d) * 1.25)
ax.set_yticks(y)
ax.set_yticklabels(labels_d, fontsize=10)
ax.set_xlabel("Änderung (2026 - 2021)", fontsize=11)
ax.set_title("Geänderte Metriken (Crates.io)", fontsize=13, fontweight="bold", pad=8)
ax.spines[["top", "right"]].set_visible(False)
fig_delta.tight_layout()
plt.savefig("campaign_delta.png", dpi=200, bbox_inches="tight", facecolor="white")

# 48 lost packages
fig2, (ax_detail, ax_group) = plt.subplots(1, 2, figsize=(16, 5.5), facecolor="white",
                                            gridspec_kw={"width_ratios": [2, 1]})

detail_labels = [
    "CPU-Ziel kann nicht bestimmt werden",
    "HTTP 403 (forbidden)",
    "HTTP 301 (redirect)",
    "Download Fehler",
    "Korruptes Downloadziel",
    "Build-Skript-Assertion",
]
detail_vals = [17, 11, 5, 5, 8, 2]
order_d = np.argsort(detail_vals)
detail_labels = [detail_labels[i] for i in order_d]
detail_vals = [detail_vals[i] for i in order_d]

y_d = np.arange(len(detail_vals))
bars_d = ax_detail.barh(y_d, detail_vals, color="#4C72B0", edgecolor="white", height=0.6)
for bar, v in zip(bars_d, detail_vals):
    ax_detail.text(bar.get_width() + 0.3, bar.get_y() + bar.get_height() / 2,
                   str(v), va="center", ha="left", fontsize=11, fontweight="bold")
ax_detail.set_yticks(y_d)
ax_detail.set_yticklabels(detail_labels, fontsize=10)
ax_detail.invert_yaxis()
ax_detail.set_xlabel("Verlorene Crates")
ax_detail.set_title("Detaillierte Analyse", fontsize=14, fontweight="bold", pad=12)
ax_detail.spines[["top", "right"]].set_visible(False)
ax_detail.set_xlim(0, 20)
ax_detail.set_xticks(range(0, 21, 5))

group_labels = [
    "Hardware-Inkompatibilität\n(CPU zu neu)",
    "Build-Scripts mit veralteten URLs /\n"
    "Git-Commits wurden nicht fest referenziert",
]
group_vals = [17, 31]
order_g = np.argsort(group_vals)
group_labels = [group_labels[i] for i in order_g]
group_vals = [group_vals[i] for i in order_g]

y_g = np.arange(len(group_vals))
bars_g = ax_group.barh(y_g, group_vals, color="#4C72B0", edgecolor="white", height=0.6)
for bar, v in zip(bars_g, group_vals):
    ax_group.text(bar.get_width() + 0.3, bar.get_y() + bar.get_height() / 2,
                  str(v), va="center", ha="left", fontsize=12, fontweight="bold")
ax_group.set_yticks(y_g)
ax_group.set_yticklabels(group_labels, fontsize=10)
ax_group.invert_yaxis()
ax_group.set_xlabel("Verlorene Crates")
ax_group.set_title("Gruppierung in 2 Kategorien", fontsize=14, fontweight="bold", pad=12)
ax_group.spines[["top", "right"]].set_visible(False)
ax_group.set_xlim(0, 37)
ax_group.set_xticks(range(0, 38, 5))

fig2.suptitle("Analyse der 48 verlorenen Pakete  (2021 → 2026)",
              fontsize=16, fontweight="bold", y=1.02)
plt.tight_layout()
plt.savefig("package_breakdown.png", dpi=200, bbox_inches="tight", facecolor="white")
plt.show()
