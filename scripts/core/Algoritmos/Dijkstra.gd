# res://scripts/core/Algorithms/Dijkstra.gd
extends RefCounted
class_name Dijkstra

# Retorna pasos para visualización y el resultado final {distances, prev}
func run(graph: Graph, source: String) -> Dictionary:
	var dist := {}
	var prev := {}
	var Q := []
	for n in graph.nodes():
		dist[n] = INF
		prev[n] = null
		Q.append(n)
	dist[source] = 0.0

	var steps := []
	while Q.size() > 0:
		# extract min in Q (O(n) naive)
		var u = null
		var best := INF
		for x in Q:
			if dist[x] < best:
				best = dist[x]
				u = x
		Q.erase(u)
		steps.append({"type":"extract_min", "node":u, "dist":dist[u], "remaining":Q.duplicate()})
		for edge in graph.get_neighbors(u):
			var v = edge["to"]
			var alt = dist[u] + edge["weight"]
			if alt < dist[v]:
				dist[v] = alt
				prev[v] = u
				steps.append({"type":"relax", "from":u, "to":v, "new_dist":alt})
	return {"steps": steps, "dist": dist, "prev": prev}
