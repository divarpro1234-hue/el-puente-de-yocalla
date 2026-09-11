extends Control

const LEVEL_ONE_PATH: String = "res://scenes/levels/Nivel01_Yocalla_Mision.tscn"

@onready var play_button: Button = $PlayButton
@onready var exit_button: Button = $ExitButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	play_button.grab_focus()


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(LEVEL_ONE_PATH)


func _on_exit_button_pressed() -> void:
	get_tree().quit()
