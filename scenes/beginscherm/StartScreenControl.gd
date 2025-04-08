extends Control

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_file("res://scenes/menu/menu.tscn") # Update with your next scene path
