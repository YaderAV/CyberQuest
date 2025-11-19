# res://scripts/core/Algoritmos/Dijkstra.gd
extends RefCounted
class_name Dijkstra

const INF = 1e20 

static func run(graph: Graph, start_node: String, end_node: String) -> Dictionary:
	print("\n--- DEBUG DIJKSTRA: INICIO ---")
	print("Calculando ruta de '%s' a '%s'" % [start_node, end_node])
	
	var steps = []
	var distances = {}
	var previous = {}
	var priority_queue = [] 
	
	# 1. Inicialización
	for node_id in graph.nodes():
		distances[node_id] = INF
		previous[node_id] = null
		priority_queue.append(node_id)
	
	distances[start_node] = 0.0
	
	steps.append({ "type": "visit", "node": start_node, "distance": 0.0 })
	
	while not priority_queue.is_empty():
		# Ordenar (Min-Heap simulado)
		priority_queue.sort_custom(func(a, b): return distances[a] < distances[b])
		
		var u = priority_queue.pop_front()
		
		# DEBUG: Ver qué nodo estamos analizando
		if distances[u] == INF:
			print("  > Nodo %s es inalcanzable (INF). Rompiendo." % u)
			break
			
		print("  > Procesando nodo: %s (Distancia actual: %.1f)" % [u, distances[u]])

		if u == end_node:
			print("    -> ¡DESTINO ALCANZADO!")
			# No hacemos break para permitir que la visualización se complete si se desea

		steps.append({ "type": "extract_min", "node": u, "distance": distances[u] })
		
		# 3. Relajación de vecinos
		var neighbors = graph.get_neighbors(u)
		# print("    - Vecinos encontrados: %d" % neighbors.size())
		
		for edge in neighbors:
			var v = edge["to"]
			
			# Obtener peso seguro
			var weight = edge.get("weight", edge.get("capacity", 1.0))
			
			var alt = distances[u] + weight
			
			# DEBUG: Ver comparación de distancias
			# print("      - Revisando vecino %s. Peso: %.1f. Nueva Dist: %.1f vs Vieja: %.1f" % [v, weight, alt, distances[v]])
			
			if alt < distances[v]:
				print("      ! RELAJACIÓN: %s -> %s (Nueva Mejor Distancia: %.1f)" % [u, v, alt])
				distances[v] = alt
				previous[v] = u
				
				steps.append({
					"type": "relax", "from": u, "to": v, 
					"weight": weight, "new_dist": alt
				})

	# 4. Reconstruir el camino
	var path = []
	var current = end_node
	
	if previous[current] != null or current == start_node:
		while current != null:
			path.insert(0, current)
			current = previous[current]
	
	print("--- DEBUG DIJKSTRA: FINAL ---")
	print("Ruta Final Calculada: ", path)
	print("Costo Total: %.1f\n" % distances[end_node])

	steps.append({
		"type": "finish_path",
		"path": path,
		"total_distance": distances[end_node]
	})
		
	return { "steps": steps, "path": path }
