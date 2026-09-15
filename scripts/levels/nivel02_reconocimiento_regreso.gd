extends Node2D

const INFO_IDS: Array[String] = ["info_01", "info_02", "info_03"]
const NEXT_LEVEL_PATH: String = "res://scenes/levels/Nivel03_Puente_Yocalla.tscn"
const HERB_HEAL_AMOUNT: int = 20
const STORM_DAMAGE_AMOUNT: int = 10
const STORM_DAMAGE_INTERVAL: float = 4.0

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

@onready var objective_label: Label = $ObjectiveHUD/ObjectiveLabel
@onready var info_counter: Label = $ObjectiveHUD/InfoCounter
@onready var mensajero: Node2D = $ZonaReconocimiento/Mensajero
@onready var level_end_area: Area2D = $SenderosRegreso/LevelEndArea
@onready var level_complete_label: Label = $ObjectiveHUD/LevelCompleteLabel
@onready var level_transition_timer: Timer = $LevelTransitionTimer
@onready var resource_hud: CanvasLayer = $ResourceHUD
@onready var collectibles_root: Node2D = $Collectibles
@onready var player: CharacterBody2D = $Player
@onready var storm_damage_area: Area2D = $ZonaTormenta/StormDamageArea
@onready var storm_damage_timer: Timer = $StormDamageTimer
@onready var info_points: Array[Node2D] = [
	$ZonaReconocimiento/InfoPoint_01,
	$ZonaReconocimiento/InfoPoint_02,
	$ZonaReconocimiento/InfoPoint_03,
]


func _ready() -> void:
	objective_label.text = "Objetivo: Reúne información en la zona de reconocimiento"
	objective_label.show()
	level_complete_label.hide()
	level_end_area.body_entered.connect(_on_level_end_body_entered)
	storm_damage_area.body_entered.connect(_on_storm_damage_area_body_entered)
	storm_damage_area.body_exited.connect(_on_storm_damage_area_body_exited)
	storm_damage_timer.timeout.connect(_on_storm_damage_timer_timeout)
	mensajero.connect(&"return_mission_assigned", _on_return_mission_assigned)
	level_transition_timer.timeout.connect(_on_level_transition_timer_timeout)
	for point: Node2D in info_points:
		point.connect(&"information_collected", _on_information_collected)
	for collectible: Node in collectibles_root.get_children():
		collectible.connect(&"collectible_collected", _on_collectible_collected)
	_update_info_counter()
	_update_resource_hud()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"use_herb"):
		_try_use_herb()


func _on_information_collected(info_id: String) -> void:
	if not INFO_IDS.has(info_id) or collected_info_ids.has(info_id):
		return
	collected_info_ids[info_id] = true
	_update_info_counter()
	if collected_info_ids.size() == INFO_IDS.size():
		mensajero.call(&"enable_interaction")


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


func _on_storm_damage_area_body_entered(body: Node2D) -> void:
	if body != player or is_player_in_storm_damage_area:
		return
	is_player_in_storm_damage_area = true
	resource_hud.call(&"show_feedback", "La tormenta está debilitando a Kespi.")
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


func _update_resource_hud() -> void:
	resource_hud.call(
		&"update_counts",
		int(collected_resources["apple"]),
		int(collected_resources["herb"]),
		int(collected_resources["water"]),
	)


func _update_info_counter() -> void:
	info_counter.text = "Información: %d/3" % collected_info_ids.size()


func _on_level_transition_timer_timeout() -> void:
	get_tree().change_scene_to_file(NEXT_LEVEL_PATH)
