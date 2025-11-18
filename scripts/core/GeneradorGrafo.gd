# res://scripts/core/Algorithms/GraphGenerator.gd
extends RefCounted

# Esta función es 'static', se llama usando el nombre de la clase
# Crea y DEVUELVE un grafo ya configurado.
static func generate_connected_random_graph(nodes: Array, num_extra_portals: int) -> Graph:
	
	# IMPORTANTE: Carga la clase Graph aquí
	var graph = Graph.new() # Crea la instancia DENTRO de la función

	# --- 0. Validación y preparación ---
	if nodes.size() < 2:
		return graph # Devuelve el grafo vacío
		
	for map_name in nodes:
		graph.add_node(map_name)

	# --- 1. Garantizar conectividad ---
	var visited = []
	var unvisited = nodes.duplicate()
	var current_map = unvisited.pick_random()
	unvisited.erase(current_map)
	visited.append(current_map)
	
	while not unvisited.is_empty():
		var from_map = visited.pick_random()
		var to_map = unvisited.pick_random()
		
		graph.add_edge(from_map, to_map, 1)
		graph.add_edge(to_map, from_map, 1)
		
		unvisited.erase(to_map)
		visited.append(to_map)

	# --- 2. Añadir atajos aleatorios (Ciclos) ---
	# ... (El resto de tu código de generación) ...
	# ...
	
	print("Grafo conectado generado por GraphGenerator.")
	
	# Devuelve el grafo terminado
	return graph
