extends Node2D

@onready var objective_label: Label = $ObjectiveHUD/ObjectiveLabel


func _ready() -> void:
	objective_label.text = "Objetivo: Reúne información en la zona de reconocimiento"
	objective_label.show()
