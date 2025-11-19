# res://scripts/core/Graph.gd
extends Resource
class_name Graph

# 'adj' guarda las conexiones (aristas)
var adj := {} # key: node_id (String), value: Array of {to: String, capacity: float, flow: float, id: String}
var nodes_data := {}

func _init():
	adj.clear()
	nodes_data.clear() # limpiamos las listas y los diccionarios  

func add_node(id: String, data:Dictionary = {})-> void:
	if not adj.has(id):
		adj[id] = []
		nodes_data[id] = data

# Función de ayuda para obtener datos de un nodo
func get_node_data(node_id: String) -> Dictionary:
	return nodes_data.get(node_id, {})

# Función de ayuda para obtener la letra de un nodo
func get_node_letter(node_id: String) -> String:
	var node_data_dict = nodes_data.get(node_id, {})
	return node_data_dict.get("letter","?")

func add_edge(a: String, b: String, capacity: float = 10.0, edge_id: String = "") -> void:
	if edge_id == "":
		edge_id = "%s-%s" % [a, b]
	if not adj.has(a): add_node(a)
	if not adj.has(b): add_node(b)
	
	# Arista A -> B
	adj[a].append({
		"to": b, 
		"capacity": capacity, 
		"flow": 0.0, 
		"residual_capacity": capacity, 
		"id": edge_id
	})
	
	# Arista B -> A (CORRECCIÓN: Usar 'capacity' en lugar de 0.0)
	# También corregí un error tipográfico: "residiual_capacity" -> "residual_capacity"
	adj[b].append({
		"to": a, 
		"capacity": capacity, # <--- ¡Aquí estaba el 0.0! Pon 'capacity'.
		"flow": 0.0, 
		"residual_capacity": capacity, # <--- También aquí, inicializar con capacidad total.
		"id": edge_id
	})
func reset_flow():
	for u in adj.keys():
		for edge in adj[u]:
			edge.flow = 0.0 
			edge.residual_capacity = edge.capacity -edge.flow

func get_neighbors(node_id: String) -> Array:
	return adj.get(node_id, [])

func nodes() -> Array:
	return adj.keys()
