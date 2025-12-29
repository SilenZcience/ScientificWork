class Graph:
    def __init__(self, n):
        self.n = n
        self.adj = [set() for _ in range(n)]

    def add_edge(self, u, v):
        self.adj[u].add(v)
        self.adj[v].add(u)

    def remove_edge(self, u, v):
        self.adj[u].discard(v)
        self.adj[v].discard(u)

    def deg(self, u):
        return len(self.adj[u])

    def has_edge(self, u, v):
        return v in self.adj[u]

    def vertices(self):
        return [i for i, nbrs in enumerate(self.adj) if nbrs]

    def is_K3(self):
        V = self.vertices()
        return len(V) == 3 and all(len(self.adj[v]) == 2 for v in V)


def has_hamilton_cycle(G):
    """
    Prüft ob ein 2-reduzierbarer Graph einen Hamilton-Kreis hat.
    """
    V = set(range(G.n))

    while len(V) > 3:
        # Wähle Knoten u mit deg(u) <= 2
        u = None
        for x in V:
            if G.deg(x) <= 2:
                u = x
                break

        if u is None or G.deg(u) < 2:
            return False

        # Grad(u) == 2
        neighbors = list(G.adj[u])
        v, w = neighbors[0], neighbors[1]

        # 2-Reduktion durchführen
        G.remove_edge(u, v)
        G.remove_edge(u, w)
        V.remove(u)
        if not G.has_edge(v, w):
            G.add_edge(v, w)

    # Prüfe ob Restgraph K3 ist
    return G.is_K3()


G = Graph(5)
hamiltonian_edges = [(i, (i+1) % 5) for i in range(5)]
for u, v in hamiltonian_edges:
    G.add_edge(u, v)
G.add_edge(0,2)
G.add_edge(0,3)
print("Adjazenzlisten:", G.adj)

print("Hamiltonkreis existiert:", has_hamilton_cycle(G))
