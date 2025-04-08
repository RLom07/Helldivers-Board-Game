extends AudioStreamPlayer

var scenes_to_stop_music := [
	"res://scenes/intro/IntroScreen.tscn"
]

func _ready():
	get_tree().connect("current_scene_changed", _on_scene_changed)
	
	# Run once at startup
	_on_scene_changed(get_tree().current_scene)


func _on_scene_changed(new_scene: Node) -> void:
	if new_scene == null:
		return
	
	var scene_path := new_scene.scene_file_path
	if scene_path in scenes_to_stop_music:
		if playing:
			stop()
	else:
		if not playing:
			play()
