extends Control  

@onready var video_player = $VideoPlayer
@onready var skip_label = $SkipLabel
@onready var blink_timer = $BlinkTimer

var skip_prompt_shown := false

func _ready():
	if video_player:
		video_player.connect("finished", _on_video_finished)
	else:
		push_error("❌ VideoPlayer node not found!")

func _on_video_finished():
	print("🎬 Video finished, transitioning to game...")
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")
	
func _unhandled_input(event):
	if not skip_prompt_shown and event is InputEventKey and not event.is_action_pressed("ui_accept"):
		skip_prompt_shown = true
		skip_label.visible = true
		blink_timer.start()

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		skip_intro()
	elif not video_player.is_playing():
		skip_intro()

func skip_intro():
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

func _on_BlinkTimer_timeout():
	skip_label.visible = !skip_label.visible
