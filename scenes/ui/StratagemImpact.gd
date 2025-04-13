extends Control

signal continue_pressed

@onready var title_label = $background/TitleLabel
@onready var enemies_label = $background/EnemiesLabel
@onready var continue_button = $background/ContinueButton

func _ready():
	continue_button.pressed.connect(_on_continue_pressed)

func _on_continue_pressed():
	emit_signal("continue_pressed")
	queue_free() # ❗ Cleanly remove from screen

func setup(hidden_hits: int, revealed_hit_names: Array):
	var total_hit = hidden_hits + revealed_hit_names.size()

	if total_hit == 0:
		enemies_label.text = "It doesn't seem you hit something"
	elif hidden_hits > 0 and revealed_hit_names.is_empty():
		enemies_label.text = "You managed to hit something"
	elif hidden_hits == 0 and revealed_hit_names.size() > 0:
		title_label.text = "You managed to hit:"
		enemies_label.text = ", ".join(revealed_hit_names)
	else:
		title_label.text = "You managed to hit:"
		enemies_label.text = ", ".join(revealed_hit_names) + " and something else"
