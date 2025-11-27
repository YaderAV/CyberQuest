extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	# 1. Espera a que el Autoload 'World' emita su señal "ready".
	await World.ready
	
	# 2. AHORA es seguro llamar a start_game(),
	#    porque sus variables @onready ya están cargadas.
	get_tree().change_scene_to_file("res://Escenas/UI/Menú.tscn")
	#World.start_game()
	
	# 3. Esta escena 'boot' ya cumplió su misión. La destruimos.
	queue_free()
