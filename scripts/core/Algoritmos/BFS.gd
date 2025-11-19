# res://scripts/core/Algoritmos/BFS.gd
extends RefCounted
class_name BFS

static func run(graph: Graph, start: String) -> Dictionary:
	print("--- DEBUG (BFS.gd): Iniciando 'run' ---") # <-- DEBUG 1
	
	var steps := []
	var key := ""
	var sequence_array := []

	var queue: Array[String] = []
	var visited := {}

	queue.push_back(start)
	visited[start] = true
	
	print("--- DEBUG (BFS.gd): Iniciando bucle while ---") # <-- DEBUG 2
	
	while not queue.is_empty():
		var current: String = queue.pop_front()
		
		print("--- DEBUG (BFS.gd): Procesando nodo: %s ---" % current) # <-- DEBUG 3
		
		# 1. Lógica del Minijuego
		key += graph.get_node_letter(current)
		sequence_array.append(current)
		
		# 2. Registrar paso de VISITA
		steps.append({
			"type": "visit",
			"node": current,
			"path":sequence_array,
			"letter": graph.get_node_letter(current), 
			"description": "Node %s visited." % current
		})
		
		# 3. Obtener y ordenar vecinos
		var neighbors = graph.get_neighbors(current).duplicate()
		neighbors.sort_custom(func(a, b): return a.capacity < b.capacity)
		
		# 4. Procesar vecinos
		for edge in neighbors:
			var nid: String = edge["to"]
			
			if not visited.has(nid):
				visited[nid] = true
				queue.push_back(nid)
				
				# 5. Registrar paso de ENCOLAR (El que corregimos)
				var edge_weight: float = edge.get("capacity", 1.0)
				
				steps.append({
					"type": "enqueue",
					"node": nid,
					"from_node": current,
					"edge_weight": edge_weight,
					"frontier": queue.duplicate(),
					"description": "Neighbor %s enqueued." % nid
				})

	# 6. Paso Final
	steps.append({
		"type": "finish_path",
		"path": sequence_array,
		"description": "Recorrido BFS finalizado."
	})
	
	print("--- DEBUG (BFS.gd): 'run' completado. Retornando... ---") # <-- DEBUG 4
				
	return {"key": key, "steps": steps}
