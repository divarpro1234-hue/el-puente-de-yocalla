extends CharacterBody2D

const HORIZONTAL_SPEED: float = 250.0
const GRAVITY: float = 1200.0
const JUMP_VELOCITY: float = -450.0
const FALL_LIMIT_Y: float = 900.0

var max_health: int = 100
var current_health: int = 100
var is_respawning: bool = false

@onready var health_label: Label = get_node_or_null("PlayerHUD/HealthLabel")
@onready var animated_sprite: AnimatedSprite2D = $Visual


func _ready() -> void:
	CheckpointManager.set_checkpoint(global_position)
	reset_health()

func _physics_process(delta: float) -> void:
	var direction: float = Input.get_axis(&"move_left", &"move_right")
	velocity.x = direction * HORIZONTAL_SPEED

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	if Input.is_action_just_pressed(&"jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	move_and_slide()
	_update_animation(direction)

	if global_position.y > FALL_LIMIT_Y and not is_respawning:
		take_damage(100)


func take_damage(amount: int) -> void:
	if amount <= 0 or is_respawning:
		return

	current_health = maxi(current_health - amount, 0)

	if health_label:
		health_label.text = "❤ Vida: %d" % current_health

	if current_health > 0:
		return

	is_respawning = true
	reset_health()
	_respawn_at_checkpoint()
	is_respawning = false


func reset_health() -> void:
	current_health = max_health

	if health_label:
		health_label.text = "❤ Vida: %d" % current_health


func can_heal() -> bool:
	return not is_respawning and current_health > 0 and current_health < max_health


func heal(amount: int) -> void:
	if amount <= 0 or not can_heal():
		return

	current_health = mini(current_health + amount, max_health)

	if health_label:
		health_label.text = "❤ Vida: %d" % current_health


func _respawn_at_checkpoint() -> void:
	global_position = CheckpointManager.get_respawn_position()
	velocity = Vector2.ZERO

func _update_animation(direction: float) -> void:
	if direction != 0.0:
		animated_sprite.flip_h = direction < 0.0

	var next_animation: StringName = &"idle"

	if not is_on_floor():
		if velocity.y < 0.0:
			next_animation = &"jump"
		else:
			next_animation = &"fall"
	elif absf(velocity.x) > 0.1:
		next_animation = &"run"

	if animated_sprite.animation != next_animation:
		animated_sprite.play(next_animation)
