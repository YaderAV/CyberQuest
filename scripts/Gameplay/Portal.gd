# res://scripts/gameplay/Portal.gd
extends Area2D
class_name Portal

# Esta señal la escucha el GameManager
signal portal_activated(target_node_id)

# Esta variable la CONFIGURA el GameManager
@export var target_node: String = "" 

@export var active: bool = true
@onready var animationPlayer = $AnimationPlayer

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	
	# Actualizar la animación según el estado (activo o no)
	if active:
		animationPlayer.play("idle")
	else:
		animationPlayer.play("disabled") # (Si tienes esta animación)

func _on_body_entered(body):
	# Si no estoy activo o ya estamos transicionando, no hacer nada
	if not active or get_tree().get_first_node_in_group("GameManager").transitioning:
		return

	# Si el cuerpo que entró es el jugador...
	if body is Player:
		print("Portal: Jugador detectado! Emitiendo señal para %s" % target_node)
		
		# ...¡Emitir la señal! GameManager se encargará del resto.
		emit_signal("portal_activated", target_node)
