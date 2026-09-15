extends Node2D

const INFO_IDS: Array[String] = ["info_01", "info_02", "info_03"]
const NEXT_LEVEL_PATH: String = "res://scenes/levels/Nivel03_Puente_Yocalla.tscn"

var collected_info_ids: Dictionary = {}
var collected_resources: Dictionary = {
	"apple": 0,
	"herb": 0,
	"water": 0,
}
var return_mission_assigned: bool = false
var level_completed: bool = false
var level_transition_started: bool = false

@onready var objective_label: Label = $ObjectiveHUD/ObjectiveLabel
@onready var info_counter: Label = $ObjectiveHUD/InfoCounter
@onready var mensajero: Node2D = $ZonaReconocimiento/Mensajero
@onready var level_end_area: Area2D = $SenderosRegreso/LevelEndArea
@onready var level_complete_label: Label = $ObjectiveHUD/LevelCompleteLabel
@onready var level_transition_timer: Timer = $LevelTransitionTimer
@onready var resource_hud: CanvasLayer = $ResourceHUD
@onready var collectibles_root: Node2D = $Collectibles
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
	mensajero.connect(&"return_mission_assigned", _on_return_mission_assigned)
	level_transition_timer.timeout.connect(_on_level_transition_timer_timeout)
	for point: Node2D in info_points:
		point.connect(&"information_collected", _on_information_collected)
	for collectible: Node in collectibles_root.get_children():
		collectible.connect(&"collectible_collected", _on_collectible_collected)
	_update_info_counter()
	_update_resource_hud()


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
	if not (body is CharacterBody2D) or body != get_node("Player"):
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
