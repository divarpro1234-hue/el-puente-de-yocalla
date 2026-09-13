extends Node2D

@onready var dialogue_text: Label = $DialogueText


func _ready() -> void:
	hide()
	dialogue_text.hide()


func reveal() -> void:
	show()
	dialogue_text.show()


func hide_dialogue() -> void:
	dialogue_text.hide()
