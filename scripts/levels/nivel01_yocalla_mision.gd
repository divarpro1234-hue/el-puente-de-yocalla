extends Node2D

@onready var jefe_inca: Node2D = $ZonaComplejoInca/JefeInca_Test
@onready var objective_label: Label = $ObjectiveHUD/ObjectiveLabel


func _ready() -> void:
	objective_label.text = "Objetivo: Dirígete al Complejo del Jefe Inca"
	objective_label.show()
	jefe_inca.connect(&"mission_assigned", _on_mission_assigned)


func _on_mission_assigned(objective: String) -> void:
	objective_label.text = "Objetivo: " + objective
	objective_label.show()
