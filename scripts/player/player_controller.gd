extends CharacterBody2D

const HORIZONTAL_SPEED: float = 250.0
const GRAVITY: float = 1200.0

func _physics_process(delta: float) -> void:
	var direction: float = Input.get_axis(&"move_left", &"move_right")
	velocity.x = direction * HORIZONTAL_SPEED

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	move_and_slide()
