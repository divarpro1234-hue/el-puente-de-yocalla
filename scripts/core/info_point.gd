extends Node2D

signal information_collected(info_id: String)

@export var info_id: String = ""

var player_inside: bool = false
var collected: bool = false

@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var collected_label: Label = $CollectedLabel


func _ready() -> void:
	interaction_prompt.hide()
	collected_label.hide()
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if player_inside and not collected and Input.is_action_just_pressed(&"interact"):
		collected = true
		interaction_prompt.hide()
		collected_label.show()
		information_collected.emit(info_id)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == &"Player":
		player_inside = true
		interaction_prompt.visible = not collected
		collected_label.hide()


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body.name == &"Player":
		player_inside = false
		interaction_prompt.hide()
		collected_label.hide()
