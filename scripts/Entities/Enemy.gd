extends CharacterBody2D
class_name Enemy

@export var max_health: int = 30 # Poca vida para probar rápido
var current_health: int

func _ready():
	current_health = max_health
	add_to_group("Enemies") # Opcional, ayuda a identificarlo



func take_damage(amount: int):
	print("Enemigo recibió %d de daño. Vida restante: %d" % [amount, current_health - amount])
	current_health -= amount
	
	# Feedback visual simple (parpadeo rojo)
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	if current_health <= 0:
		die()

func die():
	print("¡Enemigo Murió! Avisando al GameManager...")
	World.on_enemy_killed()
	queue_free()
