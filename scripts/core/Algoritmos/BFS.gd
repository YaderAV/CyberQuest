# res://scripts/core/Algorithms/BFS.gd
extends RefCounted
class_name BFS

# Retorna un Array de pasos: cada paso = {type: "visit", node: String, frontier: Array}
func run(graph: Graph, start: String) -> Array:
	var visited := {}
	var queue: Array[String] = []
	var steps := []
	queue.push_back(start)
	visited[start] = true
	while queue.size() > 0:
		var current: String = queue.pop_front()
		steps.append({"type":"visit", "node":current, "frontier":queue.duplicate()})
		for nb in graph.get_neighbors(current):
			var nid: String = nb["to"]
			if not visited.has(nid):
				visited[nid] = true
				queue.push_back(nid)
				steps.append({"type":"enqueue", "node":nid, "frontier":queue.duplicate()})
	return steps
