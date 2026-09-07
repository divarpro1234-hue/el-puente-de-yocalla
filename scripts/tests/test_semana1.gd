extends Node2D

@onready var jefe_inca: Node2D = $JefeInca_Test
@onready var objective_label: Label = $ObjectiveHUD/ObjectiveLabel


func _ready() -> void:
	jefe_inca.connect(&"mission_assigned", _on_mission_assigned)


func _on_mission_assigned(objective: String) -> void:
	objective_label.text = "Objetivo: " + objective
	objective_label.show()
