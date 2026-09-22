import matplotlib.pyplot as plt
import numpy as np

severity = ["High", "Medium", "Low"]

# SendSyncVariance
sv_vis_21 = [118, 181, 197]
sv_int_21 = [ 60,  98, 111]
sv_vis_p  = [118, 182, 197]
sv_int_p  = [ 59,  96, 109]
sv_vis_26 = [117, 179, 195]
sv_int_26 = [ 60,  98, 111]

# UnsafeDataflow
ud_vis_21 = [ 65, 119, 163]
ud_int_21 = [  8,  17,  31]
ud_vis_p  = [ 65, 118, 162]
ud_int_p  = [  7,  15,  28]
ud_vis_26 = [ 65, 119, 163]
ud_int_26 = [  8,  17,  31]

C_TOOL = "#4C72B0"
C_PAPER = "#DD8452"
C_2026 = "#55A868"
BG = "#FAFAFA"

plt.rcParams.update({
    "figure.facecolor": BG,
    "axes.facecolor": BG,
    "axes.grid": True,
    "grid.color": "#E0E0E0",
    "grid.linewidth": 0.6,
    "font.family": "sans-serif",
    "font.size": 11,
})


def grouped_bars(ax, vis_data, int_data, title):
    x = np.arange(len(severity))
    w = 0.25

    # visible bars
    b1 = ax.bar(x - w, vis_data[0], w, label="2021 (tool)", color=C_TOOL, edgecolor="white")
    b2 = ax.bar(x,     vis_data[1], w, label="2021 (paper)", color=C_PAPER, edgecolor="white")
    b3 = ax.bar(x + w, vis_data[2], w, label="2026", color=C_2026, edgecolor="white")

    # internal bars (stacked on top)
    bottom1 = [v for v in vis_data[0]]
    bottom2 = [v for v in vis_data[1]]
    bottom3 = [v for v in vis_data[2]]

    ax.bar(x - w, int_data[0], w, bottom=bottom1, color=C_TOOL, edgecolor="white", alpha=0.45, hatch="///")
    ax.bar(x,     int_data[1], w, bottom=bottom2, color=C_PAPER, edgecolor="white", alpha=0.45, hatch="///")
    ax.bar(x + w, int_data[2], w, bottom=bottom3, color=C_2026, edgecolor="white", alpha=0.45, hatch="///")

    # labels on top of each stack
    for i in range(len(severity)):
        for j, (dx, vd, id_) in enumerate([
            (-w, vis_data[0], int_data[0]),
            (0,  vis_data[1], int_data[1]),
            (w,  vis_data[2], int_data[2]),
        ]):
            total = vd[i] + id_[i]
            ax.text(x[i] + dx, total + 1.5, str(total), ha="center", va="bottom",
                    fontsize=10, fontweight="bold")

    ax.set_xticks(x)
    ax.set_xticklabels(severity, fontsize=14, fontweight="bold")
    ax.tick_params(axis='y', labelsize=14)
    ax.set_ylabel("Bugs reproduziert", fontsize=15, fontweight="bold")
    ax.set_title(title, fontsize=14, fontweight="bold", pad=12)
    ax.legend(loc="upper left", fontsize=14, frameon=True, fancybox=True)
    ax.spines[["top", "right"]].set_visible(False)
    ax.set_axisbelow(True)

    # annotate visible / internal
    ax.text(0.98, 0.05, "ausgefüllt =  visible\nschraffiert = internal",
            transform=ax.transAxes, ha="right", va="bottom", fontsize=13,
            fontstyle="italic", color="#333333", fontfamily="monospace", fontweight="bold")


fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6), facecolor="white")
fig.suptitle("Bug Reproduktion: 2021 vs 2026", fontsize=18, fontweight="bold", y=0.98)

grouped_bars(ax1,
             vis_data=[sv_vis_21, sv_vis_p, sv_vis_26],
             int_data=[sv_int_21, sv_int_p, sv_int_26],
             title="SendSyncVariance")

grouped_bars(ax2,
             vis_data=[ud_vis_21, ud_vis_p, ud_vis_26],
             int_data=[ud_int_21, ud_int_p, ud_int_26],
             title="UnsafeDataflow")

plt.tight_layout(rect=[0, 0, 1, 0.93])
plt.savefig("bug_reproduction.png", dpi=200, bbox_inches="tight", facecolor="white")
plt.show()
