# res://scripts/core/Algoritmos/FordFulkerson.gd
extends RefCounted
class_name FordFulkerson

var steps: Array = []
const INF = 1e20

# Función Auxiliar: BFS
func _find_path_bfs(graph: Graph, s: String, t: String) -> Array:
	var queue: Array = [s]
	var parent: Dictionary = {} 
	var visited: Dictionary = {s: true} 

	while not queue.is_empty():
		var u: String = queue.pop_front()
		if u == t: break 

		for edge in graph.get_neighbors(u):
			var v: String = edge.to
			var residual_cap: float = edge.capacity - edge.flow
			
			if not visited.has(v) and residual_cap > 0.0:
				visited[v] = true
				parent[v] = u
				queue.push_back(v)

	if not parent.has(t): return [null, 0.0]

	var path: Array = []
	var bottleneck_flow: float = INF
	var curr: String = t
	
	while curr != s:
		path.push_front(curr)
		var prev: String = parent[curr]
		for edge in graph.get_neighbors(prev):
			if edge.to == curr:
				bottleneck_flow = min(bottleneck_flow, edge.capacity - edge.flow)
				break
		curr = prev
	
	path.push_front(s)
	return [path, bottleneck_flow]

# Función Principal
func find_max_flow(graph: Graph, s: String, t: String) -> Dictionary:
	print("\n--- DEBUG FORD-FULKERSON: INICIO ---")
	print("Calculando Flujo Máximo de %s a %s" % [s, t])
	
	steps.clear()
	graph.reset_flow() 
	
	var max_flow: float = 0.0
	steps.append({"type": "start", "description": "Iniciando Ford-Fulkerson"})

	while true:
		var path_data = _find_path_bfs(graph, s, t)
		var path = path_data[0]
		var bottleneck = path_data[1]

		if path == null:
			print("  > No hay más rutas de aumento. Terminando.")
			break 

		print("  > Ruta de aumento encontrada: %s (Bottleneck: %.1f)" % [str(path), bottleneck])
		max_flow += bottleneck
		
		# Visualización de la ruta (tipo 'augment' activa _flow_animate)
		steps.append({
			"type": "augment",
			"path": path,
			"flow": bottleneck,
			"from": path[0], # Solo para referencia
			"to": path.back(),
			"description": "Enviando %.1f datos" % bottleneck
		})

		# Actualizar grafo
		for i in range(path.size() - 1):
			var u = path[i]
			var v = path[i+1]

			# Actualizar Ida
			for edge in graph.get_neighbors(u):
				if edge.to == v:
					edge.flow += bottleneck
					edge.residual_capacity = edge.capacity - edge.flow
					break
			
			# Actualizar Vuelta
			for edge in graph.get_neighbors(v):
				if edge.to == u:
					edge.flow -= bottleneck
					edge.residual_capacity = edge.capacity - edge.flow
					break
	
	print("--- DEBUG FORD-FULKERSON: FINAL ---")
	print("Flujo Total Máximo: %.1f\n" % max_flow)

	steps.append({
		"type": "finish_flow",
		"max_flow": max_flow
	})
	
	return {"max_flow": max_flow, "steps": steps}
