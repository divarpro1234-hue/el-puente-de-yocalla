extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var pact_area: Area2D = $PactArea
@onready var pact_prompt: Label = $PactArea/PactPrompt
@onready var satanas: Node2D = $Satanas
@onready var objective_label: Label = $ObjectiveHUD/ObjectiveLabel

var player_inside_pact_area: bool = false
var pact_completed: bool = false


func _ready() -> void:
	objective_label.text = "Objetivo: Encuentra una forma de cruzar el río"
	objective_label.show()
	pact_prompt.hide()
	pact_area.body_entered.connect(_on_pact_area_body_entered)
	pact_area.body_exited.connect(_on_pact_area_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if pact_completed or not player_inside_pact_area:
		return
	if event.is_action_pressed(&"interact"):
		pact_completed = true
		pact_prompt.hide()
		satanas.call(&"reveal")
		objective_label.text = "Objetivo: Observa la construcción del puente"
		get_viewport().set_input_as_handled()


func _on_pact_area_body_entered(body: Node2D) -> void:
	if body != player or pact_completed:
		return
	player_inside_pact_area = true
	pact_prompt.show()


func _on_pact_area_body_exited(body: Node2D) -> void:
	if body != player:
		return
	player_inside_pact_area = false
	if not pact_completed:
		pact_prompt.hide()
