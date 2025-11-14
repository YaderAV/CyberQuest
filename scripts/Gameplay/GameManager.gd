# res://scripts/gameplay/GameManager.gd
extends Node
class_name GameManager

# --- Referencias principales ---
@onready var level_container: Node = $LevelContainer
@onready var mission_controller: Node = $MissionController
@onready var algorithm_visualizer: Node = $CanvasLayer/VisualizadorAlgoritmo
@onready var player_scene := preload("res://Escenas/entities/player.tscn")

# --- Estado global ---
var current_level: Node = null
var player: Node = null
var current_node_id: String = ""
var current_graph: Graph = null
var transitioning := false

# --- Inicialización ---
func _ready():
	pass 
func start_game():
	print("GameManager: Iniciando el juego...")
	current_graph = ManejadorNiveles.graph

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
		
		# ¡Configuramos el destino del portal!
		portal_node.target_node = target_node
		portal_node.active = true
		
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

	transitioning = false
	print("Nivel cargado:", node_id)

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
func start_mission_bfs():
	print("Iniciando misión BFS...")
	mission_controller.start_mission_bfs(current_graph, current_node_id)
	mission_controller.connect("algorithm_steps_ready", Callable(self, "_on_algorithm_steps_ready"),CONNECT_ONE_SHOT)

func start_mission_dijkstra():
	print("Iniciando misión Dijkstra...")
	mission_controller.start_mission_dijkstra(current_graph, current_node_id)
	mission_controller.connect("algorithm_steps_ready", Callable(self, "_on_algorithm_steps_ready"), CONNECT_ONE_SHOT)

func start_mission_kruskal():
	print("Iniciando misión Kruskal...")
	mission_controller.start_mission_kruskal(current_graph)
	mission_controller.connect("algorithm_steps_ready", Callable(self, "_on_algorithm_steps_ready"), CONNECT_ONE_SHOT)

func start_mission_flow():
	print("Iniciando misión Ford-Fulkerson...")
	mission_controller.start_mission_flow(current_graph, "Level_0", "Level_5")
	mission_controller.connect("algorithm_steps_ready", Callable(self, "_on_algorithm_steps_ready"), CONNECT_ONE_SHOT)

# --- Visualización del algoritmo ---
func _on_algorithm_steps_ready(steps: Array) -> void:
	algorithm_visualizer.visualize_steps(steps)
