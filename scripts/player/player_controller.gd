extends CharacterBody2D

const HORIZONTAL_SPEED: float = 250.0
const GRAVITY: float = 1200.0
const JUMP_VELOCITY: float = -450.0

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
