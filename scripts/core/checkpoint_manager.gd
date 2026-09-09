class_name CheckpointManager
extends RefCounted

static var checkpoint_position: Vector2 = Vector2.ZERO


static func set_checkpoint(new_position: Vector2) -> void:
	checkpoint_position = new_position


static func get_respawn_position() -> Vector2:
	return checkpoint_position
