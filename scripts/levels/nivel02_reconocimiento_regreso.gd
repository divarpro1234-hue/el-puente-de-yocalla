extends Node2D

# transition_fade_v1

# audio_base_v1

const INFO_IDS: Array[String] = ["info_01", "info_02", "info_03"]
const NEXT_LEVEL_PATH: String = "res://scenes/levels/Nivel03_Puente_Yocalla.tscn"
const HERB_HEAL_AMOUNT: int = 20
const APPLE_HEAL_AMOUNT: int = 10
const STORM_DAMAGE_AMOUNT: int = 10
const STORM_DAMAGE_INTERVAL: float = 4.0
const CLUE_TEXT: Dictionary = {
	"info_01": "La primera señal mira hacia el antiguo paso. Parece orientar a los viajeros.",
	"info_02": "Las marcas en la piedra señalan un cruce hacia la montaña.",
	"info_03": "Desde esta altura se distingue el camino que conduce al puente.",
}
const OPTIONAL_DISCOVERY_IDS: Array[String] = ["secret_view", "secret_marks", "trail_chain"]
const TRAIL_IDS: Array[String] = ["trail_sign", "trail_water", "trail_evidence"]
const TRAIL_TEXT: Dictionary = {
	"trail_sign": "Una señal desgastada apunta hacia la quebrada. Kespi decide seguir el rastro.",
	"trail_water": "La cantimplora quedó junto al paso. Alguien cruzó por aquí antes que Kespi.",
	"trail_evidence": "Las marcas continúan más allá del cruce. El camino hacia el puente se vuelve claro.",
}
const SECRET_TEXT: Dictionary = {
	"secret_view": "Desde el mirador, Kespi reconoce la ruta entre las montañas.",
	"secret_marks": "Dos señales del sendero se leen siguiendo el camino, de izquierda a derecha.",
}

var collected_info_ids: Dictionary = {}
var collected_resources: Dictionary = {
	"apple": 0,
	"herb": 0,
	"water": 0,
}
var return_mission_assigned: bool = false
var level_completed: bool = false
var level_transition_started: bool = false
var is_player_in_storm_damage_area: bool = false
var optional_discoveries: Dictionary = {}
var first_mark_examined: bool = false
var trail_found: Dictionary = {}
var environmental_events_seen: Dictionary = {}
var info_point_pulses: Dictionary = {}
var ambient_audio_tweens: Dictionary = {}
var pre_storm_visual_active: bool = false
var wind_streak_phase: float = 0.0
var pre_storm_visual_tween: Tween

@onready var objective_label: Label = $ObjectiveHUD/ObjectiveLabel
@onready var info_counter: Label = $ObjectiveHUD/InfoCounter
@onready var optional_counter: Label = $ObjectiveHUD/OptionalCounter
@onready var exploration_summary_label: Label = $ObjectiveHUD/ExplorationSummaryLabel
@onready var discovery_label: Label = $ObjectiveHUD/DiscoveryLabel
@onready var discovery_timer: Timer = $DiscoveryTimer
@onready var optional_points: Node2D = $OptionalDiscoveries
@onready var mensajero: Node2D = $ZonaReconocimiento/Mensajero
@onready var level_end_area: Area2D = $SenderosRegreso/LevelEndArea
@onready var level_complete_label: Label = $ObjectiveHUD/LevelCompleteLabel
@onready var level_transition_timer: Timer = $LevelTransitionTimer
@onready var resource_hud: CanvasLayer = $ResourceHUD
@onready var collectibles_root: Node2D = $Collectibles
@onready var trail_water: Node2D = $Collectibles/Water_01
@onready var player: CharacterBody2D = $Player
@onready var storm_damage_area: Area2D = $ZonaTormenta/StormDamageArea
@onready var storm_damage_timer: Timer = $StormDamageTimer
@onready var storm_audio: AudioStreamPlayer = $StormAudio
@onready var level_music: AudioStreamPlayer = $LevelMusic
@onready var village_rooster_sfx: AudioStreamPlayer = $EnvironmentalEvents/VillageRoosterSfx
@onready var ravine_audio: AudioStreamPlayer = $EnvironmentalEvents/RavineAudio
@onready var pre_storm_audio: AudioStreamPlayer = $EnvironmentalEvents/PreStormAudio
@onready var transition_tint: Sprite2D = $Level02_StormVisual/TransitionTint
@onready var transition_rain: Sprite2D = $Level02_StormVisual/TransitionRain
@onready var wind_streak_near: Line2D = $EnvironmentalEvents/WindStreakNear
@onready var wind_streak_far: Line2D = $EnvironmentalEvents/WindStreakFar
@onready var info_points: Array[Node2D] = [
	$ZonaReconocimiento/InfoPoint_01,
	$ZonaReconocimiento/InfoPoint_02,
	$ZonaReconocimiento/InfoPoint_03,
]


func _ready() -> void:
	objective_label.text = "Objetivo: Reúne información en la zona de reconocimiento"
	objective_label.show()
	level_complete_label.hide()
	exploration_summary_label.hide()
	level_end_area.body_entered.connect(_on_level_end_body_entered)
	storm_damage_area.body_entered.connect(_on_storm_damage_area_body_entered)
	storm_damage_area.body_exited.connect(_on_storm_damage_area_body_exited)
	storm_damage_timer.timeout.connect(_on_storm_damage_timer_timeout)
	mensajero.connect(&"return_mission_assigned", _on_return_mission_assigned)
	level_transition_timer.timeout.connect(_on_level_transition_timer_timeout)
	for point: Node2D in info_points:
		point.connect(&"information_collected", _on_information_collected)
		_bind_info_point_feedback(point)
	for point: Node2D in optional_points.get_children():
		point.connect(&"information_collected", _on_optional_discovery)
		_bind_info_point_feedback(point)
	discovery_timer.timeout.connect(discovery_label.hide)
	discovery_label.hide()
	mensajero.call(&"set_investigation_progress", 0, INFO_IDS.size())
	for collectible: Node in collectibles_root.get_children():
		collectible.connect(&"collectible_collected", _on_collectible_collected)
	trail_water.connect(&"collectible_collected", _on_trail_water_collected)
	for area: Area2D in [$EnvironmentalEvents/TrailGrassArea, $EnvironmentalEvents/FinalGrassArea]:
		area.body_entered.connect(_on_environment_event.bind(String(area.name)))
	for area: Area2D in [$EnvironmentalEvents/VillageEdgeArea, $EnvironmentalEvents/RavineArea, $EnvironmentalEvents/PreStormArea]:
		area.body_entered.connect(_on_ambient_zone_entered.bind(String(area.name)))
		area.body_exited.connect(_on_ambient_zone_exited.bind(String(area.name)))
	for area: Area2D in [$EnvironmentalEvents/MeadowGrassArea, $EnvironmentalEvents/ReturnGrassArea, $EnvironmentalEvents/StormEdgeGrassArea]:
		area.body_entered.connect(_on_visual_grass_entered.bind(String(area.name)))
	transition_tint.modulate.a = 0.65
	transition_rain.modulate.a = 0.5
	wind_streak_near.hide()
	wind_streak_far.hide()
	_update_info_counter()
	_update_optional_counter()
	_update_resource_hud()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"use_herb"):
		_try_use_herb()
	if Input.is_action_just_pressed(&"use_apple"):
		_try_use_apple()
	if pre_storm_visual_active:
		_update_wind_streaks(delta)


func _bind_info_point_feedback(point: Node2D) -> void:
	var area: Area2D = point.get_node("InteractionArea") as Area2D
	area.body_entered.connect(_on_info_point_entered.bind(point))
	area.body_exited.connect(_on_info_point_exited.bind(point))
	point.connect(&"information_collected", _on_info_point_examined.bind(point))


func _on_info_point_entered(body: Node2D, point: Node2D) -> void:
	if body != player or bool(point.get("collected")):
		return
	var marker: Sprite2D = point.get_node("MarkerSprite") as Sprite2D
	var tween: Tween = create_tween().set_loops()
	info_point_pulses[point] = tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(marker, "position:y", -23.0, 0.55)
	tween.parallel().tween_property(marker, "modulate", Color(1.15, 1.12, 0.96), 0.55)
	tween.tween_property(marker, "position:y", -20.0, 0.55)
	tween.parallel().tween_property(marker, "modulate", Color.WHITE, 0.55)


func _on_info_point_exited(body: Node2D, point: Node2D) -> void:
	if body != player:
		return
	_stop_info_point_pulse(point)
	if not bool(point.get("collected")):
		_reset_info_point_marker(point)


func _on_info_point_examined(_info_id: String, point: Node2D) -> void:
	_stop_info_point_pulse(point)
	var marker: Sprite2D = point.get_node("MarkerSprite") as Sprite2D
	marker.position.y = -20.0
	marker.modulate = Color.WHITE
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(marker, "scale", Vector2(0.81, 0.81), 0.12)
	tween.parallel().tween_property(marker, "modulate", Color(1.45, 1.35, 1.05), 0.12)
	tween.tween_property(marker, "scale", Vector2(0.72, 0.72), 0.28)
	tween.parallel().tween_property(marker, "modulate", Color.WHITE, 0.28)
	tween.finished.connect(_resume_info_point_pulse.bind(point))


func _resume_info_point_pulse(point: Node2D) -> void:
	if not bool(point.get("collected")) and bool(point.get("player_inside")):
		_on_info_point_entered(player, point)


func _stop_info_point_pulse(point: Node2D) -> void:
	if info_point_pulses.has(point):
		var tween: Tween = info_point_pulses[point] as Tween
		tween.kill()
		info_point_pulses.erase(point)


func _reset_info_point_marker(point: Node2D) -> void:
	var marker: Sprite2D = point.get_node("MarkerSprite") as Sprite2D
	marker.position.y = -20.0
	marker.modulate = Color.WHITE


func _on_information_collected(info_id: String) -> void:
	if not INFO_IDS.has(info_id) or collected_info_ids.has(info_id):
		return
	collected_info_ids[info_id] = true
	_update_info_counter()
	mensajero.call(&"set_investigation_progress", collected_info_ids.size(), INFO_IDS.size())
	_show_discovery(str(CLUE_TEXT[info_id]))


func _on_optional_discovery(info_id: String) -> void:
	if level_completed:
		return
	if TRAIL_IDS.has(info_id):
		_on_trail_clue(info_id)
		return
	if info_id == "secret_view" and not optional_discoveries.has(info_id):
		optional_discoveries[info_id] = true
		_update_optional_counter()
		_show_discovery(str(SECRET_TEXT[info_id]))
	elif info_id == "mark_first":
		first_mark_examined = true
		_show_discovery("Primera marca observada. Busca la siguiente más adelante.")
	elif info_id == "mark_second":
		if first_mark_examined:
			if not optional_discoveries.has("secret_marks"):
				optional_discoveries["secret_marks"] = true
				_update_optional_counter()
				_show_discovery(str(SECRET_TEXT["secret_marks"]))
		else:
			_show_discovery("Las marcas parecen tener un orden. Busca el inicio del sendero.")
			optional_points.get_node("MarkSecond").call_deferred(&"reset_discovery")


func _on_trail_water_collected(_collectible_type: String, _amount: int) -> void:
	_on_trail_clue("trail_water")


func _on_trail_clue(clue_id: String) -> void:
	if level_completed or trail_found.has(clue_id):
		return
	trail_found[clue_id] = true
	var message: String = "Rastro %d/3: %s" % [trail_found.size(), str(TRAIL_TEXT[clue_id])]
	if trail_found.size() == TRAIL_IDS.size():
		optional_discoveries["trail_chain"] = true
		_update_optional_counter()
		message += " Kespi ha reconstruido la ruta."
	_show_discovery(message)
	if clue_id == "trail_sign":
		_flash_marker($ZoneB_Reconocimiento01_Visual/Props/RouteMarker)
	elif clue_id == "trail_evidence":
		_flash_marker($ZoneF_Reconocimiento03_Visual/Decoration/ObservationMarker)


func _on_environment_event(body: Node2D, event_id: String) -> void:
	if body != player or environmental_events_seen.has(event_id):
		return
	environmental_events_seen[event_id] = true
	if event_id == "TrailGrassArea":
		_sway_grass($EnvironmentalEvents/TrailGrass)
	else:
		_sway_grass($ZoneF_Reconocimiento03_Visual/Decoration/Grass02)


func _on_visual_grass_entered(body: Node2D, area_id: String) -> void:
	if body != player:
		return
	match area_id:
		"MeadowGrassArea":
			_sway_grass($ZoneB_Reconocimiento01_Visual/Props/Grass01)
		"ReturnGrassArea":
			_sway_grass($ZoneG_MensajeroRegreso_Visual/Decoration/Grass02)
		"StormEdgeGrassArea":
			_sway_grass($ZoneH_TormentaFinal_Visual/Decoration/Grass01)


func _on_ambient_zone_entered(body: Node2D, zone_id: String) -> void:
	if body != player:
		return
	match zone_id:
		"VillageEdgeArea":
			if not environmental_events_seen.has(zone_id):
				environmental_events_seen[zone_id] = true
				village_rooster_sfx.play()
				_sway_grass($ZoneA_SenderosIda_Visual/Props/Bush02)
		"RavineArea":
			_fade_ambient_audio(ravine_audio, -23.0, 1.5)
			_ripple_water()
		"PreStormArea":
			_fade_ambient_audio(pre_storm_audio, -26.0, 2.0)
			_fade_ambient_audio(level_music, -23.0, 2.0)
			pre_storm_visual_active = true
			wind_streak_near.show()
			wind_streak_far.show()
			_fade_pre_storm_visuals(1.0, 1.0)


func _on_ambient_zone_exited(body: Node2D, zone_id: String) -> void:
	if body != player:
		return
	match zone_id:
		"VillageEdgeArea":
			village_rooster_sfx.stop()
		"RavineArea":
			_fade_ambient_audio(ravine_audio, -40.0, 1.2, true)
		"PreStormArea":
			_fade_ambient_audio(pre_storm_audio, -40.0, 0.8, true)
			_fade_ambient_audio(level_music, -17.0, 1.2)
			pre_storm_visual_active = false
			wind_streak_near.hide()
			wind_streak_far.hide()
			if body.global_position.x < $EnvironmentalEvents/PreStormArea.global_position.x:
				_fade_pre_storm_visuals(0.65, 0.5)


func _fade_pre_storm_visuals(tint_alpha: float, rain_alpha: float) -> void:
	if is_instance_valid(pre_storm_visual_tween) and pre_storm_visual_tween.is_running():
		pre_storm_visual_tween.kill()
	pre_storm_visual_tween = create_tween()
	pre_storm_visual_tween.tween_property(transition_tint, "modulate:a", tint_alpha, 2.0)
	pre_storm_visual_tween.parallel().tween_property(transition_rain, "modulate:a", rain_alpha, 2.0)


func _update_wind_streaks(delta: float) -> void:
	wind_streak_phase = fposmod(wind_streak_phase + delta * 110.0, 170.0)
	var second_phase: float = fposmod(wind_streak_phase + 82.0, 170.0)
	wind_streak_near.position = Vector2(roundf(player.global_position.x + 110.0 - wind_streak_phase), roundf(player.global_position.y - 58.0))
	wind_streak_far.position = Vector2(roundf(player.global_position.x + 130.0 - second_phase), roundf(player.global_position.y - 26.0))


func _fade_ambient_audio(audio: AudioStreamPlayer, target_db: float, duration: float, stop_after: bool = false) -> void:
	if ambient_audio_tweens.has(audio):
		var previous_tween: Tween = ambient_audio_tweens[audio] as Tween
		if previous_tween.is_running():
			previous_tween.kill()
	if not audio.playing and target_db > -40.0:
		audio.volume_db = -40.0
		audio.play()
	if not audio.playing and target_db <= -40.0:
		return
	var tween: Tween = create_tween()
	ambient_audio_tweens[audio] = tween
	tween.tween_property(audio, "volume_db", target_db, duration)
	if stop_after:
		tween.finished.connect(audio.stop)


func _ripple_water() -> void:
	var water: Sprite2D = $ZoneE_Quebrada_Visual/WaterArt
	var tween: Tween = create_tween()
	tween.tween_property(water, "position:y", 512.0, 0.35)
	tween.parallel().tween_property(water, "modulate", Color(1.12, 1.16, 1.2), 0.35)
	tween.tween_property(water, "position:y", 514.0, 0.55)
	tween.parallel().tween_property(water, "modulate", Color.WHITE, 0.55)


func _sway_grass(grass: Sprite2D) -> void:
	# A short local movement gives the wind a presence without affecting physics.
	var tween: Tween = create_tween()
	tween.tween_property(grass, "rotation", 0.14, 0.18)
	tween.tween_property(grass, "rotation", -0.08, 0.25)
	tween.tween_property(grass, "rotation", 0.0, 0.3)


func _flash_marker(marker: Sprite2D) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(marker, "modulate", Color(1.5, 1.3, 0.9), 0.15)
	tween.tween_property(marker, "modulate", Color.WHITE, 0.45)


func _show_discovery(message: String) -> void:
	discovery_label.text = message
	discovery_label.show()
	discovery_timer.start()


func _on_return_mission_assigned() -> void:
	if level_completed or collected_info_ids.size() != INFO_IDS.size():
		return
	return_mission_assigned = true
	objective_label.text = "Objetivo: Regresa a Yocalla"
	objective_label.show()


func _on_level_end_body_entered(body: Node2D) -> void:
	if level_completed or not return_mission_assigned:
		return
	if collected_info_ids.size() != INFO_IDS.size():
		return
	if not (body is CharacterBody2D) or body != player:
		return
	level_completed = true
	level_complete_label.show()
	discovery_timer.stop()
	discovery_label.hide()
	exploration_summary_label.text = "Pistas principales: %d/%d\nDescubrimientos opcionales: %d/%d" % [collected_info_ids.size(), INFO_IDS.size(), optional_discoveries.size(), OPTIONAL_DISCOVERY_IDS.size()]
	exploration_summary_label.show()
	objective_label.text = "Objetivo completado: Regresaste a Yocalla"
	objective_label.show()
	if not level_transition_started:
		level_transition_started = true
		level_transition_timer.start()


func _on_collectible_collected(collectible_type: String, amount: int) -> void:
	if not collected_resources.has(collectible_type) or amount <= 0:
		return
	collected_resources[collectible_type] = int(collected_resources[collectible_type]) + amount
	_update_resource_hud()
	resource_hud.call(&"show_collection_feedback", collectible_type, amount)


func _try_use_herb() -> void:
	if int(collected_resources["herb"]) <= 0:
		resource_hud.call(&"show_feedback", "No tienes hierbas")
		return

	if not bool(player.call(&"can_heal")):
		if not bool(player.get("is_respawning")) and int(player.get("current_health")) >= int(player.get("max_health")):
			resource_hud.call(&"show_feedback", "La vida ya está completa")
		return

	player.call(&"heal", HERB_HEAL_AMOUNT)
	collected_resources["herb"] = int(collected_resources["herb"]) - 1
	_update_resource_hud()
	resource_hud.call(&"show_feedback", "Hierba usada: +%d vida" % HERB_HEAL_AMOUNT)


func _try_use_apple() -> void:
	if int(collected_resources["apple"]) <= 0:
		resource_hud.call(&"show_feedback", "No tienes manzanas")
		return

	if not bool(player.call(&"can_heal")):
		if not bool(player.get("is_respawning")) and int(player.get("current_health")) >= int(player.get("max_health")):
			resource_hud.call(&"show_feedback", "La vida ya está completa")
		return

	player.call(&"heal", APPLE_HEAL_AMOUNT)
	collected_resources["apple"] = int(collected_resources["apple"]) - 1
	_update_resource_hud()
	resource_hud.call(&"show_feedback", "Manzana comida: +%d vida" % APPLE_HEAL_AMOUNT)


func _on_storm_damage_area_body_entered(body: Node2D) -> void:
	if body != player or is_player_in_storm_damage_area:
		return
	is_player_in_storm_damage_area = true
	if not storm_audio.playing:
		storm_audio.play()
	resource_hud.call(&"show_feedback", "Tormenta: busca refugio.")
	storm_damage_timer.start(STORM_DAMAGE_INTERVAL)


func _on_storm_damage_area_body_exited(body: Node2D) -> void:
	if body == player:
		_stop_storm_damage()


func _on_storm_damage_timer_timeout() -> void:
	if not is_player_in_storm_damage_area or not storm_damage_area.overlaps_body(player):
		_stop_storm_damage()
		return

	var health_before_damage: int = int(player.get("current_health"))
	player.call(&"take_damage", STORM_DAMAGE_AMOUNT)

	if health_before_damage <= STORM_DAMAGE_AMOUNT:
		_stop_storm_damage()


func _stop_storm_damage() -> void:
	is_player_in_storm_damage_area = false
	storm_damage_timer.stop()
	storm_audio.stop()


func _update_resource_hud() -> void:
	resource_hud.call(
		&"update_counts",
		int(collected_resources["apple"]),
		int(collected_resources["herb"]),
		int(collected_resources["water"]),
	)


func _update_info_counter() -> void:
	info_counter.text = "Información: %d/3" % collected_info_ids.size()


func _update_optional_counter() -> void:
	optional_counter.text = "Exploración: %d/%d" % [optional_discoveries.size(), OPTIONAL_DISCOVERY_IDS.size()]


func _on_level_transition_timer_timeout() -> void:
	SceneTransition.change_scene(NEXT_LEVEL_PATH)
