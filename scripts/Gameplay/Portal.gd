# res://scripts/gameplay/Portal.gd
extends Area2D
class_name Portal

signal portal_activated(target_node_id)

@export var target_node: String = ""
@export var current_node: String = "" 
@export var active: bool = true

@onready var animationPlayer = $AnimationPlayer
@onready var info_label = $InfoLabel
var player_in_range: bool = false
var destination_letter: String = ""

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	
	_update_visuals()
	if info_label:
		info_label.hide()
func _update_visuals():
	# Verificar modo ingeniero a través del GameManager
	var is_reconstruction = false
	if World:
		is_reconstruction = World.is_reconstruction_mode

	if active:
		animationPlayer.play("idle")
		modulate = Color.WHITE
		
		# --- LÓGICA DE VISUALIZACIÓN DE DESTINO ---
		if not is_reconstruction:
			# Si estamos en modo normal, mostramos a dónde lleva
			if destination_letter != "" and destination_letter != "?":
				info_label.text = "A Nivel %s [%s]" % [target_node.trim_prefix("level_"), destination_letter]
				info_label.modulate = Color.CYAN # Color distintivo para información
			else:
				# Si no hay letra (enemigo vivo o no asignada), solo mostramos el nivel
				info_label.text = "A Nivel %s" % target_node.trim_prefix("level_")
				info_label.modulate = Color.WHITE
			
			info_label.show()
		else:
			# En modo reconstrucción, si está activo (ya reparado), ocultamos el texto o ponemos "Reparado"
			# Para no saturar, podemos ocultarlo o dejar un mensaje simple.
			info_label.text = "✓ Estable"
			info_label.modulate = Color.GREEN
			info_label.show() 
			
	else:
		# Si está inactivo/roto
		animationPlayer.play("disabled")
		modulate = Color(0.5, 0.5, 0.5)
		# El texto de "Presiona F" se maneja en _on_body_entered para no saturar la pantalla
		# a menos que te acerques.
		info_label.hide()

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
			info_label.text = "Portal Reconstruido"
			info_label.modulate = Color.GREEN
			info_label.show()
			
			# Desaparecer después de 1.5 segundos
			#await get_tree().create_timer(1.5).timeout
			#info_label.hide()
			
			print("Portal visualmente reparado.")
			get_viewport().set_input_as_handled()
		else:
			# --- CASO FALLO (No es parte del MST) ---
			info_label.text = "Conexión Ineficiente"
			info_label.modulate = Color.RED
			info_label.show()
			
			# Volver al mensaje original después de 1 segundo
			await get_tree().create_timer(1.0).timeout
			if player_in_range and not active:
				info_label.text = "Presiona 'F' para reconstruir"
				info_label.modulate = Color.WHITE

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
		# Mostrar el label flotante
		info_label.text = "Presiona 'F' para reconstruir"
		info_label.modulate = Color.WHITE
		info_label.show()
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
		# Ocultar el label si te alejas
		if info_label:
			info_label.hide()
