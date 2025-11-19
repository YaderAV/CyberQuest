# res://scripts/ui/NodeVisual.gd
extends ColorRect

@onready var label =$ColorRect/Label
# Puedes añadir una función para configurar el nodo
func set_node_info(node_id: String, letter: String = ""):
	if label:
		# Si hay una letra asignada (ej: "A"), muéstrala.
		# Si no (ej: "?"), muestra el ID del nodo (ej: "Level_1") para depuración.
		if letter != "" and letter != "?":
			label.text = letter
		else:
			label.text = node_id
			
		# Opcional: Centrar el texto
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
