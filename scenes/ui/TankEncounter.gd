extends Control

signal encounter_choice_made(choice: String)

@onready var fight_button: Button = $background/Fight
@onready var flight_button: Button = $background/Flight
@onready var label: Label = $background/Label
@onready var enemy_token: TextureRect = $background/Enemytoken

func _ready():
	label.text = "You have encountered an Annihilator Tank.\nWhat will you do?"
	fight_button.pressed.connect(func(): _emit_choice("fight"))
	flight_button.pressed.connect(func(): _emit_choice("flight"))

func _emit_choice(choice: String):
	emit_signal("encounter_choice_made", choice)
	queue_free()  # Close this popup so the Game scene can load the next step
