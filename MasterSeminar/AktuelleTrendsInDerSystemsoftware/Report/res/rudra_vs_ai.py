import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

BG = "#FAFAFA"
C_RUDRA = "#4C72B0"
C_AI = "#55A868"
C_BOTH = "#DD8452"
C_REFUSED = "#C44E52"
C_AI_ONLY = "#8172B3"

plt.rcParams.update({
    "figure.facecolor": BG,
    "axes.facecolor": BG,
    "font.family": "sans-serif",
    "font.size": 11,
})

fig, ax = plt.subplots(figsize=(9, 6), facecolor="white")
ax.set_xlim(0, 14)
ax.set_ylim(0, 10)
ax.axis("off")
ax.set_title("Rudra vs. AI: Bug-Findungen",
             fontsize=17, fontweight="bold")

ellipse_r = mpatches.Ellipse((5.2, 5.2), width=6.5, height=5.0,
                              facecolor=C_RUDRA, alpha=0.30,
                              edgecolor=C_RUDRA, linewidth=2.5)
ellipse_a = mpatches.Ellipse((8.8, 5.2), width=6.5, height=5.0,
                              facecolor=C_AI, alpha=0.30,
                              edgecolor=C_AI, linewidth=2.5)
ax.add_patch(ellipse_r)
ax.add_patch(ellipse_a)

ax.text(3.8, 5.4, "3", ha="center", va="center",
        fontsize=24, fontweight="bold", color=C_REFUSED)
ax.text(3.8, 4.5, "Nur Rudra\n(AI verweigerte)", ha="center",
        fontsize=12, color="#555555")

ax.text(7.0, 5.4, "8", ha="center", va="center",
        fontsize=40, fontweight="bold", color=C_BOTH)
ax.text(7.0, 4.3, "Beide gefunden", ha="center",
        fontsize=12, color="#555555")

ax.text(10.2, 5.4, "1", ha="center", va="center",
        fontsize=20, fontweight="bold", color=C_AI_ONLY)
ax.text(10.2, 4.5, "Nur AI", ha="center",
        fontsize=12, color="#555555")

ax.text(3.2, 8.2, "Rudra", ha="center", fontsize=17,
        fontweight="bold", color=C_RUDRA)
ax.text(10.8, 8.2, "AI", ha="center", fontsize=17,
        fontweight="bold", color=C_AI)

ax.text(7.0, 2,
        "Rudra: 11 Bugs  |  AI: 9 Bugs  |  Trefferquote: 72,7 %",
        ha="center", fontsize=12, fontweight="bold", fontstyle="italic", color="#333333",
        bbox=dict(boxstyle="round,pad=0.4", fc="white", ec="#CCCCCC"))

plt.tight_layout()
plt.savefig("rudra_vs_ai.png", dpi=400, bbox_inches="tight", facecolor="white")
plt.show()
