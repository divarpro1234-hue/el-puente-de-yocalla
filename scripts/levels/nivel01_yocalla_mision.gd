extends Node2D

const NEXT_LEVEL_PATH: String = "res://scenes/levels/Nivel02_Reconocimiento_Regreso.tscn"
const INTRO_PART_DURATION: float = 2.8
const RACE_MESSAGE_DURATION: float = 1.6

var intro_camera_started: bool = false
var intro_second_part_shown: bool = false
var intro_finished: bool = false
var race_event_started: bool = false
var level_transition_started: bool = false

@onready var player: CharacterBody2D = $Player
@onready var player_camera: Camera2D = $Player/Camera2D
@onready var intro_camera: Camera2D = $IntroCamera
@onready var jefe_inca: Node2D = $ZonaComplejoInca/JefeInca_Test
@onready var lucero: Node2D = $ZonaYocalla/Lucero_Test
@onready var carrera_area: Area2D = $ZonaYocalla/CarreraArea
@onready var objective_label: Label = $ObjectiveHUD/ObjectiveLabel
@onready var level_complete_label: Label = $ObjectiveHUD/LevelCompleteLabel
@onready var intro_story_text: Label = $ObjectiveHUD/IntroStoryText
@onready var intro_story_timer: Timer = $IntroStoryTimer
@onready var level_transition_timer: Timer = $LevelTransitionTimer


func _ready() -> void:
	objective_label.text = "Objetivo: Completa la carrera y llega a Yocalla"
	objective_label.show()
	level_complete_label.hide()
	intro_story_text.hide()
	jefe_inca.connect(&"mission_assigned", _on_mission_assigned)
	carrera_area.body_entered.connect(_on_carrera_area_body_entered)
	intro_story_timer.timeout.connect(_on_intro_story_timer_timeout)
	level_transition_timer.timeout.connect(_on_level_transition_timer_timeout)
	_start_intro()


func _start_intro() -> void:
	if intro_camera_started:
		return
	intro_camera_started = true
	intro_camera.enabled = true
	intro_camera.make_current()
	intro_story_text.text = "En las tierras altas de Yocalla se encontraba un pueblo rodeado de montañas y tradiciones ancestrales."
	intro_story_text.show()
	intro_story_timer.start(INTRO_PART_DURATION)


func _on_intro_story_timer_timeout() -> void:
	if not intro_second_part_shown:
		intro_second_part_shown = true
		intro_story_text.text = "Allí vivía Kespi, un joven conocido por su valentía y espíritu aventurero."
		intro_story_timer.start(INTRO_PART_DURATION)
		return
	_finish_intro()


func _finish_intro() -> void:
	if intro_finished:
		return
	intro_finished = true
	intro_story_timer.stop()
	intro_story_text.hide()
	player_camera.enabled = true
	player_camera.make_current()
	intro_camera.enabled = false
	_show_race_start_message()


func _show_race_start_message() -> void:
	intro_story_text.text = "Kespi participa en la carrera tradicional de Yocalla."
	intro_story_text.show()
	await get_tree().create_timer(RACE_MESSAGE_DURATION).timeout
	if not race_event_started:
		intro_story_text.hide()


func _on_carrera_area_body_entered(body: Node2D) -> void:
	if race_event_started or body != player:
		return
	race_event_started = true
	intro_story_text.text = "¡Kespi gana la carrera!"
	intro_story_text.show()
	await get_tree().create_timer(RACE_MESSAGE_DURATION).timeout
	intro_story_text.hide()
	lucero.call(&"reveal")
	objective_label.text = "Objetivo: Explora Yocalla y dirígete al Complejo del Jefe Inca"
	objective_label.show()


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
