extends Control  # or Node if you're not using UI

@onready var video_player = $VideoPlayer

func _ready():
	if video_player:
		video_player.connect("finished", _on_video_finished)
	else:
		push_error("❌ VideoPlayer node not found!")

func _on_video_finished():
	print("🎬 Video finished, transitioning to game...")
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")
