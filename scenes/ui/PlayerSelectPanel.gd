extends VBoxContainer
class_name PlayerSelectPanel

@onready var name_field = $TextureRect/NameField
@onready var stratagem_grid = $TextureRect/StratagemGrid
@onready var selected_grid = $TextureRect/SelectedGrid

var all_stratagems: Array[Stratagem] = []
var selected_stratagems: Array[Stratagem] = []
var strat_button_map: Dictionary = {}

func set_all_stratagems(stratagems: Array[Stratagem]) -> void:
	all_stratagems = stratagems
	call_deferred("_load_stratagem_buttons")

func _ready():
	pass

func _load_stratagem_buttons():
	# Remove previous buttons
	strat_button_map.clear()
	for child in stratagem_grid.get_children():
		child.queue_free()

	# Add buttons for each stratagem
	for strat in all_stratagems:
		var button := Button.new()
		button.toggle_mode = true
		button.icon = _resize_icon(strat.icon, Vector2(48, 48))
		button.tooltip_text = strat.name + "\n" + strat.description

		button.pressed.connect(func():
			_on_stratagem_toggled(button, strat))

		strat_button_map[strat] = button
		stratagem_grid.add_child(button)

func _on_stratagem_toggled(button: Button, strat: Stratagem):
	if button.button_pressed:
		if selected_stratagems.size() >= 4:
			button.button_pressed = false
			print("⚠️ Max 4 stratagems allowed.")
			return
		selected_stratagems.append(strat)
	else:
		selected_stratagems.erase(strat)

	_update_selected_grid()

func _update_selected_grid():
	# Clear previous selection icons
	for child in selected_grid.get_children():
		child.queue_free()

	# Add current selections as icons
	for strat in selected_stratagems:
		var icon_button := TextureButton.new()
		icon_button.texture_normal = _resize_icon(strat.icon, Vector2(48, 48))
		icon_button.tooltip_text = strat.name + "\n" + strat.description
		icon_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

		icon_button.pressed.connect(func():
			# Remove from selected list
			selected_stratagems.erase(strat)
			if strat_button_map.has(strat):
				strat_button_map[strat].button_pressed = false
			_update_selected_grid()
		)

		selected_grid.add_child(icon_button)

func _resize_icon(texture: Texture2D, size: Vector2) -> Texture2D:
	var image := texture.get_image()
	image.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)

func get_player_data() -> Dictionary:
	return {
		"name": name_field.text.strip_edges(),
		"strategems": selected_stratagems.duplicate()
	}
