# res://scripts/core/Algorithms/FordFulkerson.gd
extends RefCounted
class_name FordFulkerson

func run(graph: Graph, source: String, sink: String) -> Dictionary:
	# Crearemos una representación de capacidades (orientado)
	var cap := {}
	for u in graph.nodes():
		cap[u] = {}
		for e in graph.get_neighbors(u):
			cap[u][e["to"]] = e["weight"] # capacidad inicial
			if not cap.has(e["to"]):
				cap[e["to"]] = {}
			if not cap[e["to"]].has(u):
				cap[e["to"]][u] = 0.0
	var maxflow := 0.0
	var steps := []
	while true:
		# BFS para encontrar camino aumentado (parent map)
		var parent := {}
		var q := []
		q.push_back(source)
		parent[source] = null
		while q.size() > 0 and not parent.has(sink):
			var u = q.pop_front()
			for v in cap[u].keys():
				if not parent.has(v) and cap[u][v] > 0 and v != source:
					parent[v] = u
					q.push_back(v)
		if not parent.has(sink):
			break
		# encontrar bottleneck
		var path_flow := INF
		var v := sink
		while v != source:
			var u = parent[v]
			path_flow = min(path_flow, cap[u][v])
			v = u
		# actualizar capacidades
		v = sink
		while v != source:
			var u = parent[v]
			cap[u][v] -= path_flow
			cap[v][u] += path_flow
			steps.append({"type":"augment", "from":u, "to":v, "flow":path_flow})
			v = u
		maxflow += path_flow
		steps.append({"type":"flow_update", "maxflow": maxflow})
	return {"steps": steps, "maxflow": maxflow}
