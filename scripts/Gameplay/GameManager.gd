# res://scripts/gameplay/GameManager.gd
extends Node
class_name GameManager


# --- Referencias principales ---
@onready var level_container: Node = $LevelContainer
@onready var algorithm_visualizer: Node = $UI/VisualizadorAlgoritmo
@onready var player_scene := preload("res://Escenas/entities/player.tscn")
@onready var counter_label: Label = $UI/CounterLabel

# --- Estado global ---
var current_algorithm_name: String = ""
var current_level: Node = null
var player: Node = null
var current_node_id: String = ""
var current_graph: Graph = null
var transitioning := false
var is_computer_open = false
var reconstructed_edges := {}
var is_reconstruction_mode := false
var final_graph: Graph= null
var current_final_stage: int = 0
var collected_letters_string: String = ""
var MAX_FINAL_STAGES = 4 # BFS, Dijkstra, Prim, Flow
var current_mission_index: int = 0
var dijkstra_target_node: String = ""
var reconstruction_target: Array = []
var unlocked_nodes: Dictionary = {} 
const MISSION_FLOW = [
	"NetworkTracer", # Minijuego 1 (BFS/DFS)
	"SafeRoute",     # Minijuego 2 (Dijkstra)
	"RebuildNet",    # Minijuego 3 (Prim/MST)
	"FlowControl",   # Minijuego 4 (Ford-Fulkerson)
	"FinalCombat"    # Minijuego 5 (Boss Final + Challenge)
]


# --- Inicialización ---
func _ready():
	pass 
	
	
	
func start_game():
	print("GameManager: Iniciando el juego...")
	current_graph = ManejadorNiveles.graph
	unlocked_nodes.clear()
	
	collected_letters_string = "" # Reiniciar al empezar juego nuevo
	algorithm_visualizer.update_collected_clues(collected_letters_string)
	
	# --- DEBUGGING 1: ¿Está fallando el JUGADOR? ---
	print("start_game: Comprobando 'player_scene'...")
	if player_scene == null:
		print("¡ERROR FATAL! player_scene es null. Revisa el preload() en GameManager.")
		return # Detener la función aquí
	
	print("start_game: 'player_scene' cargada. Instanciando...")
	player = player_scene.instantiate()
	add_child(player)
	print("start_game: Jugador instanciado con éxito.")
	# --- FIN DEBUGGING 1 ---
	
	_load_level("level_0")
# --- Cargar nivel ---
func _load_level(node_id: String) -> void:
	if transitioning:
		return
	transitioning = true

	# Eliminar nivel anterior
	if current_level:
		current_level.queue_free()

	# Cargar escena del nuevo nivel
	var scene_path = "res://Escenas/Niveles/%s.tscn" % node_id
	var new_scene = load(scene_path)
	if not new_scene:
		push_warning("No se encontró la escena del nodo: %s" % node_id)
		transitioning = false
		return
	current_level = new_scene.instantiate()
	$LevelContainer.add_child(current_level)
	current_node_id = node_id

	 # --- INICIO DEL ACOPLAMIENTO LÓGICA <-> ESCENA ---
	
	if is_instance_valid(algorithm_visualizer):
			algorithm_visualizer.update_nodes_visual_state(current_node_id, unlocked_nodes)
	
	# 1. Obtenemos las conexiones LÓGICAS del grafo
	var logical_connections = ManejadorNiveles.get_connections_for(node_id)
	
	# 2. Obtenemos los portales FÍSICOS de la escena
	var physical_portals = []
	var number_portals = 0
	for child in current_level.get_children():
		if child is Portal: # Buscamos por la class_name 'Portal'
			physical_portals.append(child)
			number_portals = number_portals +1
			print("portal agregado: ", number_portals)
	
	
	
	print("  > Conexiones lógicas encontradas: %d" % logical_connections.size())
	print("  > Portales físicos encontrados: %d" % physical_portals.size())
	# --- FIN DE DEBUGGING ---
	# 3. Asignamos CADA portal físico a una conexión lógica
	print("GameManager: Configurando portales para %s..." % node_id)
	for i in range(min(logical_connections.size(), physical_portals.size())):
		var portal_node: Portal = physical_portals[i]
		var connection_data: Dictionary = logical_connections[i]
		
		var target_node = connection_data["to"]
		# Crear ID de la arista para verificar estado
		var dest_letter = current_graph.get_node_letter(target_node)
		
		var id_parts = [node_id, target_node]
		id_parts.sort()
		var edge_id = "%s-%s" % [id_parts[0], id_parts[1]]
		# Asignamos el mapa a este portal
		portal_node.current_node = node_id
		portal_node.destination_letter = dest_letter # <--- ASIGNAR LA LETRA
		# ¡Configuramos el destino del portal!
		portal_node.target_node = target_node
		portal_node.active = true
		
		if portal_node.has_method("_update_visuals"):
			portal_node._update_visuals()
		
		if is_reconstruction_mode:
			# Si estamos en modo reconstrucción, el estado depende de si ya lo arreglamos.
			# Si el ID no está en el diccionario, es false (roto) por defecto.
			var is_fixed = reconstructed_edges.get(edge_id, false)
			
			portal_node.active = is_fixed 
			
			# Feedback visual según estado
			if is_fixed:
				portal_node.modulate = Color.WHITE
				# portal_node.animationPlayer.play("idle")
			else:
				portal_node.modulate = Color(0.5, 0.5, 0.5)
				# portal_node.animationPlayer.play("disabled")
		else:
			# Modo normal (Minijuegos 1, 2, 4)
			portal_node.active = true
			portal_node.modulate = Color.WHITE
		
		# Conectamos la señal del portal a NUESTRA función
		portal_node.connect("portal_activated", Callable(self, "_on_portal_activated"))
		print("  > Portal %d conectado a: %s" % [i, target_node])
	
	# (Opcional) Desactivar portales que sobren
	for i in range(logical_connections.size(), physical_portals.size()):
		physical_portals[i].active = false
		
	# --- FIN DEL ACOPLAMIENTO ---
	# Instanciar o reposicionar al jugador
	if not player:
		player = player_scene.instantiate()
		add_child(player)
	_position_player_at_spawn(current_level)
	
	
	current_node_id = node_id # Asegúrate de actualizar esto
	transitioning = false
	print("Nivel cargado:", node_id)
	# --- VERIFICACIÓN DE MISIÓN 2 ---
	if is_instance_valid(algorithm_visualizer):
		algorithm_visualizer.update_player_position_on_map(current_node_id)
	
	_check_dijkstra_arrival()

func _update_reconstruction_counter():
	if not is_instance_valid(counter_label): return
	
	# Calcular cuántos faltan
	var total = reconstruction_target.size()
	var fixed_count = 0
	
	# Contar cuántos están en 'true' en el diccionario
	for edge_id in reconstructed_edges:
		if reconstructed_edges[edge_id] == true:
			fixed_count += 1
			
	var remaining = total - fixed_count
	
	# Actualizar texto y color
	counter_label.text = "ENERGÍA INESTABLE - PORTALES RESTANTES: %d" % remaining
	
	if remaining == 0:
		counter_label.modulate = Color.GREEN
	else:
		counter_label.modulate = Color.YELLOW
		
	counter_label.show()

func on_enemy_killed():
	print("¡Enemigo derrotado en %s!" % current_node_id)
	
	# 1. Registrar que este nodo ya fue "limpiado"
	unlocked_nodes[current_node_id] = true
	
	# 2. Obtener la letra (solo para feedback en consola o HUD)
	var letter = current_graph.get_node_letter(current_node_id)
	print("Pista obtenida: %s" % letter)
	
	# 3. Actualizar el minimapa en tiempo real (si está abierto o para la próxima vez)
	# (Opcional: Mostrar un mensaje flotante en el juego)

func _check_dijkstra_arrival():
	if MISSION_FLOW[current_mission_index] == "SafeRoute" and dijkstra_target_node != "":
		if current_node_id == dijkstra_target_node:
			print("¡LLEGASTE AL DESTINO SEGURO!")
			dijkstra_target_node = "" 
			
			await get_tree().create_timer(1.0).timeout
			
			# --- ¡AQUÍ ESTÁ EL PROBLEMA POTENCIAL! ---
			# Asegúrate de que estas líneas NO estén comentadas y se ejecuten
			current_mission_index += 1
			_nemesis_destroys_portals()

func start_next_mission() -> void:
	# 1. Avanzar el índice
	current_mission_index += 1
	
	if current_mission_index >= MISSION_FLOW.size():
		print("¡Juego Completado!")
		return

	var next_mission = MISSION_FLOW[current_mission_index]
	print("\n>>> INICIANDO SIGUIENTE MISIÓN: %s <<<" % next_mission)
	
	match next_mission:
		"SafeRoute":
			# Minijuego 2: Se inicia automáticamente al terminar el 1.
			# Opcional: Esperar unos segundos o mostrar un diálogo antes.
			await get_tree().create_timer(2.0).timeout
			start_mission_dijkstra()
			
		"RebuildNet":
			# Minijuego 3: Se inicia tras completar la ruta segura
			# (Aquí iría la animación de NEMESIS destruyendo portales)
			_nemesis_destroys_portals()
			
		"FlowControl":
			# Minijuego 4
			start_mission_flow()
			
		"FinalCombat":
			# Cargar nivel final
			_load_level("nemesis_lair")

func on_boss_killed():
	# 1. Obtener la letra del nodo (mapa) actual
	if current_graph == null: return
	
	var letter = current_graph.get_node_letter(current_node_id)
	
	# 2. Evitar duplicados (opcional, si puedes volver a matar al jefe)
	# Si quieres que la clave se arme en orden de muerte, simplemente agrégala:
	
	print("¡Jefe derrotado en %s! Letra obtenida: %s" % [current_node_id, letter])
	
	collected_letters_string += letter
	
	# 3. Actualizar la UI
	algorithm_visualizer.update_collected_clues(collected_letters_string)
	
	# (Opcional) Mostrar un mensaje en pantalla tipo "¡Letra 'A' obtenida!"

#Procesar entradas del jugador
func _input(event):
	# Solo permite ABRIR si está CERRADO y no ocupado
	if event.is_action_pressed("open_computer")  and not transitioning:
		self.computer_visible = !self.computer_visible # ¡Esto llama al 'setter'!
		get_viewport().set_input_as_handled()


var computer_visible: bool = false:
	set(value):
		computer_visible = value
		if computer_visible:
			# Estado ABRIR:
			print("SETTER: Abriendo menú")
			algorithm_visualizer.show_selection_menu()
		else:
			# Estado CERRAR:
			print("SETTER: Ocultando todo")
			algorithm_visualizer.hide_all_panels()
			# También reseteamos el bloqueo de animación, por si acaso
		

# --- Cambio de nivel por portal ---
func _on_portal_activated(target_node: String) -> void:
	if not current_graph.adj.has(target_node):
		push_warning("Nodo destino inválido: %s" % target_node)
		return
	print("Transición: %s -> %s" % [current_node_id, target_node])
	_load_level(target_node)

# --- Posicionar jugador ---
func _position_player_at_spawn(level: Node) -> void:
	var spawn := level.get_node_or_null("SpawnPoint")
	if spawn:
		player.global_position = spawn.global_position
	else:
		player.global_position = Vector2(100, 100)  # fallback

# --- Solicitud de cambio desde LevelManager ---
func _on_request_load_level(node_id: String) -> void:
	_load_level(node_id)

# --- Control de misiones ---

# Minjuego 1: Network Tracer
func start_mission_bfs():
	print("Iniciando misión BFS...")
	self.computer_visible = false
	current_algorithm_name = "BFS" # <-- GUARDAMOS EL NOMBRE
	
	MController.connect("network_tracer_key_ready", Callable(self, "_on_network_key_ready"), CONNECT_ONE_SHOT)
	MController.start_mission_bfs(current_graph, current_node_id)

func start_mission_dfs():
	print("Iniciando misión DFS...")
	self.computer_visible = false
	current_algorithm_name = "DFS" # <-- GUARDAMOS EL NOMBRE
	
	MController.connect("network_tracer_key_ready", Callable(self, "_on_network_key_ready"), CONNECT_ONE_SHOT)
	MController.start_mission_dfs(current_graph, current_node_id)
	
	
func _on_network_key_ready(result: Dictionary):
	
	# 1. Extraer los datos (pasos y clave)
	var steps = result.get("steps", [])
	var key = result.get("key", "ERROR_NO_KEY")
	
	print("Clave %s generada: %s" % [current_algorithm_name, key]) 
	
	if steps.is_empty() or key == "ERROR_NO_KEY":
		push_warning("Resultado de la misión inválido.")
		return
		
	# 2. (Paso 3) MOSTRAR Y ANIMAR EL MINIMAPA
	print("Clave recibida. Iniciando visualización...")
	algorithm_visualizer.generate_and_show_graph(current_graph)
	
	# ¡ESPERA ('await') a que la animación termine!
	await algorithm_visualizer.async_visualize(steps)
	
	# 3. (Paso 4) MOSTRAR LA TERMINAL (DESPUÉS de la espera)
	print("Visualización completada. Mostrando terminal...")
	var correct_data = {"key": key}
	algorithm_visualizer.show_challenge_terminal("ETAPA 1: RECORRIDO | INGRESA LA CLAVE")
	algorithm_visualizer.prompt_for_solution("Recorrido", correct_data)
	
	# 4. Conectar el "Submit"
	algorithm_visualizer.connect("solution_submitted", Callable(self, "_on_minigame1_solution_submitted"), CONNECT_ONE_SHOT)

#Minijuego 2: "Safe Route"

func start_mission_dijkstra():
	print("Iniciando misión Dijkstra...")
	
	# 1. Preparar UI
	self.computer_visible = false
	
	# 2. Elegir puntos
	var start_node = current_node_id
	var possible_targets = current_graph.nodes().filter(func(n): return n != start_node)
	if possible_targets.is_empty():
		push_warning("No hay nodos destino para Dijkstra.")

		return
	var end_node = possible_targets.pick_random() 
	
	print("Objetivo Dijkstra: Ir de %s a %s" % [start_node, end_node])

	# 3. Conectar señales
	# Para la animación paso a paso
	MController.connect("algorithm_steps_ready", Callable(self, "_on_dijkstra_steps_ready"), CONNECT_ONE_SHOT)
	# Para el resultado final (la ruta)
	MController.connect("path_found", Callable(self, "_on_shortest_path_found"), CONNECT_ONE_SHOT)
	
	MController.start_mission_dijkstra(current_graph, start_node, end_node)
# --- Nuevo Handler para Minijuego 2 ---
func _on_shortest_path_found(path: Array) -> void:
	if path.is_empty():
		print("Dijkstra no encontró un camino válido.")
		return
		
	print("Ruta más corta calculada: ", path)
	
	# 1. Guardar el objetivo final
	dijkstra_target_node = path.back() # El último nodo de la lista
	
	print(">>> OBJETIVO DE MISIÓN: VIAJA FÍSICAMENTE A %s <<<" % dijkstra_target_node)
	
func _on_dijkstra_steps_ready(steps: Array):
	if current_graph == null: return
	
	algorithm_visualizer.generate_and_show_graph(current_graph)
	await algorithm_visualizer.async_visualize(steps)
	
	print("Visualización Dijkstra terminada.")
	# NOTA: Aquí NO mostramos la terminal de "Ingresar Clave".
	# En Dijkstra, el jugador debe moverse físicamente, así que solo desbloqueamos 'E'.
	
	# Opcional: Mostrar en pantalla "¡Ruta calculada! Sigue el camino."
# Minijuego 3: Rebuild Net 	

# Lógica de transición al Minijuego 3 
func _nemesis_destroys_portals():
	print("\n!!! ALERTA !!! NEMESIS HA DESTRUIDO LA RED DE PORTALES.")
	
	# 1. Bloqueo Lógico Global
	is_reconstruction_mode = true 
	
	# 2. Romper los portales de la escena actual
	if current_level:
		for child in current_level.get_children():
			if child is Portal:
				# --- ¡AQUÍ ESTÁ EL CAMBIO CRÍTICO! ---
				child.active = false # <--- Desactivarlos lógicamente
				
				# Feedback Visual
				if child.has_node("AnimationPlayer"):
					child.animationPlayer.play("disabled") 
				child.modulate = Color(0.5, 0.5, 0.5) # Gris/Roto

	# 3. Pausa dramática
	await get_tree().create_timer(2.0).timeout
	
	# 4. Iniciar lógica matemática
	start_mission_prim()
func start_mission_prim():
	print("Iniciando misión PRIM: Reconstrucción de portales")
	MController.connect("mst_found",Callable(self, "_on_mst_found"), CONNECT_ONE_SHOT)
	MController.start_mission_prim(current_graph)
	

func _on_mst_found(mst_edges: Array)->void: 
	print("MST encontrado. Aristas a reconstruir: %d" % mst_edges.size())
	# 1. Almacenar el objetivo de reconstrucción globalmente
	# Esto permite que los nodos Portal.gd accedan a la lista de aristas objetivo.
	World.reconstruction_target = mst_edges
	is_reconstruction_mode = true
	# 2. Inicializar el rastreador de aristas reconstruidas
	reconstructed_edges.clear()
	for current_edge in mst_edges:
		# Crea un ID de arista canónico (ordenado alfabéticamente)
		var id_parts = [current_edge.u, current_edge.v]
		id_parts.sort()
		var edge_id = "%s-%s" % [id_parts[0], id_parts[1]]
		# Inicialmente, ninguna arista está reconstruida
		reconstructed_edges[edge_id] = false 
	# 3. Cargar la UI/Minimapa para mostrar el MST
	# Debes implementar 'show_mst_map' en AlgorithmVisualizer.gd
	algorithm_visualizer.generate_and_show_graph(current_graph, mst_edges)
	print("Minimapa de MST cargado. Presiona [TAB] (o la tecla de UI) para verlo.")
	# 4. Cambiar la dinámica de juego
	World.is_reconstruction_mode = true # Estado global para el ingeniero
	
	_update_reconstruction_counter()
	
	# 5. Informar al jugador (ej. mostrar un mensaje HUD o un pop-up)
	# World.ui_manager.display_message("¡Alerta! Modo Ingeniero activado. Reconstruye los portales usando el MST.")
	
	# NOTA: Los portales ahora deben responder a la interacción del jugador, 
	# conectándose a la lógica 'rebuild_edge' que definiremos a continuación.


func rebuild_edge(node_a: String, node_b: String) -> bool:
	if not World.is_reconstruction_mode:
		return false # No estamos en el modo correcto
	# 1. Crear el ID canónico de la arista
	var id_parts = [node_a, node_b]
	id_parts.sort()
	var edge_id = "%s-%s" % [id_parts[0], id_parts[1]]
	# 2. Verificar si es una arista del MST y si ya fue reconstruida
	if not reconstructed_edges.has(edge_id):
		# No es una arista del MST
		print("Intento de conexión fallido: La arista %s no está en el MST." % edge_id)
		return false
	if reconstructed_edges[edge_id]:
		# Ya reconstruida
		print("Arista %s ya está activa." % edge_id)
		return true
	# 3. Reconstrucción exitosa
	reconstructed_edges[edge_id] = true
	
	_update_reconstruction_counter()
	
	print("¡Arista %s reconstruida con éxito! Peso: %s" % [edge_id, "Desconocido (Buscar en MST)"])
	
	# Opcional: Notificar al portal que ahora debe estar funcional
	# (El portal se activa solo)
	# 4. Verificar si la misión ha terminado
	if _check_reconstruction_complete():
		_end_minigame_3()
	
	return true


func _check_reconstruction_complete() -> bool:
	# Retorna true si TODAS las aristas en el rastreador son 'true'
	for id in reconstructed_edges:
		if reconstructed_edges[id] == false:
			return false
	return true


func _end_minigame_3() -> void:
	print("--- ¡MINIJUEGO 3 COMPLETO! ÁRBOL DE EXPANSIÓN RECONSTRUIDO ---")
	World.is_reconstruction_mode = false
	
	# Opcional: Limpiar el minimapa del visualizador
	# algorithm_visualizer.hide()
	
	if is_instance_valid(counter_label):
		counter_label.hide()
	
	# Llamar al Minijuego 4: Flow Control (Ford-Fulkerson)
	start_mission_flow()

#Minijuego 4: Flow Control

func start_mission_flow():
	print("Iniciando Minijuego 4: Flow Control (Ford-Fulkerson)...")
	
	# 1. ¡BLOQUEAR INTERACCIÓN! Queremos que el jugador mire la pantalla.
	self.computer_visible = false
	
	var source_node = "level_0"
	# Intentamos buscar un nodo lejano si es posible
	var possible_sinks = current_graph.nodes().filter(func(n): return n != source_node)
	var sink_node = possible_sinks.pick_random() if not possible_sinks.is_empty() else "level_1"
	
	print("Objetivo Flujo: %s -> %s" % [source_node, sink_node])

	# 2. CONECTAR EL VISUALIZADOR
	# Creamos una función específica para ver la animación de flujo
	MController.connect("algorithm_steps_ready", Callable(self, "_on_flow_visual_ready"), CONNECT_ONE_SHOT)
	
	# 3. CONECTAR EL FINAL
	MController.connect("max_flow_found", Callable(self, "_on_max_flow_found"), CONNECT_ONE_SHOT)
	
	MController.start_mission_fort(current_graph, source_node, sink_node)

# --- NUEVO HANDLER VISUAL ---
func _on_flow_visual_ready(steps: Array):
	print("Visualizando Flujo de Datos...")
	
	# 1. Generar el mapa
	algorithm_visualizer.generate_and_show_graph(current_graph)
	
	# 2. Mostrar el mensaje PERO mantener el mapa visible (true)
	# Esto permite ver la animación detrás o al lado del panel.
	algorithm_visualizer.show_challenge_terminal("ESTABILIZANDO RED... OPTIMIZANDO FLUJO", true)
	
	# Desactivar input porque este minijuego es automático
	algorithm_visualizer.submit_button.disabled = true
	algorithm_visualizer.input_line.editable = false
	
	# 3. Ejecutar la animación (ahora se verá porque el mapa sigue ahí)
	await algorithm_visualizer.async_visualize(steps)
	
	print("Flujo estabilizado.")
	# La transición final ocurrirá en _on_max_flow_found
	# (Nota: No cerramos aquí, esperamos a _on_max_flow_found para la transición)
func _on_max_flow_found(flow_value: float) -> void:
	print("Flujo Máximo establecido: %.1f. NEMESIS AISLADO." % flow_value)
	
	# Esperar un momento para ver el resultado final
	await get_tree().create_timer(2.0).timeout
	
	# Cerrar visualización
	self.computer_visible = false
	
	# AVANZAR AL FINAL
	# (Aquí cargaríamos el nivel del jefe final)
	print(">>> TRANSICIÓN A COMBATE FINAL <<<")
	# _load_level("nemesis_lair") # Descomenta esto cuando tengas la escena

func start_final_reconstruction() -> void:
	print("--- INICIANDO MINIJUEGO FINAL: RECONSTRUCCIÓN DEL SISTEMA CENTRAL ---")
	
	# 1. Generar una nueva red aleatoria para el desafío
	var final_nodes = ["Core_A", "Core_B", "Core_C", "Core_D", "Core_E"] # Nodos para la fase final
	final_graph = ManejadorNiveles.GraphGenerator.generate_connected_random_graph(final_nodes, 4)
	
	# 2. Inicializar el estado de la misión
	current_final_stage = 0
	
	# 3. Mostrar la interfaz del visualizador
	algorithm_visualizer.show_final_challenge_ui() # Nueva función en el visualizador
	
	# 4. Iniciar la primera etapa
	_next_final_stage()

func _next_final_stage() -> void:
	current_final_stage += 1
	var start_node = final_graph.nodes().pick_random() # Origen aleatorio para cada etapa
	
	match current_final_stage:
		1:
			print("ETAPA 1: RECORRIDO (BFS/DFS)")
			# Pedir al jugador que escoja BFS o DFS como al inicio
			algorithm_visualizer.prompt_algorithm_choice("Recorrido")
			# NOTA: Necesitarás un handler aquí para que la elección del jugador llame a start_final_stage_algorithm
		2:
			print("ETAPA 2: CAMINO MÍNIMO (DIJKSTRA)")
			_start_final_stage_algorithm("Dijkstra", start_node)
		3:
			print("ETAPA 3: RECONSTRUCCIÓN (PRIM)")
			_start_final_stage_algorithm("Prim", start_node)
		4:
			print("ETAPA 4: FLUJO MÁXIMO (FORD-FULKERSON)")
			_start_final_stage_algorithm("Flow", start_node)
		_:
			_end_final_minigame()

# Minijuego 5: The core (Todos los algoritmos)

func _start_final_stage_algorithm(algo_name: String, start_node: String, end_node: String = "") -> void:
	# Simulación: Ejecutar el algoritmo y obtener la solución correcta
	var correct_solution = {}
	
	match algo_name:
		"BFS":
			correct_solution = MController.BFS_Algoritmo.run(final_graph, start_node)
		"DFS":
			correct_solution = MissionController.DFS_Algoritmo.run(final_graph, start_node)
		"Dijkstra":
			var sink = final_graph.nodes().filter(func(n): return n != start_node).pick_random()
			correct_solution = MissionController.DIJKSTRA_Algoritmo.run(final_graph, start_node, sink)
		"Prim":
			correct_solution = MissionController.PRIM_Algoritmo.run(final_graph)
		"Flow":
			# ETAPA 4: Flujo Máximo
			var sink = final_graph.nodes().filter(func(n): return n != start_node).pick_random()
			
			# 1. Llamar al MissionController para ejecutar Ford-Fulkerson
			MController.start_mission_fort(final_graph, start_node, sink)
			
			# 2. La lógica de Ford-Fulkerson es asíncrona (con visualización). 
			# Nos conectamos a su resultado final para obtener la respuesta correcta.
			MController.connect("max_flow_found", 
								 Callable(self, "_on_final_flow_result_ready").bind(algo_name), 
								 CONNECT_ONE_SHOT)
			
			# Regresa temprano para esperar la visualización y la señal
			return 
		_:
			return

	algorithm_visualizer.show_challenge_map(final_graph)
	
	# Mostrar los pasos del algoritmo para que el jugador infiera la respuesta (¡la clave!)
	algorithm_visualizer.visualize_steps(correct_solution.steps) 
	
	# Esperar la entrada del jugador (la respuesta)
	algorithm_visualizer.prompt_for_solution(correct_solution)
	
	# Conectar la señal que el jugador emite cuando cree tener la respuesta
	algorithm_visualizer.connect("solution_submitted", Callable(self, "_verify_final_solution"), CONNECT_ONE_SHOT)

func _on_final_flow_result_ready(flow_value: float, algo_name: String) -> void:
	# 1. Construir el objeto de solución basado en el valor de flujo recibido
	var correct_data: Dictionary = {
		"max_flow": flow_value
	}
	
	# 2. Notificar al visualizador que muestre la terminal y pida la respuesta
	algorithm_visualizer.show_challenge_terminal("ETAPA 4: FLUJO MÁXIMO | INFIERE EL VALOR")
	algorithm_visualizer.prompt_for_solution("Flow", correct_data)

# El visualizador debe enviar el tipo de misión y la respuesta del jugador.
func _verify_final_solution(mission_type: String, player_answer: String, correct_data: Dictionary) -> void:
	var is_correct = false
	
	# La verificación dependerá del tipo de misión:
	match mission_type:
		"BFS", "DFS":
			# Comprobar si la clave (string) ingresada es correcta
			is_correct = (player_answer == correct_data.key)
		"Dijkstra":
			# Comprobar si el nodo destino es el correcto
			# Esto puede ser complejo, se recomienda que el jugador solo elija el nodo final.
			is_correct = (player_answer == correct_data.path.back())
		"Prim":
			# Comprobar si el número de aristas seleccionadas es correcto
			is_correct = (int(player_answer) == correct_data.edges.size())
		"Flow":
			# Comprobar si el valor del flujo máximo ingresado es correcto
			is_correct = (abs(float(player_answer) - correct_data.max_flow) < 0.1) # Tolerancia de flotantes
	
	if is_correct:
		print("✅ ETAPA %d COMPLETA." % current_final_stage)
		_next_final_stage() # Pasar a la siguiente etapa
	else:
		print("❌ ETAPA FALLIDA. NEMESIS corrompe más datos.")
		# Lógica de penalización o repetición
		pass

func _end_final_minigame():
	print("--- ¡VICTORIA TOTAL! HAS DERROTADO A NEMESIS Y SELLADO LA BRECHA ---")
	# Mostrar escena final y créditos
	get_tree().quit()

# El visualizador llama a esta función cuando el jugador hace clic en BFS o DFS
func start_final_stage_algorithm_choice(algo_name: String) -> void:
	var start_node = final_graph.nodes().pick_random()
	var mission_type = ""
	
	# Después de la elección, forzamos la Etapa 1 a usar ese algoritmo
	if algo_name == "BFS":
		mission_type = "BFS"
	elif algo_name == "DFS":
		mission_type = "DFS"
	
	# Reejecutamos la etapa con el algoritmo elegido
	_start_final_stage_algorithm(mission_type, start_node)

func _on_minigame1_solution_submitted(mission_type: String, player_answer: String, correct_data: Dictionary):
	
	# Normalizar respuesta (mayúsculas/minúsculas)
	var is_correct = (player_answer.to_upper() == correct_data.key.to_upper())
	
	if is_correct:
		print("¡CLAVE CORRECTA! Minijuego 1 completado.")
		algorithm_visualizer.display_feedback(true, "CLAVE CORRECTA. ACCESO CONCEDIDO.")
		
		# Espera para ver el feedback
		await get_tree().create_timer(1.5).timeout 
		
		# 1. CERRAR EL MENÚ ACTUAL
		self.computer_visible = false 
		
		# 2. ¡ACTIVAR LA PROGRESIÓN!
		# Verifica que estemos en la misión correcta antes de avanzar
		if MISSION_FLOW[current_mission_index] == "NetworkTracer":
			start_next_mission() # Esto llamará a start_mission_dijkstra()
		
	else:
		print("Clave incorrecta.")
		algorithm_visualizer.display_feedback(false, "CLAVE INCORRECTA. Intenta de nuevo.")
		# Reconectar para permitir otro intento
		algorithm_visualizer.connect("solution_submitted", Callable(self, "_on_minigame1_solution_submitted"), CONNECT_ONE_SHOT)
# ... (Función placeholder en AlgorithmVisualizer.gd)
# ...
func prompt_algorithm_choice(mission_type: String):
	# Oculta la terminal y muestra los botones BFS/DFS 
	# CONECTANDO SUS SEÑALES A World.game_manager.start_final_stage_algorithm_choice
	pass

# --- Visualización del algoritmo ---

	# CORRECCIÓN: Usa la nueva variable
	
