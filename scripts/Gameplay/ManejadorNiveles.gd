# res://scripts/core/Gameplay/ManejadorNiveles.gd
extends Node

const GraphGenerator = preload("res://scripts/core/GeneradorGrafo.gd")
var graph: Graph = null

var map_nodes = ["level_0", "level_1", "level_2","level_3"]

func _ready():
	randomize() 
	print("ManejadorNiveles listo. Generando mapa del mundo...")
	graph = GraphGenerator.generate_connected_random_graph(map_nodes, 2)
	# ELIMINA ESTA LÍNEA: emit_signal("request_load_level", "level_0")
	print("ManejadorNiveles: Grafo generado y listo.") # Nuevo print

func get_connections_for(level_name: String) -> Array:
	if graph:
		return graph.get_neighbors(level_name)
	return []
