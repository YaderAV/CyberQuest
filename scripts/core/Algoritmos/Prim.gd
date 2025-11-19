# res://scripts/core/Algoritmos/Prim.gd
extends RefCounted
class_name Prim

# Retorna un Dictionary con:
# "mst_cost": float (Costo total del árbol)
# "steps": Array (para la visualización)
# "edges": Array (Las aristas que forman el MST)
static func run(graph: Graph) -> Dictionary:
	var steps := []
	var mst_edges := []
	var nodes_list = graph.nodes()
	if nodes_list.size() < 1:
		return {"mst_cost": 0.0, "steps": steps, "edges": mst_edges}
		
	# 1. Inicialización
	var start_node = nodes_list.pick_random() # Empezar desde un nodo cualquiera
	var visited := {}
	var min_cost = 0.0
	
	# Usaremos un Array para simular la cola de prioridad (almacena aristas {weight, u, v})
	var priority_queue := [] 
	
	visited[start_node] = true
	
	# 2. Añadir todas las aristas del nodo inicial a la cola de prioridad
	for edge in graph.get_neighbors(start_node):
		# En Prim, la cola almacena las ARISTAS CANDIDATAS
		priority_queue.append({
			"capacity": edge.capacity, 
			"u": start_node, 
			"v": edge.to
		})
		steps.append({
			"type": "enqueue", 
			"node": edge.to, 
			"capacity": edge.capacity, 
			"description": "Adding candidate edge to %s" % edge.to
		})

	# 3. Bucle principal
	while mst_edges.size() < nodes_list.size() - 1 and not priority_queue.is_empty():
		
		# Ordenar la cola para simular la extracción del MÍNIMO (O(N*logN) en sorting)
		priority_queue.sort_custom(func(a, b): return a.capacity < b.capacity)
		
		# Extraer la arista de menor peso
		var min_edge = priority_queue.pop_front()
		var u = min_edge.u
		var v = min_edge.v
		var capacity = min_edge.capacity

		# Si el nodo 'v' ya fue visitado, descartar esta arista
		if visited.has(v):
			steps.append({"type": "discard", "edge": [u, v], "description": "Discarded edge %s-%s (cycle)" % [u, v]})
			continue

		# 4. Aceptar la arista e incluir el nodo
		visited[v] = true
		mst_edges.append(min_edge)
		min_cost += capacity
		
		steps.append({
			"type": "add_edge", 
			"u": u, 
			"v": v, 
			"capacity": capacity, 
			"description": "Added edge %s-%s to MST. Total cost: %.1f" % [u, v, min_cost]
		})
		
		# 5. Añadir las nuevas aristas candidatas de 'v'
		for edge in graph.get_neighbors(v):
			var w = edge.to
			if not visited.has(w):
				priority_queue.append({
					"capacity": edge.capacity, 
					"u": v, 
					"v": w
				})
				steps.append({"type": "enqueue", "node": w, "capacity": edge.capacity, "description": "New edge candidate to %s" % w})
				
	return {"mst_cost": min_cost, "steps": steps, "edges": mst_edges}
