## res://scripts/core/Algoritmos/DFS.gd
extends RefCounted
class_name DFS

# Devuelve un diccionario:
# "key": String (la clave de letras)
# "steps": Array (para el visualizador)
static func run(graph: Graph, start: String) -> Dictionary:
	var steps := []
	var key := "" # Aquí guardaremos la clave
	
	var sequence_array := []
	
	# La principal diferencia: Usamos una PILA (Array actuando como pila)
	var stack: Array[String] = []
	var visited := {} # Usamos un diccionario para 'visited'

	stack.push_back(start) # DFS empieza apilando el nodo inicial
	# NOTA: En este estilo de implementación iterativa, marcamos como visitado
	# justo antes de PROCESAR el nodo (al desapilarlo) o al APILARLO,
	# dependiendo de la implementación. Aquí lo marcaremos al apilarlo
	# para evitar procesar el mismo nodo múltiples veces.
	
	# Usaremos un set para registrar nodos que han sido puestos en la pila,
	# pero que aún no han sido visitados/extraídos para su procesamiento.
	visited[start] = true
	
	while not stack.is_empty():
		# Principal diferencia: Extraemos del FINAL (pop_back) para simular una pila (LIFO)
		var current: String = stack.pop_back()
		
		sequence_array.append(current)
		
		# 1. Lógica del Minijuego: Añadir la letra del nodo actual
		key += graph.get_node_letter(current)
		
		
		
		# 2. Registrar el paso de VISITA/EXTRACCIÓN (para resaltar el nodo actual)
		steps.append({
			"type": "visit", 
			"node": current, 
			"letter": graph.get_node_letter(current), # Letra asociada
			"description": "Node %s visited (DFS), letter added to key." % current
		})
		
		# 3. Obtener y ordenar vecinos por el peso de la arista (criterio de selección)
		# NOTA: Para DFS, el orden de procesamiento de vecinos es crucial.
		# Para mantener el mismo orden de recorrido basado en el peso de la arista
		# (menor a mayor), pero garantizar que el de MENOR peso sea el
		# PRÓXIMO en ser extraído (LIFO), debemos apilar los vecinos en ORDEN INVERSO.
		var neighbors = graph.get_neighbors(current).duplicate()
		# Ordenar por peso (menor a mayor)
		neighbors.sort_custom(func(a, b): return a.capacity < b.capacity)
		
		# 4. Procesar los vecinos ordenados, ¡en orden INVERSO!
		# Recorremos la lista ordenada de forma inversa para que el vecino con
		# el peso MÁS PEQUEÑO sea el último en ser apilado y, por lo tanto, el
		# PRIMERO en ser extraído en la siguiente iteración (comportamiento LIFO).
		for i in range(neighbors.size() - 1, -1, -1):
			var edge = neighbors[i]
			var nid: String = edge["to"]
			
			if not visited.has(nid):
				# Se marca como visitado/en-pila
				visited[nid] = true 
				stack.push_back(nid) # Apilar
				
				# 5. Registrar el paso de APILAR (Otros datos para la visualización)
				var edge_weight: float = 1.0
				
				if edge.has("capacity"):
					edge_weight =edge.capacity
				elif edge.has("weight"):
					edge_weight = edge.weight
				
				steps.append({
					"type": "enqueue", # Mantenemos 'enqueue' pero se entiende que es 'push' a la pila
					"node": nid, 
					"from_node": current, # Nodo de origen (para resaltar la arista)
					"edge_weight": edge_weight, # Peso de la arista (útil para mostrar)
					"frontier": stack.duplicate(), # Estado actual de la pila
					"description": "Neighbor %s pushed onto stack via edge with weight %.1f." % [nid, edge_weight]
				})
	steps.append({
					"type": "finish_path",
					"path": sequence_array, # Array de nodos
					"description": "Recorrido finalizado."
				})
	return {"key": key, "steps": steps}
