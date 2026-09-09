extends Area2D

var active: bool = false

@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if active or not (body is CharacterBody2D and body.name == &"Player"):
		return
	active = true
	CheckpointManager.set_checkpoint(global_position)
	visual.color = Color(0.95, 0.78, 0.28, 1.0)
