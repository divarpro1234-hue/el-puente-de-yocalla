extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var pact_area: Area2D = $PactArea
@onready var pact_prompt: Label = $PactArea/PactPrompt
@onready var satanas: Node2D = $Satanas
@onready var satanas_dialogue: Label = $Satanas/DialogueText
@onready var guardian: Node2D = $Guardian
@onready var objective_label: Label = $ObjectiveHUD/ObjectiveLabel
@onready var rooster_event_label: Label = $ObjectiveHUD/RoosterEventLabel
@onready var bridge_parts: Array[Polygon2D] = [
	$ZonaRioPuente/BridgeZone/BridgeConstruction/BridgePart_01,
	$ZonaRioPuente/BridgeZone/BridgeConstruction/BridgePart_02,
	$ZonaRioPuente/BridgeZone/BridgeConstruction/BridgePart_03,
]
@onready var bridge_collision_shapes: Array[CollisionShape2D] = [
	$ZonaRioPuente/BridgeZone/BridgeConstruction/BridgeCollision_01/CollisionShape2D,
	$ZonaRioPuente/BridgeZone/BridgeConstruction/BridgeCollision_02/CollisionShape2D,
	$ZonaRioPuente/BridgeZone/BridgeConstruction/BridgeCollision_03/CollisionShape2D,
]
@onready var construction_timer: Timer = $ZonaRioPuente/BridgeZone/BridgeConstruction/ConstructionTimer
@onready var outcome_timer: Timer = $OutcomeTimer

var player_inside_pact_area: bool = false
var pact_completed: bool = false
var bridge_construction_started: bool = false
var next_bridge_part_index: int = 0
var outcome_sequence_started: bool = false
var outcome_stage: int = 0


func _ready() -> void:
	objective_label.text = "Objetivo: Encuentra una forma de cruzar el río"
	objective_label.show()
	pact_prompt.hide()
	rooster_event_label.hide()
	pact_area.body_entered.connect(_on_pact_area_body_entered)
	pact_area.body_exited.connect(_on_pact_area_body_exited)
	construction_timer.timeout.connect(_on_construction_timer_timeout)
	outcome_timer.timeout.connect(_on_outcome_timer_timeout)


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
		_start_outcome_sequence()


func _start_outcome_sequence() -> void:
	if outcome_sequence_started:
		return
	outcome_sequence_started = true
	guardian.call(&"reveal")
	outcome_timer.start()


func _on_outcome_timer_timeout() -> void:
	if outcome_stage == 0:
		rooster_event_label.show()
		outcome_stage = 1
		outcome_timer.start()
	elif outcome_stage == 1:
		satanas.hide()
		satanas_dialogue.hide()
		_enable_bridge_collisions()
		objective_label.text = "Objetivo: Cruza el Puente de Yocalla"
		outcome_stage = 2


func _enable_bridge_collisions() -> void:
	for collision_shape: CollisionShape2D in bridge_collision_shapes:
		collision_shape.disabled = false


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
