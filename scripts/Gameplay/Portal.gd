# res://scripts/gameplay/Portal.gd
extends Area2D
class_name Portal

signal portal_activated(target_node_id)

@export var target_node: String = ""
@export var current_node: String = "" 
@export var active: bool = true

@onready var animationPlayer = $AnimationPlayer

var player_in_range: bool = false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	
	_update_visuals()

func _update_visuals():
	if active:
		animationPlayer.play("idle")
		modulate = Color.WHITE
	else:
		animationPlayer.play("disabled")
		modulate = Color(0.5, 0.5, 0.5) # Gris para indicar roto

# --- DETECCIÓN DE TECLA ---
func _input(event):
	# Solo intentamos reparar si el jugador está en rango y es el modo correcto.
	# IMPORTANTE: NO chequeamos 'and active' aquí, porque queremos reparar los inactivos.
	if player_in_range and World.is_reconstruction_mode and event.is_action_pressed("Interact"):
		
		print("DEBUG: Solicitando reparación para %s -> %s" % [current_node, target_node])
		
		if World.rebuild_edge(current_node, target_node):
			# ÉXITO: Activamos el portal localmente
			active = true
			_update_visuals()
			print("Portal visualmente reparado.")
			get_viewport().set_input_as_handled()

# --- ENTRADA ---
func _on_body_entered(body):
	if not body is Player: return
	
	# 1. ¡ESTO VA PRIMERO! Registramos que el jugador llegó.
	# Si no ponemos esto primero, el 'return' de abajo evitará que se active la interacción.
	player_in_range = true 

	# 2. Bloqueo de Reconstrucción
	# Si estamos en modo reconstrucción Y el portal sigue roto (no activo)...
	if World.is_reconstruction_mode and not active:
		print("Portal roto. Presiona 'F' para reparar.")
		return # <--- Detenemos el teletransporte, PERO 'player_in_range' YA es true.

	# 3. Teletransporte Normal
	if not active or World.transitioning:
		return

	print("Portal: Viajando a %s" % target_node)
	emit_signal("portal_activated", target_node)

# --- SALIDA ---
func _on_body_exited(body):
	if body is Player:
		player_in_range = false
