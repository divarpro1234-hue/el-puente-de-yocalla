extends CanvasLayer

@onready var apples_label: Label = $ApplesLabel
@onready var herbs_label: Label = $HerbsLabel
@onready var water_label: Label = $WaterLabel
@onready var feedback_label: Label = $FeedbackLabel
@onready var feedback_timer: Timer = $FeedbackTimer


func _ready() -> void:
	feedback_label.hide()
	feedback_timer.timeout.connect(_on_feedback_timer_timeout)
	update_counts(0, 0, 0)


func update_counts(apples: int, herbs: int, water: int) -> void:
	apples_label.text = "Manzanas: %d" % apples
	herbs_label.text = "Hierbas: %d" % herbs
	water_label.text = "Agua: %d" % water


func show_collection_feedback(collectible_type: String, amount: int) -> void:
	var singular_messages: Dictionary = {
		"apple": "Manzana obtenida",
		"herb": "Hierba obtenida",
		"water": "Agua obtenida",
	}
	var plural_names: Dictionary = {
		"apple": "Manzanas",
		"herb": "Hierbas",
		"water": "Agua",
	}
	if amount == 1:
		feedback_label.text = str(singular_messages.get(collectible_type, "Recurso obtenido"))
	else:
		feedback_label.text = "%s obtenidas: %d" % [str(plural_names.get(collectible_type, "Recursos")), amount]
	feedback_label.show()
	feedback_timer.start()


func _on_feedback_timer_timeout() -> void:
	feedback_label.hide()
