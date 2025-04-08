extends AudioStreamPlayer

var scenes_with_music := [
	"res://scenes/beginscherm/StartScreen.tscn",
	"res://scenes/menu/menu.tscn",
	"res://scenes/player_select/PlayerSelect.tscn"
]

var last_scene_path := ""

func _ready():
	set_process_mode(PROCESS_MODE_ALWAYS)
	last_scene_path = ""
	_check_music_status()  # Initial check

func _process(_delta):
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return

	var current_path = current_scene.scene_file_path
	if current_path != last_scene_path:
		print("Scene changed to:", current_path)
		last_scene_path = current_path
		_check_music_status()

func _check_music_status():
	var scene = get_tree().current_scene
	if scene == null:
		print("⚠️ No current scene.")
		return

	var scene_path: String = scene.scene_file_path
	print("🎬 Checking scene:", scene_path)

	if scene_path in scenes_with_music:
		if not playing:
			print("🎵 Starting music.")
			play()
		else:
			print("🎵 Music already playing.")
	else:
		if playing:
			print("🛑 Scene does NOT allow music. Stopping.")
			stop()
