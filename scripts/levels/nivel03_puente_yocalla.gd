extends Node2D

# transition_fade_v1

# audio_base_v1

const MAIN_MENU_PATH: String = "res://scenes/ui/MainMenu.tscn"
const BRIDGE_WAIT_MESSAGE: String = "Aguarda el desenlace antes de cruzar."
const RIVER_FALL_MESSAGE: String = "La corriente te arrastró. Inténtalo de nuevo."

@onready var player: CharacterBody2D = $Player
@onready var pact_area: Area2D = $PactArea
@onready var river_fall_area: Area2D = $ZonaRioPuente/RiverFallArea
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
@onready var bridge_art: Array[Sprite2D] = [
	$ZonaRioPuente/BridgeZone/BridgeConstruction/BridgePart_01/BridgePart_01_Art,
	$ZonaRioPuente/BridgeZone/BridgeConstruction/BridgePart_02/BridgePart_02_Art,
]
@onready var crossing_guides: Array[Polygon2D] = [
	$ZonaRioPuente/BridgeZone/Guide_05,
	$ZonaRioPuente/BridgeZone/Guide_08,
]
@onready var level_music: AudioStreamPlayer = $LevelMusic
@onready var epilogue_glow: Sprite2D = $ZoneG_EpilogoFinal_Visual/Atmosphere/Glow
@onready var construction_timer: Timer = $ZonaRioPuente/BridgeZone/BridgeConstruction/ConstructionTimer
@onready var outcome_timer: Timer = $OutcomeTimer
@onready var final_story_timer: Timer = $FinalStoryTimer
@onready var legend_complete_timer: Timer = $LegendCompleteTimer
@onready var bridge_blocked_message_timer: Timer = $BridgeBlockedMessageTimer
@onready var bridge_sfx: AudioStreamPlayer = $BridgeSfx
@onready var rooster_sfx: AudioStreamPlayer = $RoosterSfx

var player_inside_pact_area: bool = false
var pact_completed: bool = false
var bridge_construction_started: bool = false
var next_bridge_part_index: int = 0
var outcome_sequence_started: bool = false
var outcome_stage: int = 0
var epilogue_started: bool = false
var legend_completed: bool = false
var impulse_was_active: bool = false


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
	($Player/PlayerHUD/EnergyPanel/RunnerHint as Label).add_theme_font_size_override("font_size", 11)
	bridge_blocker_collision.disabled = true
	pact_area.body_entered.connect(_on_pact_area_body_entered)
	pact_area.body_exited.connect(_on_pact_area_body_exited)
	epilogue_area.body_entered.connect(_on_epilogue_area_body_entered)
	river_fall_area.body_entered.connect(_on_river_fall_body_entered)
	construction_timer.timeout.connect(_on_construction_timer_timeout)
	outcome_timer.timeout.connect(_on_outcome_timer_timeout)
	final_story_timer.timeout.connect(_on_final_story_timer_timeout)
	legend_complete_timer.timeout.connect(_on_legend_complete_timer_timeout)
	bridge_blocked_message_timer.timeout.connect(_on_bridge_blocked_message_timer_timeout)
	epilogue_glow.modulate.a = 0.65


func _process(_delta: float) -> void:
	var impulse_active: bool = float(player.get("fox_remaining")) > 0.0
	if impulse_active and not impulse_was_active and outcome_stage == 2 and not epilogue_started:
		if player.global_position.x > 37500.0 and player.global_position.x < 37800.0:
			_pulse_crossing_guides()
	impulse_was_active = impulse_active


func _physics_process(_delta: float) -> void:
	if bridge_blocker_collision.disabled or bridge_blocked_text.visible:
		return
	for collision_index: int in player.get_slide_collision_count():
		var collision: KinematicCollision2D = player.get_slide_collision(collision_index)
		if collision.get_collider() == bridge_blocker:
			bridge_blocked_text.text = BRIDGE_WAIT_MESSAGE
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
		objective_label.text = "Objetivo: Avanza por el puente mientras se construye"
		_start_bridge_construction()
		get_viewport().set_input_as_handled()


func _start_bridge_construction() -> void:
	if bridge_construction_started:
		return
	bridge_construction_started = true
	bridge_blocker_collision.disabled = false
	bridge_parts[0].show()
	bridge_collision_shapes[0].disabled = false
	player.call(&"set_runner_enabled", true)
	objective_label.text = "Puente 1/3: avanza con cuidado"
	bridge_sfx.play()
	_celebrate_bridge_segment(0)
	next_bridge_part_index = 1
	construction_timer.start()


func _on_construction_timer_timeout() -> void:
	if next_bridge_part_index >= bridge_parts.size() - 1:
		construction_timer.stop()
		return
	bridge_parts[next_bridge_part_index].show()
	bridge_collision_shapes[next_bridge_part_index].disabled = false
	bridge_sfx.play()
	_celebrate_bridge_segment(next_bridge_part_index)
	next_bridge_part_index += 1
	objective_label.text = "Puente %d/3: avanza con cuidado" % next_bridge_part_index
	if next_bridge_part_index == bridge_parts.size() - 1:
		construction_timer.stop()
		objective_label.text = "Objetivo: Falta el último tramo. Observa el desenlace"
		_start_outcome_sequence()


func _celebrate_bridge_segment(segment_index: int) -> void:
	var art: Sprite2D = bridge_art[segment_index]
	var landing_y: float = art.position.y
	art.position.y -= 6.0
	art.modulate = Color(1.4, 1.24, 0.86)
	var tween: Tween = create_tween()
	tween.tween_property(art, "position:y", landing_y, 0.24)
	tween.parallel().tween_property(art, "modulate", Color.WHITE, 0.42)
	bridge_blocked_text.text = "Tramo %d colocado: puedes avanzar." % (segment_index + 1)
	if segment_index == 1:
		bridge_blocked_text.text = "Tramo 2 colocado: queda un espacio por cruzar."
	bridge_blocked_text.show()
	bridge_blocked_message_timer.start(0.75)


func _start_outcome_sequence() -> void:
	if outcome_sequence_started:
		return
	outcome_sequence_started = true
	guardian.call(&"reveal")
	outcome_timer.start()


func _on_outcome_timer_timeout() -> void:
	if outcome_stage == 0:
		rooster_event_label.show()
		rooster_sfx.play()
		outcome_stage = 1
		outcome_timer.start()
	elif outcome_stage == 1:
		satanas.hide()
		satanas_dialogue.hide()
		_enable_bridge_collisions()
		_disable_bridge_blocker()
		for guide: Polygon2D in crossing_guides:
			guide.modulate.a = 0.55
			guide.show()
		objective_label.text = "Objetivo: Usa F y salta el tramo faltante para cruzar"
		outcome_stage = 2


func _pulse_crossing_guides() -> void:
	for guide: Polygon2D in crossing_guides:
		guide.modulate.a = 1.0
		var tween: Tween = create_tween()
		tween.tween_property(guide, "modulate:a", 0.55, 0.55)


func _enable_bridge_collisions() -> void:
	for collision_index: int in bridge_collision_shapes.size():
		bridge_collision_shapes[collision_index].disabled = not bridge_parts[collision_index].visible


func _disable_bridge_blocker() -> void:
	bridge_blocker_collision.disabled = true
	bridge_blocked_message_timer.stop()
	bridge_blocked_text.hide()


func _on_bridge_blocked_message_timer_timeout() -> void:
	bridge_blocked_text.hide()


func _on_river_fall_body_entered(body: Node2D) -> void:
	if body != player or player.is_respawning:
		return
	bridge_blocked_text.text = RIVER_FALL_MESSAGE
	bridge_blocked_text.show()
	bridge_blocked_message_timer.start()
	player.call_deferred(&"take_damage", 100)


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
	player.call(&"set_runner_enabled", false)
	rooster_event_label.hide()
	bridge_blocked_text.hide()
	objective_label.text = "Objetivo: Descubre el destino de Yocalla"
	var music_tween: Tween = create_tween()
	music_tween.tween_property(level_music, "volume_db", -26.0, 1.8)
	var glow_tween: Tween = create_tween()
	glow_tween.tween_property(epilogue_glow, "modulate:a", 1.0, 1.2)
	var arrival_pause: Tween = create_tween()
	arrival_pause.tween_interval(0.65)
	arrival_pause.tween_callback(_show_epilogue_text)


func _show_epilogue_text() -> void:
	epilogue_text.show()
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
	SceneTransition.change_scene(MAIN_MENU_PATH)


func _on_exit_button_pressed() -> void:
	get_tree().quit()
