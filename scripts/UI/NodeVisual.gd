# res://scripts/ui/NodeVisual.gd
extends ColorRect

@onready var label =$ColorRect/Label

# Colores de estado
const COLOR_LOCKED = Color(0.3, 0.3, 0.3) # Gris oscuro (Enemigo vivo)
const COLOR_UNLOCKED = Color(0.2, 0.6, 1.0) # Azul (Enemigo muerto / Letra visible)
const COLOR_CURRENT = Color(1.0, 0.8, 0.0) # Dorado/Amarillo (Jugador aquí)

func update_visual(node_id: String, letter: String, is_unlocked: bool, is_current: bool):
	# 1. Lógica de Texto (¿Mostrar letra o incógnita?)
	if is_unlocked:
		label.text = letter
	else:
		label.text = "?" # Oculto hasta matar al enemigo
	
	# 2. Lógica de Color (¿Dónde estoy?)
	if is_current:
		color = COLOR_CURRENT # Resaltar posición del jugador
		# Opcional: Hacerlo un poco más grande
		scale = Vector2(1.2, 1.2)
		z_index = 10 # Ponerlo al frente
	else:
		scale = Vector2(1.0, 1.0)
		z_index = 0
		
		if is_unlocked:
			color = COLOR_UNLOCKED
		else:
			color = COLOR_LOCKED
