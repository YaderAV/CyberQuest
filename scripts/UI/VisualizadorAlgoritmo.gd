# res://scripts/ui/AlgorithmVisualizer.gd
extends Control
class_name AlgorithmVisualizer

@export var highlight_time := 0.5

# --- Paleta de colores inspirada en la imagen ---
const COLOR_HOT_LAVA = Color("#ffb439")
const COLOR_SENSOR_RED = Color("#ff4f4f")
const COLOR_ACTIVE_GREEN = Color("#aade40")
const COLOR_NEUTRAL = Color.WHITE


func visualize_steps(steps: Array) -> void:
	# Llamar con await para animación paso a paso
	async_visualize(steps)

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
		"extract_min":
			_highlight_node(step.node)
		"relax":
			_indicate_relax(step.from, step.to)
		"add_edge":
			_highlight_edge(step.edge)
		"augment":
			_flow_animate(step.from, step.to, step.flow)
		_:
			pass

# ====================================================================
# --- Implementación de Animaciones ---
# ====================================================================

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
	var node_a = _get_node_visual(a)
	var node_b = _get_node_visual(b)
	if not (is_instance_valid(node_a) and is_instance_valid(node_b)): return

	# Crea una partícula de 'lava'
	var particle := ColorRect.new()
	particle.color = COLOR_HOT_LAVA
	particle.size = Vector2(10, 10)
	particle.position = node_a.position + (node_a.size / 2.0) # Centrado
	add_child(particle)
	
	# Mueve la partícula de A a B y luego la destruye
	var tween := create_tween()
	tween.tween_property(particle, "position", node_b.position + (node_b.size / 2.0), highlight_time * 0.9)
	tween.tween_callback(particle.queue_free)

# ====================================================================
# --- Funciones de Ayuda (¡Necesitas implementar esto!) ---
# ====================================================================

# NOTA: Estas funciones son placeholders. Debes adaptarlas a
# cómo tu escena 'AlgorithmVisualizer' almacena u obtiene
# las referencias a los nodos y aristas visuales.

func _get_node_visual(node_id) -> Control:
	"""
	Obtiene el nodo de UI (Panel, ColorRect, etc.) que representa
	un nodo del grafo (ej: "Level_0").
	"""
	# Asume que los nodos visuales son hijos de este Control
	# y se llaman igual que el ID del nodo.
	if has_node(str(node_id)):
		return get_node(str(node_id))
	print_debug("No se pudo encontrar el nodo visual: %s" % node_id)
	return null

func _get_edge_visual(node_a, node_b) -> Node:
	"""
	Obtiene el nodo de UI (Line2D, TextureRect, etc.) que representa
	la arista (portal) entre dos nodos del grafo.
	"""
	# Asume que las aristas se nombran "ID1-ID2" o "ID2-ID1"
	var name_a = "%s-%s" % [node_a, node_b]
	var name_b = "%s-%s" % [node_b, node_a]
	
	if has_node(name_a):
		return get_node(name_a)
	if has_node(name_b):
		return get_node(name_b)
		
	print_debug("No se pudo encontrar la arista visual: %s <-> %s" % [node_a, node_b])
	return null
