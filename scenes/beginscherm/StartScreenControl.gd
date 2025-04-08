extends Control

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		skip_to_next_scene()
	elif event is InputEventMouseButton and event.pressed:
		skip_to_next_scene()

func skip_to_next_scene():
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")  # Change path if needed
