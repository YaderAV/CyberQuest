# res://scripts/gameplay/MissionController.gd
extends Node
class_name MissionController

var current_algo = null
var graph_ref: Graph = null

func start_mission_bfs(graph_inst: Graph, start_node: String):
	graph_ref = graph_inst
	current_algo = preload("res://scripts/core/Algoritmos/BFS.gd").new()
	var steps = current_algo.run(graph_ref, start_node)
	emit_signal("algorithm_steps_ready", steps)

# Define señales en la cabecera si quieres (visualizer se conecta a ellas)
signal algorithm_steps_ready(steps)
	
