extends CharacterBody2D

const HORIZONTAL_SPEED: float = 250.0

func _physics_process(_delta: float) -> void:
	var direction: float = Input.get_axis(&"move_left", &"move_right")
	velocity.x = direction * HORIZONTAL_SPEED
	move_and_slide()
