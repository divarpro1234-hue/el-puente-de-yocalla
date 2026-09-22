extends CanvasLayer

const FADE_OUT_TIME := 0.28
const FADE_IN_TIME := 0.34

var _overlay: ColorRect
var _transitioning := false

func _ready() -> void:
	layer = 1000

	_overlay = ColorRect.new()
	_overlay.name = "FadeOverlay"
	_overlay.color = Color.BLACK
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	_overlay.modulate.a = 1.0
	_fade_in()


func change_scene(scene_path: String) -> void:
	if _transitioning:
		return

	_transitioning = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var fade_out := create_tween()
	fade_out.set_trans(Tween.TRANS_QUAD)
	fade_out.set_ease(Tween.EASE_IN_OUT)
	fade_out.tween_property(_overlay, "modulate:a", 1.0, FADE_OUT_TIME)
	await fade_out.finished

	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("No se pudo cambiar de escena: %s (error %s)" % [scene_path, error])
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_transitioning = false
		_fade_in()
		return

	await get_tree().process_frame
	_fade_in()


func _fade_in() -> void:
	var fade_in := create_tween()
	fade_in.set_trans(Tween.TRANS_QUAD)
	fade_in.set_ease(Tween.EASE_IN_OUT)
	fade_in.tween_property(_overlay, "modulate:a", 0.0, FADE_IN_TIME)
	fade_in.finished.connect(_on_fade_in_finished)


func _on_fade_in_finished() -> void:
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transitioning = false
