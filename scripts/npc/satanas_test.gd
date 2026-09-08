extends Node2D

@onready var dialogue_text: Label = $DialogueText


func reveal() -> void:
	show()
	dialogue_text.show()
