extends Control

@onready var player_list = $PlayerList
@onready var stratagem_display = $StratagemDisplay
@onready var turn_label = $TurnLabel
@onready var next_turn_button = $NextTurnButton

var players = []
var current_player_index := 0

func _ready():
	players = PlayerManager.players.duplicate()
	print("🧠 Players loaded:", players.size())
	if players.is_empty():
		print("⚠️ No players found.")
		return

	next_turn_button.pressed.connect(_on_next_turn_pressed)

	_render_players()
	_update_turn()

func _render_players():
	for child in player_list.get_children():
		child.queue_free()

	var title = Label.new()
	title.text = "🧑 Players:"
	player_list.add_child(title)

	for i in range(players.size()):
		var label = Label.new()
		label.text = players[i].name
		if i == current_player_index:
			label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
		player_list.add_child(label)

func _update_turn():
	var player = players[current_player_index]
	turn_label.text = "🎯 Current Turn: " + player.name

	for child in stratagem_display.get_children():
		child.queue_free()

	for strat in player.stratagems:
		var button = TextureButton.new()
		button.texture_normal = strat.icon
		button.tooltip_text = strat.name + "\n" + strat.description
		button.pressed.connect(func():
			print("💥", player.name, "used", strat.name)
		)
		stratagem_display.add_child(button)

	_render_players()  # Refresh highlight

func _on_next_turn_pressed():
	current_player_index += 1
	if current_player_index >= players.size():
		current_player_index = 0

	_update_turn()
