# res://scripts/gameplay/MissionController.gd
extends Node
class_name MissionController

#Señales
signal algorithm_steps_ready(steps) 
signal path_found(path_array) 
signal mst_found(edges_array) 
signal max_flow_found(flow_value)
signal network_tracer_key_ready(key)


# Algoritmos Network Tracer (Minijuego 1) 
const BFS_Algoritmo = preload("res://scripts/core/Algoritmos/BFS.gd")
const DFS_Algoritmo = preload("res://scripts/core/Algoritmos/DFS.gd")
# ------------------------------------------------------------------------

# Algoritmo Safe Route (Minijuego 2)
const DIJKSTRA_Algoritmo = preload("res://scripts/core/Algoritmos/Dijkstra.gd")
#-------------------------------------------------------------------------

#Algoritmo RebuildNet (Minijuego 3)
const PRIM_Algoritmo = preload("res://scripts/core/Algoritmos/Prim.gd")
#-------------------------------------------------------------------------

#Algoritmo FlowControl (Minijuego 4)
const FORD_Algoritmo = preload("res://scripts/core/Algoritmos/FordFulkerson.gd")


var graph_ref: Graph = null

func start_mission_bfs(graph_inst: Graph, start_node: String):
	graph_ref = graph_inst
	var result = BFS_Algoritmo.run(graph_ref, start_node)
	emit_signal("network_tracer_key_ready", result)



func start_mission_dfs(graph_inst: Graph, start_node:String):
	graph_ref = graph_inst
	var result =DFS_Algoritmo.run(graph_ref,start_node)

	emit_signal("algorithm_steps_ready", result["steps"])
	emit_signal("network_tracer_key_ready", result)



func start_mission_dijkstra(graph_inst: Graph, start_node: String, end_node: String):
	graph_ref = graph_inst
	
	var result = DIJKSTRA_Algoritmo.run(graph_inst, start_node, end_node)
	
	# 1. Emitir pasos para visualización
	emit_signal("algorithm_steps_ready", result.steps)
	
	# 2. Emitir el camino más corto encontrado (para lógica del juego)
	emit_signal("path_found", result.path)


#arbol de expansión mínimo 
func start_mission_prim(graph_inst: Graph):
	graph_ref = graph_inst
	var result = PRIM_Algoritmo.run(graph_inst)
	
	# 1. Emitir pasos para visualización
	emit_signal("algorithm_steps_ready", result.steps)
	
	# 2. Emitir las aristas que forman el MST para la lógica de reconstrucción
	emit_signal("mst_found", result.edges)



func start_mission_fort(graph_inst: Graph, source_node: String, sink_node: String):
	graph_ref = graph_inst
	var ford_fulkerson_inst = FORD_Algoritmo.new() # Instanciar si no es estático
	var result = ford_fulkerson_inst.find_max_flow(graph_inst, source_node, sink_node)
	
	# 1. Emitir pasos para visualización
	emit_signal("algorithm_steps_ready", result.steps)
	
	# 2. Emitir el flujo máximo encontrado (usa 'max_flow_found' y 'max_flow')
	emit_signal("max_flow_found", result.max_flow)
