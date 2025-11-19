# res://scripts/core/GeneradorGrafo.gd
extends RefCounted
class_name GeneradorGrafo


static func generate_connected_random_graph(nodes_list: Array, num_extra_portals: int) -> Graph:
	#Instanciamos el grafo
	var graph = Graph.new()
	# Verificamos que se puedan hacer las conexiones 
	if nodes_list.size() < 2:
		return graph
		
	#Lista de letras disponibles
	var letters = "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ"
	
	# Convertir el String en un Array de caracteres
	var letters_array = []
	for char in letters:
		letters_array.append(char)
		
	# Barajamos las letras
	letters_array.shuffle()
	
	var letter_index = 0
	
	# Añadir nodos con datos (Letras)
	for map_name in nodes_list:
		var node_data = {}
		
		if letter_index < letters_array.size():
			# 3. Asignar la letra desde el array barajado
			node_data["letter"] = letters_array[letter_index]
			letter_index += 1
		else:
			node_data["letter"] = "?"
			
		graph.add_node(map_name, node_data)

	# Garantizar conectividad (Árbol de expansión) 
	var visited = []
	var unvisited = nodes_list.duplicate()
	var current_map = unvisited.pick_random()
	unvisited.erase(current_map)
	visited.append(current_map)
	
	while not unvisited.is_empty():
		var from_map = visited.pick_random()
		var to_map = unvisited.pick_random()
		
		var random_weight = randi_range(1, 10)
		graph.add_edge(from_map, to_map, random_weight)
		
		unvisited.erase(to_map)
		visited.append(to_map)

	# Añadir atajos aleatorios (Ciclos) ---
	var portals_created = 0
	var max_attempts = 50 # Límite de seguridad
	var attempts = 0
	
	while portals_created < num_extra_portals and attempts < max_attempts:
		attempts += 1
		var map_a = nodes_list.pick_random()
		var map_b = nodes_list.pick_random()
		
		# Evitar conectarse a sí mismo
		if map_a == map_b: 
			continue
			
		# Lógica para evitar duplicados
		var already_connected = false
		# Revisamos los vecinos de map_a
		for neighbor_data in graph.get_neighbors(map_a):
			if neighbor_data["to"] == map_b:
				already_connected = true
				break # Si ya lo encontramos, rompemos el bucle
		
		# Si ya están conectados, saltamos este intento
		if already_connected:
			continue
		
			
		# Si llegamos aquí, es una conexión nueva y válida
		var random_capacity = randi_range(1,20) 
		graph.add_edge(map_a, map_b, random_capacity)
		
		portals_created += 1

	print("Grafo conectado generado con letras y pesos aleatorios. (Corregido)")
	
	return graph
