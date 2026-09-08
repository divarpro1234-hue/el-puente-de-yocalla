extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var pact_area: Area2D = $PactArea
@onready var pact_prompt: Label = $PactArea/PactPrompt
@onready var satanas: Node2D = $Satanas
@onready var objective_label: Label = $ObjectiveHUD/ObjectiveLabel
@onready var bridge_parts: Array[Polygon2D] = [
	$ZonaRioPuente/BridgeZone/BridgeConstruction/BridgePart_01,
	$ZonaRioPuente/BridgeZone/BridgeConstruction/BridgePart_02,
	$ZonaRioPuente/BridgeZone/BridgeConstruction/BridgePart_03,
]
@onready var construction_timer: Timer = $ZonaRioPuente/BridgeZone/BridgeConstruction/ConstructionTimer

var player_inside_pact_area: bool = false
var pact_completed: bool = false
var bridge_construction_started: bool = false
var next_bridge_part_index: int = 0


func _ready() -> void:
	objective_label.text = "Objetivo: Encuentra una forma de cruzar el río"
	objective_label.show()
	pact_prompt.hide()
	pact_area.body_entered.connect(_on_pact_area_body_entered)
	pact_area.body_exited.connect(_on_pact_area_body_exited)
	construction_timer.timeout.connect(_on_construction_timer_timeout)


func _unhandled_input(event: InputEvent) -> void:
	if pact_completed or not player_inside_pact_area:
		return
	if event.is_action_pressed(&"interact"):
		pact_completed = true
		pact_prompt.hide()
		satanas.call(&"reveal")
		objective_label.text = "Objetivo: Observa la construcción del puente"
		_start_bridge_construction()
		get_viewport().set_input_as_handled()


func _start_bridge_construction() -> void:
	if bridge_construction_started:
		return
	bridge_construction_started = true
	bridge_parts[0].show()
	next_bridge_part_index = 1
	construction_timer.start()


func _on_construction_timer_timeout() -> void:
	if next_bridge_part_index >= bridge_parts.size():
		construction_timer.stop()
		return
	bridge_parts[next_bridge_part_index].show()
	next_bridge_part_index += 1
	if next_bridge_part_index == bridge_parts.size():
		construction_timer.stop()
		objective_label.text = "Objetivo: Observa el desenlace del pacto"


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
