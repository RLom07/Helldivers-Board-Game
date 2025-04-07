extends Control

@onready var video_player = $VideoStreamPlayer
@onready var skip_label = $SkipLabel
@onready var blink_timer = $BlinkTimer

var skip_prompt_shown := false

func _ready():
	video_player.play()

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
	get_tree().change_scene_to_file("res://scenes/beginscherm/StartScreen.tscn")

func _on_BlinkTimer_timeout():
	skip_label.visible = !skip_label.visible


func _on_blink_timer_timeout() -> void:
	pass # Replace with function body.
