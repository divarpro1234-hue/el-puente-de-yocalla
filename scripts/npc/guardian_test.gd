extends Node2D

@onready var event_text: Label = $EventText


func reveal() -> void:
	show()
	event_text.show()
