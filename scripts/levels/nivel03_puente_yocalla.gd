extends Node2D

@onready var objective_label: Label = $ObjectiveHUD/ObjectiveLabel


func _ready() -> void:
	objective_label.text = "Objetivo: Encuentra una forma de cruzar el río"
	objective_label.show()
