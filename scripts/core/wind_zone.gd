@tool
extends Area2D

const WIND_IMPACT_SFX: AudioStream = preload("res://assets/audio/v2/sfx/wind_push_impact.wav")

# A sensor only: existing ground/player collisions are never changed.
@export_range(0.1, 1.0, 0.05) var speed_multiplier: float = 0.55
var phase: float = 0.0
var affected_bodies: Array[Node2D] = []
var _wind_audio: AudioStreamPlayer = null


func _ready() -> void:
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
		_wind_audio = AudioStreamPlayer.new()
		_wind_audio.stream = WIND_IMPACT_SFX
		_wind_audio.volume_db = -10.0
		add_child(_wind_audio)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method(&"set_wind_modifier") and not affected_bodies.has(body):
		affected_bodies.append(body)
		body.call(&"set_wind_modifier", self, speed_multiplier)
		if _wind_audio:
			_wind_audio.play()


func _on_body_exited(body: Node2D) -> void:
	if affected_bodies.has(body):
		affected_bodies.erase(body)
		if is_instance_valid(body):
			body.call(&"remove_wind_modifier", self)


func _exit_tree() -> void:
	for body: Node2D in affected_bodies:
		if is_instance_valid(body):
			body.call(&"remove_wind_modifier", self)
	affected_bodies.clear()


func _process(delta: float) -> void:
	phase = fposmod(phase + delta * 190.0, 600.0)
	queue_redraw()


func _draw() -> void:
	# Lightweight, crisp gust strokes work with Compatibility/OpenGL.
	var detection: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if detection == null or not detection.shape is RectangleShape2D:
		return
	var extent: Vector2 = (detection.shape as RectangleShape2D).size
	for index: int in range(18):
		var x: float = fposmod(float(index * 97) - phase, extent.x - 64.0) - extent.x * 0.5 + 32.0
		var y: float = float(index % 6) * (extent.y / 6.0) - extent.y * 0.5 + 18.0
		var point: Vector2 = detection.position + Vector2(x, y)
		var tint: Color = Color(0.76, 0.89, 0.84, 0.55)
		draw_polyline(PackedVector2Array([point + Vector2(48, -4), point + Vector2(24, -4), point, point + Vector2(10, -7)]), tint, 2.0)
