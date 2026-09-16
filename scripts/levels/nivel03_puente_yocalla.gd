extends Node2D

const MAIN_MENU_PATH: String = "res://scenes/ui/MainMenu.tscn"

@onready var player: CharacterBody2D = $Player
@onready var pact_area: Area2D = $PactArea
@onready var pact_prompt: Label = $PactArea/PactPrompt
@onready var satanas: Node2D = $Satanas
@onready var satanas_dialogue: Label = $Satanas/DialogueText
@onready var guardian: Node2D = $Guardian
@onready var objective_label: Label = $ObjectiveHUD/ObjectiveLabel
@onready var rooster_event_label: Label = $ObjectiveHUD/RoosterEventLabel
@onready var epilogue_area: Area2D = $ZonaEpilogo/EpilogueArea
@onready var epilogue_text: Label = $ObjectiveHUD/EpilogueText
@onready var final_story_text: Label = $ObjectiveHUD/FinalStoryText
@onready var legend_complete_panel: Control = $ObjectiveHUD/LegendCompletePanel
@onready var return_to_menu_button: Button = $ObjectiveHUD/LegendCompletePanel/ReturnToMenuButton
@onready var exit_button: Button = $ObjectiveHUD/LegendCompletePanel/ExitButton
@onready var bridge_blocker: StaticBody2D = $ZonaRioPuente/BridgeZone/BridgeBlocker
@onready var bridge_blocker_collision: CollisionShape2D = $ZonaRioPuente/BridgeZone/BridgeBlocker/CollisionShape2D
@onready var bridge_blocked_text: Label = $ObjectiveHUD/BridgeBlockedText
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
@onready var final_story_timer: Timer = $FinalStoryTimer
@onready var legend_complete_timer: Timer = $LegendCompleteTimer
@onready var bridge_blocked_message_timer: Timer = $BridgeBlockedMessageTimer

var player_inside_pact_area: bool = false
var pact_completed: bool = false
var bridge_construction_started: bool = false
var next_bridge_part_index: int = 0
var outcome_sequence_started: bool = false
var outcome_stage: int = 0
var epilogue_started: bool = false
var legend_completed: bool = false


func _ready() -> void:
	objective_label.text = "Objetivo: Encuentra una forma de cruzar el río"
	objective_label.show()
	pact_prompt.hide()
	rooster_event_label.hide()
	epilogue_text.hide()
	final_story_text.hide()
	legend_complete_panel.hide()
	return_to_menu_button.pressed.connect(_on_return_to_menu_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	bridge_blocked_text.hide()
	bridge_blocker_collision.disabled = true
	pact_area.body_entered.connect(_on_pact_area_body_entered)
	pact_area.body_exited.connect(_on_pact_area_body_exited)
	epilogue_area.body_entered.connect(_on_epilogue_area_body_entered)
	construction_timer.timeout.connect(_on_construction_timer_timeout)
	outcome_timer.timeout.connect(_on_outcome_timer_timeout)
	final_story_timer.timeout.connect(_on_final_story_timer_timeout)
	legend_complete_timer.timeout.connect(_on_legend_complete_timer_timeout)
	bridge_blocked_message_timer.timeout.connect(_on_bridge_blocked_message_timer_timeout)


func _physics_process(_delta: float) -> void:
	if bridge_blocker_collision.disabled or bridge_blocked_text.visible:
		return
	for collision_index: int in player.get_slide_collision_count():
		var collision: KinematicCollision2D = player.get_slide_collision(collision_index)
		if collision.get_collider() == bridge_blocker:
			bridge_blocked_text.show()
			bridge_blocked_message_timer.start()
			return


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
	bridge_blocker_collision.disabled = false
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
		_disable_bridge_blocker()
		objective_label.text = "Objetivo: Cruza el Puente de Yocalla"
		outcome_stage = 2


func _enable_bridge_collisions() -> void:
	for collision_shape: CollisionShape2D in bridge_collision_shapes:
		collision_shape.disabled = false


func _disable_bridge_blocker() -> void:
	bridge_blocker_collision.disabled = true
	bridge_blocked_message_timer.stop()
	bridge_blocked_text.hide()


func _on_bridge_blocked_message_timer_timeout() -> void:
	bridge_blocked_text.hide()


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


func _on_epilogue_area_body_entered(body: Node2D) -> void:
	if body != player or outcome_stage != 2 or epilogue_started:
		return
	epilogue_started = true
	rooster_event_label.hide()
	epilogue_text.show()
	objective_label.text = "Objetivo: Descubre el destino de Yocalla"
	final_story_timer.start()


func _on_final_story_timer_timeout() -> void:
	final_story_text.show()
	legend_complete_timer.start()


func _on_legend_complete_timer_timeout() -> void:
	if legend_completed:
		return
	legend_completed = true
	epilogue_text.hide()
	final_story_text.hide()
	legend_complete_panel.show()
	return_to_menu_button.grab_focus()
	objective_label.text = "Objetivo completado: La leyenda de Yocalla terminó"

func _on_return_to_menu_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _on_exit_button_pressed() -> void:
	get_tree().quit()
