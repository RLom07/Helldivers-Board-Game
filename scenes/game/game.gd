extends Control

@onready var player_list = $PlayerList
@onready var stratagem_display = $StratagemDisplay
@onready var turn_label = $TurnLabel
@onready var next_turn_button = $NextTurnButton

@onready var name_label = $background/playerHUD/NameLabel
@onready var health_bar = $background/playerHUD/HealthBar
@onready var health_label = $background/playerHUD/HealthLabel
@onready var stim_button = $background/playerHUD/StimButton

@onready var tokens := [
	$background/Token1, $background/Token2, $background/Token3, $background/Token4, $background/Token5,
	$background/Token6, $background/Token7, $background/Token8, $background/Token9, $background/Token10,
	$background/Token11, $background/Token12, $background/Token13, $background/Token14, $background/Token15,
	$background/Token16, $background/Token17, $background/Token18, $background/Token19, $background/Token20
]

var players = []
var current_player_index := 0

func _ready():
	players = PlayerManager.players.duplicate()
	print("🧠 Players loaded:", players.size())
	if players.is_empty():
		print("⚠️ No players found.")
		return

	next_turn_button.pressed.connect(_on_next_turn_pressed)
	stim_button.pressed.connect(_on_stim_pressed)

	for i in tokens.size():
		var token = tokens[i]
		token.mouse_filter = Control.MOUSE_FILTER_STOP
		token.connect("gui_input", Callable(self, "_on_token_clicked").bind(i))

	_render_players()
	_update_turn()

func _create_label(text: String, size: int = 20, color: Color = Color.WHITE) -> Label:
	var label = Label.new()
	label.text = text
	var settings = LabelSettings.new()
	settings.font_size = size
	label.label_settings = settings
	label.add_theme_color_override("font_color", color)
	return label

func _render_players():
	for child in player_list.get_children():
		child.queue_free()

	var title = _create_label("Players:", 30, Color.YELLOW)
	player_list.add_child(title)

	for i in range(players.size()):
		var color = Color.LIGHT_GREEN if i == current_player_index else Color.WHITE
		var label = _create_label(players[i].name, 30, color)
		player_list.add_child(label)

		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 15)
		player_list.add_child(spacer)

func _update_turn():
	var player = players[current_player_index]
	turn_label.text = player.name + " your turn to spread Democracy!"

	var turn_settings = LabelSettings.new()
	turn_settings.font_size = 40
	turn_label.label_settings = turn_settings

	# HUD update
	name_label.text = player.name
	update_health(player.health)

	for child in stratagem_display.get_children():
		child.queue_free()

	for strat in player.stratagems:
		var button = TextureButton.new()
		button.texture_normal = strat.icon
		button.tooltip_text = strat.name + "\n" + strat.description
		button.custom_minimum_size = Vector2(96, 96)
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.pressed.connect(func():
			print("💥", player.name, "used", strat.name)
		)
		button.add_theme_constant_override("margin_right", 10)
		stratagem_display.add_child(button)

	_render_players()

func update_health(new_health: int):
	var player = players[current_player_index]
	player.health = new_health
	health_label.text = str(new_health) + " / 100"

	var tween = create_tween()
	tween.tween_property(health_bar, "value", new_health, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_stim_pressed():
	var player = players[current_player_index]
	if player.health < 100:
		print("💉", player.name, "used a stim!")
		update_health(100)

func _on_next_turn_pressed():
	current_player_index += 1
	if current_player_index >= players.size():
		current_player_index = 0

	_update_turn()

func _on_token_clicked(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		_fade_out_token(tokens[index])
		players[current_player_index].current_place = index
		print("📍", players[current_player_index].name, "moved to", index + 1)

		match index:
			0: on_token1_clicked()
			1: on_token2_clicked()
			2: on_token3_clicked()
			3: on_token4_clicked()
			4: on_token5_clicked()
			5: on_token6_clicked()
			6: on_token7_clicked()
			7: on_token8_clicked()
			8: on_token9_clicked()
			9: on_token10_clicked()
			10: on_token11_clicked()
			11: on_token12_clicked()
			12: on_token13_clicked()
			13: on_token14_clicked()
			14: on_token15_clicked()
			15: on_token16_clicked()
			16: on_token17_clicked()
			17: on_token18_clicked()
			18: on_token19_clicked()
			19: on_token20_clicked()

func _fade_out_token(token: TextureRect):
	var tween = create_tween()
	tween.tween_property(token, "modulate:a", 0.0, 0.5)
	tween.tween_callback(Callable(token, "hide"))

# Placeholder token functions
func on_token1_clicked(): pass
func on_token2_clicked(): pass
func on_token3_clicked(): pass
func on_token4_clicked(): pass
func on_token5_clicked(): pass
func on_token6_clicked(): pass
func on_token7_clicked(): pass
func on_token8_clicked(): pass
func on_token9_clicked(): pass
func on_token10_clicked(): pass
func on_token11_clicked(): pass
func on_token12_clicked(): pass
func on_token13_clicked(): pass
func on_token14_clicked(): pass
func on_token15_clicked(): pass
func on_token16_clicked(): pass
func on_token17_clicked(): pass
func on_token18_clicked(): pass
func on_token19_clicked(): pass
func on_token20_clicked(): pass
