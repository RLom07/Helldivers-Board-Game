extends Control

signal continue_pressed

@onready var countdown_label = $background/CountdownLabel
@onready var continue_button = $background/ContinueButton

func setup(turns_left: int):
	countdown_label.text = "🚁 Extraction arrives in " + str(turns_left - 1) + " turn(s)!"
	continue_button.pressed.connect(func():
		continue_pressed.emit()
		queue_free()
	)
