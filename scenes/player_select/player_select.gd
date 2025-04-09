extends Control

const PlayerSelectPanel = preload("res://scenes/ui/PlayerSelectPanel.gd")

@onready var player_row = $MarginContainer/VBoxContainer/PlayerRow
@onready var confirm_button = $MarginContainer/VBoxContainer/ConfirmButton

@onready var add_button_1 = $MarginContainer/VBoxContainer/PlayerRow/Addbutton1
@onready var add_button_2 = $MarginContainer/VBoxContainer/PlayerRow/Addbutton2
@onready var add_button_3 = $MarginContainer/VBoxContainer/PlayerRow/Addbutton3

var all_stratagems: Array[Stratagem] = [
	preload("res://scripts/data/stratagems/Napalm.tres"),
	preload("res://scripts/data/stratagems/Orbital Barage.tres"),
	preload("res://scripts/data/stratagems/Napalm Eagle.tres"),
	preload("res://scripts/data/stratagems/Smoke Eagle.tres"),
	preload("res://scripts/data/stratagems/Orbital Scan.tres"),
	preload("res://scripts/data/stratagems/Eagle Bullet Rain.tres"),
	preload("res://scripts/data/stratagems/Eagle Drone.tres"),
	preload("res://scripts/data/stratagems/Orbital Nuke.tres")
]

var current_player_count := 0
const MAX_PLAYERS := 4

func _ready():
	add_button_1.pressed.connect(func(): _add_player_panel(add_button_1))
	add_button_2.pressed.connect(func(): _add_player_panel(add_button_2))
	add_button_3.pressed.connect(func(): _add_player_panel(add_button_3))

	confirm_button.pressed.connect(_on_confirm_pressed)

	# Add the first player panel by default
	_add_player_panel(null)

func _create_player_panel() -> Control:
	var panel_scene = preload("res://scenes/ui/PlayerSelectPanel.tscn")
	var panel = panel_scene.instantiate()

	if panel.has_method("set_all_stratagems"):
		panel.set_all_stratagems(all_stratagems)
	else:
		print("⚠️ Panel does not have 'set_all_stratagems' method")

	return panel

func _add_player_panel(trigger_button: Button):
	if current_player_count >= MAX_PLAYERS:
		print("⚠️ Max players reached.")
		return

	if trigger_button != null:
		trigger_button.queue_free()  # Remove the clicked button

	var panel = _create_player_panel()

	# Insert before the first remaining add button (if any)
	var insert_index := player_row.get_child_count()
	for i in range(player_row.get_child_count()):
		var child = player_row.get_child(i)
		if child is Button:
			insert_index = i
			break

	player_row.add_child(panel)
	player_row.move_child(panel, insert_index)

	current_player_count += 1

func _on_confirm_pressed():
	# Access the autoloaded PlayerManager directly (no preload)
	PlayerManager.clear_players()

	for child in player_row.get_children():
		if child.has_method("get_player_data"):
			var data = child.get_player_data()

			var player = Player.new()
			player.name = data.name
			player.health = 100
			player.weapon = "Liberator"
			player.stratagems = data.strategems
			player.current_place = 0

			PlayerManager.add_player(player)

			print("✅ Player added:", player.name)
			for strat in player.stratagems:
				print("   -", strat.name)

	get_tree().change_scene_to_file("res://scenes/automatonintro/AutomatonIntro.tscn")
