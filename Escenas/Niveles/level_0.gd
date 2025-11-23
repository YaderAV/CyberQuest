extends Node2D

@onready var spawn_point: Marker2D = $SpawnPoint


func _on_respawn_body_entered(body: Node2D) -> void:
	if not body is Player: return
	body.global_position = spawn_point.position
