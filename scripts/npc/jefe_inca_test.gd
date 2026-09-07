extends Node2D

var player_inside: bool = false

@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var dialogue_text: Label = $DialogueText


func _ready() -> void:
	interaction_prompt.hide()
	dialogue_text.hide()
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed(&"interact"):
		dialogue_text.show()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == &"Player":
		player_inside = true
		interaction_prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == &"Player":
		player_inside = false
		interaction_prompt.hide()
		dialogue_text.hide()
