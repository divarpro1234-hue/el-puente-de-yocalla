extends Node2D

# transition_fade_v1

const NEXT_LEVEL_PATH: String = "res://scenes/levels/Nivel02_Reconocimiento_Regreso.tscn"
const INTRO_PART_DURATION: float = 2.8
const RACE_MESSAGE_DURATION: float = 1.6
const STORY_MESSAGE_DURATION: float = 2.2
const GUARD_MESSAGE_DURATION: float = 2.5
const RACE_TARGET_SECONDS: float = 65.0

# Local race progress only; these gates do not change respawn checkpoints.
var race_active: bool = false
var race_countdown_started: bool = false
var race_finished: bool = false
var race_checkpoint_count: int = 0
var race_elapsed: float = 0.0
var race_feedback_remaining: float = 0.0
var race_best_time: float = 0.0
var race_record_saved: bool = true
# Separate local record; no global save manager or narrative state is needed.
var race_record_path: String = "user://yocalla_runner_record.cfg"

var intro_camera_started: bool = false
var intro_second_part_shown: bool = false
var intro_finished: bool = false
var race_event_started: bool = false
var secret_meeting_started: bool = false
var guard_event_completed: bool = false
var council_scene_started: bool = false
var council_scene_completed: bool = false
var level_transition_started: bool = false

@onready var player: CharacterBody2D = $Player
@onready var player_camera: Camera2D = $Player/Camera2D
@onready var intro_camera: Camera2D = $IntroCamera
@onready var jefe_inca: Node2D = $ZonaComplejoInca/JefeInca_Test
@onready var jefe_interaction_area: Area2D = $ZonaComplejoInca/JefeInca_Test/InteractionArea
@onready var jefe_interaction_prompt: Label = $ZonaComplejoInca/JefeInca_Test/InteractionPrompt
@onready var lucero: Node2D = $ZonaYocalla/Lucero_Test
@onready var lucero_consejo: Node2D = $ZonaComplejoInca/Lucero_Consejo
@onready var guardia_inca: Node2D = $ZonaYocalla/PuebloYocalla/GuardiaInca_Test
@onready var carrera_area: Area2D = $ZonaYocalla/CarreraArea
@onready var reunion_secreta_area: Area2D = $ZonaYocalla/PuebloYocalla/ReunionSecretaArea
@onready var consejo_area: Area2D = $ZonaComplejoInca/ConsejoArea
@onready var complex_access_blocker: StaticBody2D = $ZonaComplejoInca/ComplexAccessBlocker
@onready var complex_access_collision: CollisionShape2D = $ZonaComplejoInca/ComplexAccessBlocker/CollisionShape2D
@onready var objective_label: Label = $ObjectiveHUD/ObjectiveLabel
@onready var level_complete_label: Label = $ObjectiveHUD/LevelCompleteLabel
@onready var intro_story_text: Label = $ObjectiveHUD/IntroStoryText
@onready var intro_story_timer: Timer = $IntroStoryTimer
@onready var level_transition_timer: Timer = $LevelTransitionTimer
@onready var race_panel: Panel = $ObjectiveHUD/RacePanel
@onready var race_title: Label = $ObjectiveHUD/RacePanel/Title
@onready var race_progress: Label = $ObjectiveHUD/RacePanel/Progress
@onready var race_progress_bar: ProgressBar = $ObjectiveHUD/RacePanel/ProgressBar
@onready var race_feedback: Label = $ObjectiveHUD/RacePanel/Feedback
@onready var race_best_label: Label = $ObjectiveHUD/RacePanel/BestTime
@onready var race_sfx: AudioStreamPlayer = $RaceSfx
@onready var race_gates: Array[Area2D] = [
	$RaceCourse/Checkpoint1,
	$RaceCourse/Checkpoint2,
	$RaceCourse/Checkpoint3,
]


func _ready() -> void:
	_load_race_record()
	objective_label.text = "Objetivo: Completa la carrera y llega a Yocalla"
	objective_label.show()
	level_complete_label.hide()
	intro_story_text.hide()
	jefe_interaction_area.set_deferred(&"monitoring", false)
	jefe_interaction_prompt.hide()
	complex_access_collision.set_deferred(&"disabled", false)
	complex_access_blocker.show()
	jefe_inca.connect(&"mission_assigned", _on_mission_assigned)
	carrera_area.body_entered.connect(_on_carrera_area_body_entered)
	reunion_secreta_area.body_entered.connect(_on_reunion_secreta_area_body_entered)
	consejo_area.body_entered.connect(_on_consejo_area_body_entered)
	intro_story_timer.timeout.connect(_on_intro_story_timer_timeout)
	level_transition_timer.timeout.connect(_on_level_transition_timer_timeout)
	for index: int in range(race_gates.size()):
		race_gates[index].body_entered.connect(_on_race_checkpoint_entered.bind(index))
	# The level holds the start during the introduction/countdown only.
	player.set_physics_process(false)
	race_panel.hide()
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
	# Keep the race's ground and sky in frame without exposing the map edges.
	player_camera.limit_left = 0
	player_camera.limit_top = 0
	player_camera.limit_bottom = 648
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
		race_panel.show()
		_update_race_hud()
		objective_label.text = "Carrera: pasa por los tres hitos y cruza la meta"


func _unhandled_input(event: InputEvent) -> void:
	if not intro_finished or not race_panel.visible or race_countdown_started:
		return
	if event.is_action_pressed(&"interact") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_start_race_countdown()


func _start_race_countdown() -> void:
	if race_countdown_started:
		return
	race_countdown_started = true
	for count: int in range(3, 0, -1):
		race_title.text = "PREPÁRATE... %d" % count
		race_feedback.text = "A/D o flechas: correr   |   Espacio: saltar las rocas"
		race_sfx.pitch_scale = 0.8
		race_sfx.play()
		await get_tree().create_timer(1.0).timeout
	race_title.text = "CARRERA ANCESTRAL DE YOCALLA"
	race_active = true
	player.call(&"set_runner_enabled", true)
	player.set_physics_process(true)
	_show_race_feedback("¡Vamos! Busca el hito 1", 1.2)
	_update_race_hud()


func _process(delta: float) -> void:
	if not race_active:
		return
	race_elapsed += delta
	race_feedback_remaining = maxf(0.0, race_feedback_remaining - delta)
	if race_feedback_remaining == 0.0:
		if race_checkpoint_count < race_gates.size():
			race_feedback.text = "Siguiente: hito %d   |   Espacio: saltar las rocas" % (race_checkpoint_count + 1)
		else:
			race_feedback.text = "¡Los tres hitos completos! Cruza el arco de META"
	_update_race_hud()


func _update_race_hud() -> void:
	race_progress.text = "Hitos: %d/3   |   Tiempo: %.1f s   |   Reto: %.0f s" % [race_checkpoint_count, race_elapsed, RACE_TARGET_SECONDS]
	race_progress_bar.value = 4 if race_finished else race_checkpoint_count
	race_best_label.text = "Mejor guardado: %.2f s" % race_best_time if race_best_time > 0.0 else "Mejor guardado: —"
	if not race_record_saved:
		race_best_label.text += "   (nuevo tiempo sin guardar)"


func _load_race_record() -> void:
	race_best_time = 0.0
	var record: ConfigFile = ConfigFile.new()
	var error: Error = record.load(race_record_path)
	if error == ERR_FILE_NOT_FOUND:
		return
	if error != OK:
		push_warning("No se pudo leer el récord de carrera: %s" % error_string(error))
		return
	var saved: Variant = record.get_value("runner_v1", "best_seconds", 0.0)
	if (saved is float or saved is int) and is_finite(float(saved)) and float(saved) > 0.0:
		race_best_time = float(saved)


func _save_race_record() -> void:
	if race_best_time > 0.0 and race_elapsed >= race_best_time:
		return
	var record: ConfigFile = ConfigFile.new()
	record.set_value("runner_v1", "best_seconds", race_elapsed)
	var error: Error = record.save(race_record_path)
	race_record_saved = error == OK
	if race_record_saved:
		race_best_time = race_elapsed
	else:
		push_warning("No se pudo guardar el récord de carrera: %s" % error_string(error))


func _show_race_feedback(message: String, pitch: float) -> void:
	race_feedback.text = message
	race_feedback_remaining = 3.0
	race_sfx.pitch_scale = pitch
	race_sfx.play()


func _on_race_checkpoint_entered(body: Node2D, index: int) -> void:
	if body != player or not race_active or index < race_checkpoint_count:
		return
	if index != race_checkpoint_count:
		_show_race_feedback("Falta el hito %d: vuelve y sigue el orden" % (race_checkpoint_count + 1), 0.8)
		return
	race_checkpoint_count += 1
	var gate: Area2D = race_gates[index]
	var marker: Label = gate.get_node("Number") as Label
	marker.text = "¡COMPLETADO!"
	marker.modulate = Color("#aee8a0")
	var arch: Sprite2D = gate.get_node("Arch") as Sprite2D
	var flash: Tween = create_tween()
	arch.modulate = Color(1.8, 1.5, 0.8)
	flash.tween_property(arch, "modulate", Color(0.85, 1.0, 0.7), 0.65)
	_show_race_feedback("¡Hito %d/3!  Parcial: %.1f s" % [race_checkpoint_count, race_elapsed], 1.0 + float(index) * 0.15)
	_update_race_hud()


func _show_story_message(message: String, duration: float = STORY_MESSAGE_DURATION) -> void:
	intro_story_text.text = message
	intro_story_text.show()
	await get_tree().create_timer(duration).timeout


func _on_carrera_area_body_entered(body: Node2D) -> void:
	if race_finished or body != player or not race_active:
		return
	if race_checkpoint_count != race_gates.size():
		_show_race_feedback("Aún falta el hito %d. Completa los tres antes de la meta" % (race_checkpoint_count + 1), 0.8)
		return
	race_active = false
	race_finished = true
	player.call(&"set_runner_enabled", false)
	_save_race_record()
	race_title.text = "¡META!  ¡Kespi gana la carrera!"
	var result: String = "¡Reto de tiempo superado!" if race_elapsed <= RACE_TARGET_SECONDS else "¡Recorrido completo! Yocalla te espera"
	_show_race_feedback(result, 1.5)
	_update_race_hud()
	var finish_arch: Sprite2D = $ZoneB_EntradaYocalla_Visual/Gate
	finish_arch.modulate = Color(1.8, 1.5, 0.8)
	var celebration: Tween = create_tween()
	celebration.tween_property(finish_arch, "modulate", Color.WHITE, 1.5)
	# The result card presents the original victory line without overlapping dialogue.
	await get_tree().create_timer(RACE_MESSAGE_DURATION).timeout
	lucero.call(&"reveal")
	race_event_started = true
	objective_label.text = "Objetivo: Explora Yocalla y encuentra a los jóvenes del pueblo"
	objective_label.show()
	await get_tree().create_timer(4.0).timeout
	race_panel.hide()


func _on_reunion_secreta_area_body_entered(body: Node2D) -> void:
	if secret_meeting_started or not race_event_started or body != player:
		return
	secret_meeting_started = true
	await _show_story_message("Joven de Yocalla: Han llegado rumores de hombres extraños por los caminos.")
	await _show_story_message("Joven de Yocalla: Debemos estar atentos y proteger nuestro pueblo.")
	await _show_story_message("Kespi decide organizarse con los jóvenes de Yocalla.")
	intro_story_text.hide()
	guardia_inca.call(&"reveal")
	await get_tree().create_timer(GUARD_MESSAGE_DURATION).timeout
	guardia_inca.call(&"hide_dialogue")
	guard_event_completed = true
	complex_access_collision.set_deferred(&"disabled", true)
	complex_access_blocker.hide()
	objective_label.text = "Objetivo: Dirígete al Complejo del Jefe Inca"
	objective_label.show()


func _on_consejo_area_body_entered(body: Node2D) -> void:
	if council_scene_started or not guard_event_completed or body != player:
		return
	council_scene_started = true
	await _show_story_message("Jefe Inca: Has reunido a los jóvenes sin mi autorización.")
	await _show_story_message("Kespi: Solo quería proteger a Yocalla.")
	lucero_consejo.show()
	await _show_story_message("Lucero: Padre, Kespi no buscaba desafiarte. Intentaba proteger a Yocalla.")
	intro_story_text.hide()
	council_scene_completed = true
	jefe_interaction_area.set_deferred(&"monitoring", true)
	objective_label.text = "Objetivo: Habla con el Jefe Inca"
	objective_label.show()


func _on_mission_assigned(objective: String) -> void:
	if not council_scene_completed:
		return
	objective_label.text = "Objetivo: " + objective
	objective_label.show()
	if level_transition_started:
		return
	level_transition_started = true
	level_complete_label.show()
	level_transition_timer.start()


func _on_level_transition_timer_timeout() -> void:
	SceneTransition.change_scene(NEXT_LEVEL_PATH)
