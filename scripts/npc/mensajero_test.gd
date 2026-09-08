extends Node2D

signal return_mission_assigned

var interaction_enabled: bool = false
var player_inside: bool = false
var mission_was_assigned: bool = false

@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var dialogue_text: Label = $DialogueText


func _ready() -> void:
	hide()
	interaction_prompt.hide()
	dialogue_text.hide()
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func enable_interaction() -> void:
	interaction_enabled = true
	show()
	interaction_prompt.visible = player_inside


func _process(_delta: float) -> void:
	if interaction_enabled and player_inside and Input.is_action_just_pressed(&"interact"):
		interaction_prompt.hide()
		dialogue_text.show()
		if not mission_was_assigned:
			mission_was_assigned = true
			return_mission_assigned.emit()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == &"Player":
		player_inside = true
		interaction_prompt.visible = interaction_enabled


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == &"Player":
		player_inside = false
		interaction_prompt.hide()
		dialogue_text.hide()
