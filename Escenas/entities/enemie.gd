extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var health: int = 100

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()

func die():
	print("El enemigo ha muerto.")
	
	# --- ¡AQUÍ ESTÁ LA MAGIA! ---
	# Avisamos al GameManager para que recoja la letra del nivel actual
	World.game_manager.on_boss_killed()
	
	# Animación de muerte, drops, etc.
	queue_free()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
