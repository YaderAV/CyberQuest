# res://scripts/core/Algoritmos/Kruskal.gd
extends RefCounted
class_name Kruskal


var parent := {}

func find(x):
	while parent[x] != x:
		# Compresión de caminos (Path Compression)
		parent[x] = parent[parent[x]]
		x = parent[x]
	return x

func union(a, b) -> bool:
	var root_a = find(a)
	var root_b = find(b)
	
	if root_a != root_b:
		# Si están en conjuntos diferentes, los une
		parent[root_a] = root_b
		return true # Devuelve 'true' si se realizó una unión
		
	return false # Devuelve 'false' si ya estaban en el mismo conjunto

# La función principal
func run(graph: Graph) -> Dictionary:
	# --- 1. CONSTRUIR LISTA DE ARISTAS ---
	var edges := {}
	for u in graph.nodes():
		for e in graph.get_neighbors(u):
			var id = e["id"]
			if not edges.has(id):
				edges[id] = {"u": u, "v": e["to"], "w": e["weight"], "id": id}
	
	var elist := edges.values()
	
	elist.sort_custom(_sort_by_weight)
	
	# --- 2. INICIALIZAR DISJOINT SET ---
	parent.clear() # Limpia el 'parent' de ejecuciones anteriores
	for n in graph.nodes(): 
		parent[n] = n

	# --- 3. EJECUTAR KRUSKAL ---
	var mst := []
	var steps := []
	
	for e in elist:
		# Ahora la lógica de 'find' y 'union' está en la función 'union'
		if union(e.u, e.v):
			# Si 'union' devolvió 'true', significa que conectó dos conjuntos
			mst.append(e)
			steps.append({"type":"add_edge", "edge": e})
			
	return {"steps": steps, "mst": mst}

# 6. CORRECCIÓN: La función de ordenamiento debe devolver un booleano
func _sort_by_weight(a, b) -> bool:
	return a["w"] < b["w"]
