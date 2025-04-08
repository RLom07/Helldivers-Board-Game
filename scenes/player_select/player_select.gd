extends Control

const PlayerSelectPanel = preload("res://scenes/ui/PlayerSelectPanel.gd")

@onready var player_row = $MarginContainer/VBoxContainer/PlayerRow
@onready var confirm_button = $MarginContainer/VBoxContainer/ConfirmButton

@onready var add_button_1 = $MarginContainer/VBoxContainer/PlayerRow/Addbutton1
@onready var add_button_2 = $MarginContainer/VBoxContainer/PlayerRow/Addbutton2
@onready var add_button_3 = $MarginContainer/VBoxContainer/PlayerRow/Addbutton3

var all_stratagems = [
	preload("res://scripts/data/stratagems/Napalm.tres"),
	preload("res://scripts/data/stratagems/Orbital Barage.tres"),
	preload("res://scripts/data/stratagems/Napalm Eagle.tres"),
	preload("res://scripts/data/stratagems/Smoke Eagle.tres")
]

var current_player_count := 1
const MAX_PLAYERS := 4

func _ready():
	# Hook up plus buttons
	add_button_1.pressed.connect(func(): _add_player_at_index(1))
	add_button_2.pressed.connect(func(): _add_player_at_index(2))
	add_button_3.pressed.connect(func(): _add_player_at_index(3))

	confirm_button.pressed.connect(_on_confirm_pressed)

func _create_player_panel() -> Control:
	var panel_scene = preload("res://scenes/ui/PlayerSelectPanel.tscn")
	var panel = panel_scene.instantiate()

	if "all_stratagems" in panel:
		panel.set("all_stratagems", all_stratagems)
	else:
		print("⚠️ Panel does not have 'all_stratagems'")

	return panel


func _add_player_at_index(index: int):
	if current_player_count >= MAX_PLAYERS:
		print("⚠️ Max players already added.")
		return

	# Remove the button at that index and replace with a panel
	var button = player_row.get_child(index)
	player_row.remove_child(button)
	button.queue_free()

	var panel = _create_player_panel()
	player_row.add_child(panel)
	player_row.move_child(panel, index)

	current_player_count += 1

func _on_confirm_pressed():
	print("✅ FINALIZED SQUAD:")
	for child in player_row.get_children():
		if child.has_method("get_player_data"):
			var data = child.get_player_data()
			print("▶️ Player:", data.name)
			for strat in data.strategems:
				print("   -", strat.name)
