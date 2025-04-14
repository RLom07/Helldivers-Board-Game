extends Control

signal extraction_choice_made(choice: bool)

@onready var yes_button = $background/Yes
@onready var no_button = $background/No

func _ready():
	yes_button.pressed.connect(func(): emit_signal("extraction_choice_made", true); queue_free())
	no_button.pressed.connect(func(): emit_signal("extraction_choice_made", false); queue_free())
