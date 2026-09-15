extends Node2D

signal collectible_collected(collectible_type: String, amount: int)

@export_enum("apple", "herb", "water") var collectible_type: String = "apple"
@export_range(1, 99, 1) var amount: int = 1

var player_inside: bool = false
var was_collected: bool = false

@onready var interaction_area: Area2D = $InteractionArea
@onready var collision_shape: CollisionShape2D = $InteractionArea/CollisionShape2D
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var apple_visual: Node2D = $VisualRoot/AppleVisual
@onready var herb_visual: Node2D = $VisualRoot/HerbVisual
@onready var water_visual: Node2D = $VisualRoot/WaterVisual


func _ready() -> void:
	interaction_prompt.hide()
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	_update_visual()


func _process(_delta: float) -> void:
	if player_inside and not was_collected and Input.is_action_just_pressed(&"interact"):
		_collect()


func _collect() -> void:
	if was_collected:
		return
	was_collected = true
	player_inside = false
	interaction_prompt.hide()
	interaction_area.set_deferred(&"monitoring", false)
	collision_shape.set_deferred(&"disabled", true)
	collectible_collected.emit(collectible_type, amount)
	hide()


func _update_visual() -> void:
	apple_visual.visible = collectible_type == "apple"
	herb_visual.visible = collectible_type == "herb"
	water_visual.visible = collectible_type == "water"


func _on_body_entered(body: Node2D) -> void:
	if was_collected:
		return
	if body is CharacterBody2D and body.name == &"Player":
		player_inside = true
		interaction_prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == &"Player":
		player_inside = false
		interaction_prompt.hide()
