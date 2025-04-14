extends Control  

@onready var video_player = $VideoStreamPlayer  

func _ready():
	video_player.play()
	video_player.connect("finished", Callable(self, "_on_video_finished"))

func _on_video_finished():
	get_tree().change_scene_to_file("res://scenes/beginscherm/StartScreen.tscn")
