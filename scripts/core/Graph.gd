# res://scripts/core/Graph.gd
extends Resource
class_name Graph

# Usa lista de adyacencia (cambia a matriz si prefieres)
var adj := {}    # key: node_id (String), value: Array of {to: String, weight: float, id: String}

func _init():
	adj.clear()

func add_node(id: String) -> void:
	if not adj.has(id):
		adj[id] = []

func add_edge(a: String, b: String, weight: float = 1.0, edge_id: String = "") -> void:
	if edge_id == "":
		edge_id = "%s-%s" % [a, b]
	if not adj.has(a): add_node(a)
	if not adj.has(b): add_node(b)
	adj[a].append({"to": b, "weight": weight, "id": edge_id})
	adj[b].append({"to": a, "weight": weight, "id": edge_id})  # grafo no dirigido

func get_neighbors(node_id: String) -> Array:
	return adj.get(node_id, [])

func nodes() -> Array:
	return adj.keys()
