extends CharacterBody2D

# Auditoría Astra Test
# audio_base_v1

const HORIZONTAL_SPEED: float = 250.0
const GRAVITY: float = 1200.0
const JUMP_VELOCITY: float = -450.0
const FALL_LIMIT_Y: float = 900.0

# Opt-in by the level: other scenes retain their original movement and HUD.
const MAX_ENERGY: float = 100.0
const SPRINT_MULTIPLIER: float = 1.45
const SPRINT_DRAIN: float = 18.0
const ENERGY_RECOVERY: float = 14.0
const EXHAUSTION_RECOVERY: float = 25.0
const FOX_COST: float = 30.0
const FOX_DURATION: float = 1.2
const FOX_COOLDOWN: float = 3.0
const FOX_MULTIPLIER: float = 2.1

var runner_enabled: bool = false
var sprint_only: bool = false
var energy_capacity: float = MAX_ENERGY
var energy: float = MAX_ENERGY
var exhausted: bool = false
var fox_remaining: float = 0.0
var fox_cooldown_remaining: float = 0.0
var sprinting: bool = false
var wind_sources: Dictionary = {}
var runner_message: String = ""
var runner_message_remaining: float = 0.0

var max_health: int = 100
var current_health: int = 100
var is_respawning: bool = false

@onready var health_label: Label = get_node_or_null("PlayerHUD/HealthLabel")
@onready var animated_sprite: AnimatedSprite2D = $Visual
@onready var jump_sfx: AudioStreamPlayer = $JumpSfx
@onready var damage_sfx: AudioStreamPlayer = $DamageSfx
@onready var fox_sfx: AudioStreamPlayer = $FoxSfx
@onready var energy_panel: Control = $PlayerHUD/EnergyPanel
@onready var energy_bar: ProgressBar = $PlayerHUD/EnergyPanel/EnergyBar
@onready var energy_label: Label = $PlayerHUD/EnergyPanel/EnergyLabel
@onready var runner_hint: Label = $PlayerHUD/EnergyPanel/RunnerHint


func _ready() -> void:
	CheckpointManager.set_checkpoint(global_position)
	reset_health()
	energy_panel.hide()

func _physics_process(delta: float) -> void:
	var direction: float = Input.get_axis(&"move_left", &"move_right")
	velocity.x = direction * HORIZONTAL_SPEED * _runner_speed_multiplier(delta, direction)

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	if Input.is_action_just_pressed(&"jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump_sfx.play()

	move_and_slide()
	_update_animation(direction)

	if global_position.y > FALL_LIMIT_Y and not is_respawning:
		take_damage(100)


func take_damage(amount: int) -> void:
	if amount <= 0 or is_respawning:
		return

	damage_sfx.play()
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
	# Cancel the impulse, but do not refill energy or alter checkpoint state.
	fox_remaining = 0.0

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


func set_runner_enabled(enabled: bool) -> void:
	runner_enabled = enabled
	energy_panel.visible = enabled
	fox_remaining = 0.0
	fox_cooldown_remaining = 0.0
	sprinting = false
	exhausted = false
	energy = MAX_ENERGY
	animated_sprite.modulate = Color.WHITE
	animated_sprite.speed_scale = 1.0
	_update_energy_hud()


# Source-keyed wind modifiers support overlapping reusable zones without stacking
# them into an impassable wall. Dead sources are removed defensively.
func set_wind_modifier(source: Node, multiplier: float) -> void:
	wind_sources[source] = clampf(multiplier, 0.1, 1.0)


func remove_wind_modifier(source: Node) -> void:
	wind_sources.erase(source)


func get_wind_multiplier() -> float:
	var multiplier: float = 1.0
	for source: Variant in wind_sources.keys():
		if not is_instance_valid(source):
			wind_sources.erase(source)
		else:
			multiplier = minf(multiplier, float(wind_sources[source]))
	return multiplier


func _runner_speed_multiplier(delta: float, direction: float) -> float:
	var wind: float = get_wind_multiplier()
	if not runner_enabled:
		return wind
	fox_remaining = maxf(0.0, fox_remaining - delta)
	fox_cooldown_remaining = maxf(0.0, fox_cooldown_remaining - delta)
	runner_message_remaining = maxf(0.0, runner_message_remaining - delta)
	if Input.is_action_just_pressed(&"fox_impulse"):
		if direction != 0.0 and not exhausted and energy >= FOX_COST and fox_cooldown_remaining == 0.0:
			energy -= FOX_COST
			fox_remaining = FOX_DURATION
			fox_cooldown_remaining = FOX_DURATION + FOX_COOLDOWN
			fox_sfx.play()
		else:
			runner_message = "Camina para recuperarte"
			if direction == 0.0:
				runner_message = "Muévete para impulsarte"
			elif fox_cooldown_remaining > 0.0:
				runner_message = "Impulso recargándose"
			runner_message_remaining = 1.2
	sprinting = direction != 0.0 and Input.is_action_pressed(&"sprint") and not exhausted and fox_remaining == 0.0
	var speed: float = 1.0
	if fox_remaining > 0.0:
		speed = FOX_MULTIPLIER
		# The impulse resists most of the wind, but cannot bypass collisions.
		wind = lerpf(wind, 1.0, 0.75)
	elif sprinting:
		energy = maxf(0.0, energy - SPRINT_DRAIN * delta)
		speed = SPRINT_MULTIPLIER
	else:
		energy = minf(MAX_ENERGY, energy + ENERGY_RECOVERY * delta)
	if energy <= 0.0:
		exhausted = true
	if exhausted and energy >= EXHAUSTION_RECOVERY:
		exhausted = false
	if exhausted and fox_remaining == 0.0:
		speed = 0.65
	animated_sprite.modulate = Color(1.45, 1.15, 0.65) if fox_remaining > 0.0 else Color.WHITE
	animated_sprite.speed_scale = 1.6 if fox_remaining > 0.0 else (1.2 if sprinting else 1.0)
	_update_energy_hud()
	return speed * wind


func _runner_key(action: StringName) -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	return events[0].as_text().replace(" (Physical)", "") if not events.is_empty() else "sin tecla"


func _update_energy_hud() -> void:
	energy_bar.value = energy
	energy_label.text = "Energía: %d / 100" % ceili(energy)
	energy_bar.modulate = Color("#e89274") if exhausted else Color.WHITE
	if fox_remaining > 0.0:
		runner_hint.text = "¡Impulso del Zorro Andino!"
	elif exhausted:
		runner_hint.text = "Agotado: recupera 25 energía"
	elif runner_message_remaining > 0.0:
		runner_hint.text = runner_message
	elif fox_cooldown_remaining > 0.0:
		runner_hint.text = "Impulso listo en %.1f s" % fox_cooldown_remaining
	else:
		runner_hint.text = "%s: rápido | %s: impulso (-30)" % [_runner_key(&"sprint"), _runner_key(&"fox_impulse")]
