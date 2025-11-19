# res://scripts/ui/AlgorithmVisualizer.gd
extends Control
class_name AlgorithmVisualizer

@export var highlight_time := 0.5

# --- Paleta de colores inspirada en la imagen ---
const COLOR_HOT_LAVA = Color("#ffb439")
const COLOR_SENSOR_RED = Color("#ff4f4f")
const COLOR_ACTIVE_GREEN = Color("#aade40")
const COLOR_NEUTRAL = Color.WHITE
const NODE_VISUAL = preload("res://Escenas/UI/NodeVisual.tscn")
const EDGE_VISUAL = preload("res://Escenas/UI/EdgeVisual.tscn")
const NODE_POSITIONS = {
	"level_0": Vector2(0.2, 0.3),  # 20% del ancho, 30% del alto
	"level_1": Vector2(0.5, 0.15), # 50% del ancho, 15% del alto
	"level_2": Vector2(0.8, 0.3),  # 80% del ancho, 30% del alto
	"level_3": Vector2(0.5, 0.7),  # 50% del ancho, 70% del alto
	# ... (ajusta tus otros nodos como "Core_A", "Core_B" a valores entre 0 y 1)
	"Core_A": Vector2(0.15, 0.15),
	"Core_B": Vector2(0.5, 0.15),
	"Core_C": Vector2(0.85, 0.15),
	"Core_D": Vector2(0.3, 0.7),
	"Core_E": Vector2(0.7, 0.7),
}

signal solution_submitted(mission_type, player_answer, correct_data)

@onready var terminal_panel: Control = $TerminalPanel # Panel donde se muestra el desafío
@onready var challenge_label: Label = $TerminalPanel/ChallengeLabel # Texto de la misión (Etapa 1: Recorrido)
@onready var input_line: LineEdit = $TerminalPanel/InputLine# Campo de texto para la respuesta del jugador
@onready var submit_button: Button = $TerminalPanel/SubmitButton# Botón para enviar la respuesta
@onready var feedback_label: Label = $TerminalPanel/FeedbackLabel# Mensaje de éxito/error
@onready var clue_label: Label = $Panel/ClueLabel
@onready var bfs_button = $Panel/BFS_BUTTON
@onready var dfs_button = $Panel/DFS_BUTTON
@onready var close_button = $Panel/Close_button
@onready var selection_panel:Control = $Panel
@onready var minimap_container: Control = $MinimapContainer


var current_challenge_type: String = ""
var current_correct_data: Dictionary = {}



func prompt_for_solution(mission_type: String, correct_data: Dictionary) -> void:
	# 1. Almacena ambos argumentos
	current_correct_data = correct_data
	current_challenge_type = mission_type # <-- Usar el nuevo argumento
	
	# 2. La lógica de inferencia se vuelve más simple:
	# Si la estás llamando con "Flow", no necesitas inferir que es "Flow" de nuevo.
	
	# 3. Actualizar la lógica condicional (ya que ahora recibes 'mission_type')
	
	var challenge_text = ""
	match mission_type:
		"BFS", "DFS","Recorrido":
			challenge_text = "ETAPA: RECORRIDO (Clave de Letras) | INGRESA LA CLAVE"
		"Dijkstra":
			challenge_text = "ETAPA: CAMINO MÍNIMO | INGRESA EL NODO DESTINO FINAL"
		"Prim":
			challenge_text = "ETAPA: RECONSTRUCCIÓN | INGRESA EL NÚMERO DE ARISTAS DEL MST"
		"Flow":
			challenge_text = "ETAPA: FLUJO MÁXIMO | INGRESA EL VALOR DE FLUJO MÁXIMO"
		_:
			challenge_text = "Error de misión."

	challenge_label.text = challenge_text
	
	input_line.clear()
	input_line.editable = true
	submit_button.disabled = false
	feedback_label.text = "Esperando entrada..."

# Función para manejar el botón de envío
func _on_submit_button_pressed():
	if not current_challenge_type.is_empty():
		submit_button.disabled = true
		input_line.editable = false
		var player_answer = input_line.text.strip_edges()
		
		# Emitir la señal al GameManager para la verificación
		emit_signal("solution_submitted", current_challenge_type, player_answer, current_correct_data)
	else:
		feedback_label.text = "Error: Sin desafío activo."

# Función para que el GameManager actualice el estado de la UI
func display_feedback(success: bool, message: String):
	feedback_label.text = message
	if success:
		feedback_label.modulate = COLOR_ACTIVE_GREEN
	else:
		feedback_label.modulate = COLOR_SENSOR_RED
		submit_button.disabled = false # Permitir reintento
		input_line.editable = true

func show_final_challenge_ui() -> void:
	self.show()
	if is_instance_valid(selection_panel):
		selection_panel.hide() # Ocultamos la selección BFS/DFS inicial
		
	if is_instance_valid(terminal_panel):
		terminal_panel.show()
		
		# Conexión del botón de envío
		submit_button.pressed.connect(Callable(self, "_on_submit_button_pressed"))
		input_line.clear()
		feedback_label.text = "Iniciando la secuencia final de sellado..."

func _ready():
	#conectamos las señales a los botones
	bfs_button.pressed.connect(Callable(self, "_on_bfs_button_pressed"))
	dfs_button.pressed.connect(Callable(self, "_on_dfs_button_pressed"))
	close_button.pressed.connect(Callable(self, "_on_close_button_pressed"))
	submit_button.pressed.connect(Callable(self,"_on_submit_button_pressed"))
	update_collected_clues("")
	
	# Escondemos el UI del visualizador de algoritmos 
	if is_instance_valid(terminal_panel):
		terminal_panel.hide()
	
	hide()


func update_collected_clues(current_clues: String):
	if is_instance_valid(clue_label):
		if current_clues.is_empty():
			clue_label.text = "Claves recolectadas: (Ninguna)"
		else:
			clue_label.text = "Claves recolectadas: %s" % current_clues
# Función específica para la Etapa 1 (Recorrido) del Minijuego 5
func prompt_algorithm_choice(mission_type: String):
	# Mostramos los botones de BFS/DFS de nuevo
	if is_instance_valid(selection_panel):
		selection_panel.show()
	
	challenge_label.text = "ETAPA 1: RECORRIDO | ELIGE el algoritmo para generar la clave."
	
	# Desconectamos los botones de sus misiones del Minijuego 1 (CONNECT_ONE_SHOT ayuda)
	# y los re-conectamos a la lógica del Minijuego 5.
	
	# Desconectar temporalmente la lógica del Minijuego 1 si no usas CONNECT_ONE_SHOT
	# bfs_button.pressed.disconnect(...)
	
	# ⚠️ Conectamos a la función que inicia la etapa final con el algoritmo elegido.
	# Esta función debe existir en el GameManager.
	bfs_button.pressed.connect(Callable(World.game_manager, "start_final_stage_algorithm_choice").bind("BFS"), CONNECT_ONE_SHOT)
	dfs_button.pressed.connect(Callable(World.game_manager, "start_final_stage_algorithm_choice").bind("DFS"), CONNECT_ONE_SHOT)


# Función llamada desde el GameManager después de la elección BFS/DFS o para otras etapas

func show_challenge_terminal(challenge_info: String, keep_map_visible: bool = false):
	print("--- DEBUG (Visualizer): Mostrando Terminal Panel ---")
	
	if is_instance_valid(selection_panel):
		selection_panel.hide()
		
	# MODIFICACIÓN AQUÍ:
	if is_instance_valid(minimap_container):
		# Solo limpiamos y ocultamos si NO queremos mantenerlo visible
		if not keep_map_visible:
			for child in minimap_container.get_children():
				child.queue_free()
			minimap_container.hide()
		# Si keep_map_visible es true, el mapa se queda ahí.
	
	if is_instance_valid(terminal_panel):
		terminal_panel.show()
	else:
		push_warning("Visualizador: TerminalPanel es nulo.")
		return
	
	challenge_label.text = challenge_info
	input_line.clear()
	input_line.editable = true
	submit_button.disabled = false
	feedback_label.text = "..."

# Esta función se llama cuando presionas "E" (para ABRIR)
func show_selection_menu():
	# 1. Muestra el nodo raíz
	self.show() 
	
	# 2. Muestra el panel de selección
	if is_instance_valid(selection_panel):
		selection_panel.show()
		
	# 3. ¡LIMPIEZA! Oculta los otros paneles
	if is_instance_valid(terminal_panel):
		terminal_panel.hide()
		
	if is_instance_valid(minimap_container):
		# Borra el grafo antiguo
		for child in minimap_container.get_children():
			child.queue_free()
		minimap_container.hide()

# Esta función se llama cuando presionas "Cerrar" (para CERRAR)
func hide_all_panels():
	if is_instance_valid(selection_panel):
		selection_panel.hide()
	if is_instance_valid(terminal_panel):
		terminal_panel.hide()
	if is_instance_valid(minimap_container):
		# Borra el grafo antiguo
		for child in minimap_container.get_children():
			child.queue_free()
		minimap_container.hide()
	
	# Oculta el nodo raíz
	self.hide()
func _on_bfs_button_pressed():
	print("DEBUG: BOTNO BFS PRESIONADO")
	# Pedir al GameManager que inicie la misión BFS
	World.start_mission_bfs()
	

func _on_dfs_button_pressed():
	print("DEBUG: BOTON DFS PRESIONADO")
	# Pedir al GameManager que inicie la misión DFS
	World.start_mission_dfs() # Debes crear esta función en GameManager
	

func _on_close_button_pressed():
	# Pedir al GameManager que maneje el cierre y la despausa del juego.
	print("--- DEBUG: BOTÓN CERRAR PRESIONADO. Cerrando interfaz... ---")
	# GameManager ya tiene la lógica para alternar el estado (toggle)
	
	World.computer_visible =false
	get_viewport().set_input_as_handled()

func visualize_steps(steps: Array) -> void:
	var correct_key = ""
	for step in steps:
		var node_id = step["node_id"]
		var letter = step["letter"]
		correct_key += letter
		# ... (Aquí va tu lógica de animación y visualización del nodo)
	# 2. Mostrar clave correcta (para que el jugador la ingrese)
	print("CLAVE CORRECTA (para debug): ", correct_key)
	# 3. Mostrar la interfaz de terminal para que el jugador la ingrese
	show_terminal_input(correct_key)

func show_terminal_input(correct_key:String):
	pass

func async_visualize(steps):
	for s in steps:
		_apply_step(s)
		await get_tree().create_timer(highlight_time).timeout

func _apply_step(step: Dictionary) -> void:
	match step.get("type",""):
		"visit":
			_highlight_node(step.node)
		"enqueue":
			_pulse_node(step.node)
			if step.has("from_node"):
				_indicate_candidate_edge(step.from_node, step.node)
		"extract_min":
			_highlight_node(step.node)
		"relax":
			_indicate_relax(step.from, step.to)
		"add_edge":
			_highlight_edge({"u": step.u, "v": step.v})
		"discard": 
			_discard_edge(step.edge[0], step.edge[1])
		"augment": # <--- Verifica que esto coincida con tu script FordFulkerson
			# FordFulkerson envía: path, flow, from, to.
			# Asegúrate de usar las claves correctas:
			if step.has("from") and step.has("to"):
				_flow_animate(step.from, step.to, step.flow)
			else:
				# Si FordFulkerson envía un 'path' array, tomamos el primero y el último para animar el salto general
				# O iteramos sobre el path (más complejo). 
				# Tu script FordFulkerson actual YA ENVÍA 'from' y 'to', así que esto debería funcionar.
				pass
		"finish_path": 
			_animate_path_result(step)
		_:
			pass


# --- Implementación de Animaciones ---

func generate_and_show_graph(graph: Graph, edges_to_highlight: Array = []) -> void:
	# Oculta el menú de selección si aún está visible
	if is_instance_valid(selection_panel):
		selection_panel.hide()
	# Oculta la terminal (Minijuego 5)
	if is_instance_valid(terminal_panel):
		terminal_panel.hide()
	# Muestra el contenedor del minimapa
	minimap_container.show()
	self.show()
	
	print("Visualizador: Generando grafo dinámicamente.")
	
	# 1. Limpiar dibujos anteriores
	for child in minimap_container.get_children():
		child.queue_free()
	
	var container_size = minimap_container.size
	if container_size.x == 0 or container_size.y == 0:
		push_warning("MinimapContainer tiene tamaño 0. No se puede dibujar.")
		return # Evita errores si el contenedor no está listo aún
	
	# 2. Generar Nodos
	# 2. Generar Nodos
	var node_visuals = {}
	for node_id in graph.nodes():
		var node_visual: Control = NODE_VISUAL.instantiate()
		node_visual.name = node_id 
		
		# Posición (tu código actual)
		var pos = NODE_POSITIONS.get(node_id, Vector2(0.5, 0.5))
		node_visual.position = Vector2(pos.x * container_size.x, pos.y * container_size.y)
		
		minimap_container.add_child(node_visual)
		node_visuals[node_id] = node_visual
		
		# 1. Obtener la letra desde el grafo
		var letter = graph.get_node_letter(node_id)
		
		# 2. Pasarle la información al nodo visual
		# (Verifica que el nodo tenga el método antes de llamarlo para evitar errores)
		if node_visual.has_method("set_node_info"):
			node_visual.set_node_info(node_id, letter)
		
		# (Si usabas la lógica anterior de buscar "Label" manualmente, bórrala,
		#  es mejor usar la función del paso 1).

	# 3. Generar Aristas (Portales)
	var processed_edges = {} # Evitar dibujar la arista doblemente (a->b y b->a)
	for u in graph.nodes():
		for edge_data in graph.get_neighbors(u):
			var v = edge_data.to
			
			# Crear un ID canónico (ordenado alfabéticamente)
			var id_parts = [u, v]
			id_parts.sort()
			var edge_canonical_id = "%s-%s" % [id_parts[0], id_parts[1]]
			
			if processed_edges.has(edge_canonical_id):
				continue
			processed_edges[edge_canonical_id] = true
			
			if not node_visuals.has(u) or not node_visuals.has(v): continue
			
			var edge_visual_root: Node2D = EDGE_VISUAL.instantiate()
			edge_visual_root.name = edge_canonical_id # ¡Esencial para que _get_edge_visual funcione!
			
			var edge_line:Line2D = edge_visual_root.get_node("Line2D")
			if not is_instance_valid(edge_line):
				push_warning("No se encontró 'Line2D' hijo en EdgeVisual.tscn")
				continue
			
			# 4. Asignar los puntos al HIJO Line2D
			var start_pos = node_visuals[u].position + (node_visuals[u].size / 2.0)
			var end_pos = node_visuals[v].position + (node_visuals[v].size / 2.0)
			
			# ⚠️ Esto asume que EdgeVisual.tscn es un Line2D
			edge_line.points = PackedVector2Array([
				node_visuals[u].position + (node_visuals[u].size / 2.0), 
				node_visuals[v].position + (node_visuals[v].size / 2.0)
			])
			
			# MOSTRAR EL PESO (WEIGHT/CAPACITY) ---
			var weight_label = edge_visual_root.get_node_or_null("Label")
			if weight_label:
				# Calcular posición media
				var mid_point = (start_pos + end_pos) / 2.0
				weight_label.position = mid_point - (weight_label.size / 2.0) # Centrar el label
				
				# Obtener el valor a mostrar.
				# Para Dijkstra usamos 'weight' (o 'capacity' si reusamos la variable)
				var weight_val = edge_data.get("weight", edge_data.get("capacity", 1.0))
				weight_label.text = str(weight_val)
				
			# ------------------------------------------------
			
			minimap_container.add_child(edge_visual_root)
			
			minimap_container.add_child(edge_visual_root)
			
			

	# 4. Implementar la animación (Esto se hace en el paso de visualización)
	# Por ahora, aseguramos que _get_node_visual y _get_edge_visual funcionen.
	
	# 5. [Opcional] Mostrar el panel de control
	# show_challenge_terminal(...)

func _highlight_node(node_id):
	"""(visit, extract_min) - Un destello 'caliente' como la lava."""
	var node_visual = _get_node_visual(node_id)
	if not is_instance_valid(node_visual): return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Destella a color lava y vuelve a neutral
	tween.tween_property(node_visual, "modulate", COLOR_HOT_LAVA, highlight_time * 0.4)
	tween.tween_property(node_visual, "modulate", COLOR_NEUTRAL, highlight_time * 0.6)

func _pulse_node(node_id):
	"""(enqueue) - Un pulso 'sensor' rojo."""
	var node_visual = _get_node_visual(node_id)
	if not is_instance_valid(node_visual): return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Destella a rojo y también escala un poco para 'pulsar'
	tween.tween_property(node_visual, "modulate", COLOR_SENSOR_RED, highlight_time * 0.4)
	tween.tween_property(node_visual, "modulate", COLOR_NEUTRAL, highlight_time * 0.6)
	
	# Animación de escala en paralelo
	var scale_tween := create_tween()
	scale_tween.set_parallel(true)
	scale_tween.tween_property(node_visual, "scale", Vector2.ONE * 1.1, highlight_time * 0.4)
	scale_tween.tween_property(node_visual, "scale", Vector2.ONE, highlight_time * 0.6)

func _indicate_relax(a, b):
	"""(relax) - Un destello 'caliente' en la arista que se está revisando."""
	var edge_visual = _get_edge_visual(a, b)
	if not is_instance_valid(edge_visual): return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Destella la arista a color lava
	tween.tween_property(edge_visual, "modulate", COLOR_HOT_LAVA, highlight_time * 0.4)
	tween.tween_property(edge_visual, "modulate", COLOR_NEUTRAL, highlight_time * 0.6)

func _highlight_edge(edge_data):
	"""(add_edge) - Fija permanentemente la arista a un color 'activado'."""
	var edge_visual = _get_edge_visual(edge_data.u, edge_data.v)
	if not is_instance_valid(edge_visual): return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	# Fija la arista al color verde (como las vainas de energía)
	tween.tween_property(edge_visual, "modulate", COLOR_ACTIVE_GREEN, highlight_time * 0.8)
	
	# Si tus aristas son Line2D, también podrías engrosarlas:
	if edge_visual is Line2D:
		tween.parallel().tween_property(edge_visual, "width", 8.0, highlight_time * 0.8)

func _flow_animate(a, b, flow):
	"""(augment) - Una 'partícula' de lava fluyendo de A a B."""
	print("DEBUG ANIM: Flujo de %s a %s" % [a, b]) # <-- Debug para confirmar llamada
	
	var node_a = _get_node_visual(a)
	var node_b = _get_node_visual(b)
	
	if not (is_instance_valid(node_a) and is_instance_valid(node_b)): 
		push_warning("No se pudieron encontrar nodos visuales para animación de flujo.")
		return

	# Crea una partícula de 'lava'
	var particle := ColorRect.new()
	particle.color = COLOR_HOT_LAVA # Asegúrate de que este color sea visible (Naranja/Rojo)
	particle.size = Vector2(15, 15) # Un poco más grande para verla bien
	
	# Centrar la partícula en el nodo de origen
	# Como ambos (nodo y partícula) serán hijos de 'minimap_container', usamos position local.
	particle.position = node_a.position + (node_a.size / 2.0) - (particle.size / 2.0)
	
	# CORRECCIÓN CRÍTICA: Añadir al contenedor del mapa, no a la raíz
	minimap_container.add_child(particle) 
	
	# Calcular destino (Centro del nodo B)
	var target_pos = node_b.position + (node_b.size / 2.0) - (particle.size / 2.0)
	
	# Mueve la partícula de A a B y luego la destruye
	var tween := create_tween()
	tween.tween_property(particle, "position", target_pos, highlight_time * 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(particle.queue_free)

func _get_node_visual(node_id) -> Control:
	"""Obtiene el nodo visual del grafo."""
	# Buscar el nodo visual como hijo del contenedor del minimapa
	return minimap_container.get_node_or_null(str(node_id))

func _get_edge_visual(node_a, node_b) -> Node:
	"""Obtiene la arista visual (Line2D) entre dos nodos."""
	var name_a = "%s-%s" % [node_a, node_b]
	var name_b = "%s-%s" % [node_b, node_a]
	
	# Buscar la arista por su nombre canónico en el contenedor
	if minimap_container.has_node(name_a):
		return minimap_container.get_node(name_a)
	if minimap_container.has_node(name_b):
		return minimap_container.get_node(name_b)
		
	return null

func _indicate_candidate_edge(a, b):
	"""
	(enqueue) - Destello suave en la arista que conecta el nodo visitado con el encolado.
	"""
	var edge_visual = _get_edge_visual(a, b)
	if not is_instance_valid(edge_visual): return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Destella la arista a color rojo suave (candidato)
	tween.tween_property(edge_visual, "modulate", COLOR_SENSOR_RED, highlight_time * 0.4)
	tween.tween_property(edge_visual, "modulate", COLOR_NEUTRAL, highlight_time * 0.6)

func _discard_edge(a, b):
	"""
	(discard - Prim/Kruskal) - Animación para aristas descartadas (forman ciclo).
	"""
	var edge_visual = _get_edge_visual(a, b)
	if not is_instance_valid(edge_visual): return
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Parpadeo rápido en color neutro (apagado)
	tween.tween_property(edge_visual, "modulate", Color.GRAY, highlight_time * 0.2)
	tween.tween_property(edge_visual, "modulate", COLOR_NEUTRAL, highlight_time * 0.4)


func _animate_path_result(step: Dictionary):
	"""
	(finish_path) - Animación de la ruta final para BFS/DFS o Dijkstra.
	"""
	var path: Array = step.get("path", [])
	if path.is_empty(): return
	
	print("Animando ruta final: ", path)
	
	# Limpia cualquier tween anterior en los nodos de la ruta
	for node_id in path:
		var node_visual = _get_node_visual(node_id)
		if is_instance_valid(node_visual):
			node_visual.get_tree().create_tween().kill()
			node_visual.modulate = COLOR_NEUTRAL
			
	# Animación secuencial de los nodos y aristas del camino
	var sequence_tween = create_tween()
	sequence_tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	
	for i in range(path.size()):
		var u = path[i]
		
		# Animar el nodo
		var node_visual = _get_node_visual(u)
		if is_instance_valid(node_visual):
			sequence_tween.tween_property(node_visual, "modulate", COLOR_ACTIVE_GREEN, 0.15)
			sequence_tween.tween_property(node_visual, "modulate", COLOR_NEUTRAL, 0.15)
		
		# Animar la arista que lleva al siguiente nodo
		if i < path.size() - 1:
			var v = path[i+1]
			var edge_visual = _get_edge_visual(u, v)
			if is_instance_valid(edge_visual):
				# Fija la arista al color final de la ruta
				sequence_tween.tween_property(edge_visual, "modulate", COLOR_ACTIVE_GREEN, 0.3)
				
				# Si es Line2D, engrosar
				if edge_visual is Line2D:
					sequence_tween.parallel().tween_property(edge_visual, "width", 8.0, 0.3)
