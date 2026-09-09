extends Node2D

const NEXT_LEVEL_PATH: String = "res://scenes/levels/Nivel02_Reconocimiento_Regreso.tscn"

var level_transition_started: bool = false

@onready var jefe_inca: Node2D = $ZonaComplejoInca/JefeInca_Test
@onready var objective_label: Label = $ObjectiveHUD/ObjectiveLabel
@onready var level_complete_label: Label = $ObjectiveHUD/LevelCompleteLabel
@onready var level_transition_timer: Timer = $LevelTransitionTimer


func _ready() -> void:
	objective_label.text = "Objetivo: Dirígete al Complejo del Jefe Inca"
	objective_label.show()
	level_complete_label.hide()
	jefe_inca.connect(&"mission_assigned", _on_mission_assigned)
	level_transition_timer.timeout.connect(_on_level_transition_timer_timeout)


func _on_mission_assigned(objective: String) -> void:
	objective_label.text = "Objetivo: " + objective
	objective_label.show()
	if level_transition_started:
		return
	level_transition_started = true
	level_complete_label.show()
	level_transition_timer.start()


func _on_level_transition_timer_timeout() -> void:
	get_tree().change_scene_to_file(NEXT_LEVEL_PATH)
