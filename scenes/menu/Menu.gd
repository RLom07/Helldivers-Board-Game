extends Control

@onready var main_game_button = $MainGameButton
@onready var tutorial_button = $TutorialButton

func _ready():
	main_game_button.pressed.connect(_on_main_game_pressed)
	tutorial_button.pressed.connect(_on_tutorial_pressed)

func _on_main_game_pressed():
	get_tree().change_scene_to_file("res://scenes/player_select/PlayerSelect.tscn")  # Update path if needed

func _on_tutorial_pressed():
	print("Tutorial button pressed (not implemented yet)")
