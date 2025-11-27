# res://scripts/gameplay/Player.gd
extends CharacterBody2D
class_name Player

const SPEED = 350
const JUMP_VELOCITY = -350.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var atacar: bool = false
enum Mode { EXPLORER, TELEPORTER, REPAIR, FLOW }
var mode: int = Mode.EXPLORER
@onready var animationPlayer = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var colission:CollisionShape2D = $WeaponArea/CollisionShape2D

func _on_weapon_area_body_entered(body):
	# DEBUG 1: Ver si el arma está tocando ALGO
	print("¡El arma tocó algo!: ", body.name) 
	
	if body.has_method("take_damage"):
		print(" > El objeto tiene take_damage. Aplicando daño...")
		body.take_damage(10)
	else:
		print(" > El objeto NO es un enemigo (o no tiene el script correcto).")



func _physics_process(delta):
	if not atacar:
		if not is_on_floor():
			velocity.y += gravity * delta
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			
		var direction = Input.get_axis("ui_left","ui_right")
		if direction: 
			velocity.x = direction * SPEED
		else: 
			velocity.x = move_toward(velocity.x, 0 , SPEED)
		move_and_slide()
		animations(direction) 
		if direction == 1: 
			sprite.flip_h = false
		elif direction == -1:
			sprite.flip_h = true
		if Input.is_action_just_pressed("Atacar"):
			atacar= true
	else: 
		move_and_slide()
		animationPlayer.play("attack")
		colission.disabled = false 
		await (animationPlayer.animation_finished)
		atacar = false	
		colission.disabled = true 
func animations(direction):
	if is_on_floor():
		if direction == 0:
			# Si estábamos corriendo, reproducimos "stop"
			if animationPlayer.current_animation == "run":
				animationPlayer.play("stop")
			# Si no estamos ya en "stop" o "idle" (ej. acabamos de aterrizar)
			# reproducimos "idle" directamente.
			elif animationPlayer.current_animation != "stop" and animationPlayer.current_animation != "idle":
				animationPlayer.play("idle")
		else: # direction != 0
			# Solo reproducimos "run" si no está ya en play (evita reiniciarla)
			if animationPlayer.current_animation != "run":
				animationPlayer.play("run")
	else: 
		# (Optimizado para no reiniciar la animación en cada frame)
		if velocity.y < 0:
			if animationPlayer.current_animation != "jump":
				animationPlayer.play("jump")
		else: 
			if animationPlayer.current_animation != "fall":
				animationPlayer.play("fall")



func _on_idle_animation_finished(anim_name: StringName) -> void:
	if anim_name == "stop":
		animationPlayer.play("idle")
