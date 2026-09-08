extends Node2D

const INFO_IDS: Array[String] = ["info_01", "info_02", "info_03"]

var collected_info_ids: Dictionary = {}
var return_mission_assigned: bool = false
var level_completed: bool = false

@onready var objective_label: Label = $ObjectiveHUD/ObjectiveLabel
@onready var info_counter: Label = $ObjectiveHUD/InfoCounter
@onready var mensajero: Node2D = $ZonaReconocimiento/Mensajero
@onready var level_end_area: Area2D = $SenderosRegreso/LevelEndArea
@onready var level_complete_label: Label = $ObjectiveHUD/LevelCompleteLabel
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
	for point: Node2D in info_points:
		point.connect(&"information_collected", _on_information_collected)
	_update_info_counter()


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


func _update_info_counter() -> void:
	info_counter.text = "Información: %d/3" % collected_info_ids.size()
