extends Control

# transition_fade_v1

const LEVEL_ONE_PATH: String = "res://scenes/levels/Nivel01_Yocalla_Mision.tscn"

@onready var play_button: Button = $PlayButton
@onready var exit_button: Button = $ExitButton
@onready var menu_music: AudioStreamPlayer = get_node_or_null("MenuMusic")


func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	play_button.grab_focus()


func _on_play_button_pressed() -> void:
	if menu_music and menu_music.playing:
		var fade := create_tween()
		fade.tween_property(menu_music, "volume_db", -40.0, 0.28)
	SceneTransition.change_scene(LEVEL_ONE_PATH)


func _on_exit_button_pressed() -> void:
	get_tree().quit()
