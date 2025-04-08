@tool
extends VBoxContainer
class_name PlayerSelectPanel

@onready var name_field = $TextureRect/NameField
@onready var stratagem_grid = $TextureRect/StratagemGrid
@onready var selected_grid = $TextureRect/SelectedGrid

# Will be set externally
var all_stratagems: Array[Stratagem] = []
var selected_stratagems: Array[Stratagem] = []

func _ready():
	_load_stratagem_buttons()

func _load_stratagem_buttons():
	for strat in all_stratagems:
		var button = Button.new()
		button.toggle_mode = true
		button.icon = _resize_icon(strat.icon, Vector2(48, 48))
		button.tooltip_text = strat.name + "\n" + strat.description
		button.pressed.connect(func():
			_on_stratagem_toggled(button, strat))
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
	selected_grid.clear()

	for strat in selected_stratagems:
		var icon = TextureRect.new()
		icon.texture = _resize_icon(strat.icon, Vector2(48, 48))
		icon.tooltip_text = strat.name + "\n" + strat.description
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		selected_grid.add_child(icon)

func _resize_icon(texture: Texture2D, size: Vector2) -> Texture2D:
	var image = texture.get_image()
	image.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)


func get_player_data() -> Dictionary:
	return {
		"name": name_field.text.strip_edges(),
		"strategems": selected_stratagems
	}
