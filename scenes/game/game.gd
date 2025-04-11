extends Control

# HUD & UI nodes
@onready var player_list = $PlayerList
@onready var stratagem_display = $StratagemDisplay
@onready var current_tile = $CurrentTile
@onready var next_turn_button = $NextTurnButton

# Player HUD
@onready var name_label = $background/playerHUD/NameLabel
@onready var health_bar = $background/playerHUD/HealthBar
@onready var stim_button = $background/playerHUD/StimButton
@onready var stim_count_label = $background/playerHUD/StimCountLabel

# Tokens (tiles)
@onready var tokens := [
	$background/Token1, $background/Token2, $background/Token3, $background/Token4, $background/Token5,
	$background/Token6, $background/Token7, $background/Token8, $background/Token9, $background/Token10,
	$background/Token11, $background/Token12, $background/Token13, $background/Token14, $background/Token15,
	$background/Token16, $background/Token17, $background/Token18, $background/Token19, $background/Token20
]

var players = []
var current_player_index := 0
var original_sizes := {}

var selected_stratagem = null
var selected_strat_button = null
var targeted_tiles: Array = []
var last_previewed_target_index := -1
var preview_tweens := {}

func _ready():
	players = PlayerManager.players.duplicate()
	if players.is_empty():
		return

	next_turn_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	next_turn_button.pressed.connect(_on_next_turn_pressed)

	stim_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	stim_button.pressed.connect(_on_stim_pressed)
	stim_button.connect("mouse_entered", Callable(self, "_on_mouse_entered_button").bind(stim_button))
	stim_button.connect("mouse_exited", Callable(self, "_on_mouse_exited_button").bind(stim_button))
	original_sizes[stim_button] = stim_button.scale

	for i in range(tokens.size()):
		var token = tokens[i]
		token.mouse_filter = Control.MOUSE_FILTER_STOP
		token.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		token.connect("mouse_entered", Callable(self, "_on_token_mouse_entered").bind(i))
		token.connect("mouse_exited", Callable(self, "_on_token_mouse_exited").bind(i))
		token.connect("gui_input", Callable(self, "_on_token_gui_input").bind(i))
		original_sizes[token] = token.scale

	_render_players()
	_update_turn()

func _on_token_mouse_entered(index: int) -> void:
	var token = tokens[index]
	if selected_stratagem:
		_preview_tile_target(index)
	else:
		_scale_token_to(token, original_sizes[token] * 1.2)

func _on_token_mouse_exited(index: int) -> void:
	if not targeted_tiles.has(index):
		var token = tokens[index]
		_scale_token_to(token, original_sizes[token])
	_reset_preview_tiles()

func _on_token_gui_input(event: InputEvent, index: int) -> void:
	var token = tokens[index]
	if event is InputEventMouseButton and event.pressed:
		var player = players[current_player_index]
		var current_tile: int = player.current_place
		if selected_stratagem:
			var target_tile := index
			if abs(target_tile - current_tile) <= selected_stratagem.range:
				var affected = _get_affected_tiles(selected_stratagem, target_tile)
				for i in affected:
					if selected_stratagem.type == "Scan":
						_fade_out_token(tokens[i])  # Only fade if it's a Scan stratagem
					else:
						_reset_tile_scale(tokens[i])
				print("💣 Tile", target_tile + 1, "hit by", selected_stratagem.name)
				_deselect_stratagem()
			else:
				print("❌ Out of range")
		else:
			# Only allow moving (and fading) when no stratagem is selected
			_fade_out_token(token)
			player.current_place = index
			_update_turn()

func _on_mouse_entered_button(button: Control):
	_scale_token_to(button, original_sizes[button] * 1.2)

func _on_mouse_exited_button(button: Control):
	if selected_strat_button != button:
		_scale_token_to(button, original_sizes[button])

func _scale_token_to(control: Control, target_scale: Vector2):
	var tween := create_tween()
	tween.tween_property(control, "scale", target_scale, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _pulse_token(token: Control):
	var tween := create_tween()
	tween.set_loops()  # loop forever
	tween.tween_property(token, "scale", original_sizes[token] * 1.25, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(token, "scale", original_sizes[token], 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	preview_tweens[token] = tween

func _create_label(text: String, size: int = 20, color: Color = Color.WHITE) -> Label:
	var label = Label.new()
	label.text = text
	var settings = LabelSettings.new()
	settings.font_size = size
	settings.font_color = color
	label.label_settings = settings
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
	current_tile.text = "Current Tile: " + str(player.current_place + 1)

	var tile_settings = LabelSettings.new()
	tile_settings.font_size = 60
	current_tile.label_settings = tile_settings

	name_label.text = player.name
	var name_settings = LabelSettings.new()
	name_settings.font_size = 30
	name_label.label_settings = name_settings

	update_health(player.health)
	stim_count_label.text = str(player.stims) + " / 3"

	selected_stratagem = null
	selected_strat_button = null
	_reset_preview_tiles()

	if stratagem_display is HBoxContainer:
		stratagem_display.add_theme_constant("separation", 50)

	for child in stratagem_display.get_children():
		child.queue_free()

	for strat in player.stratagems:
		var button = TextureButton.new()
		button.texture_normal = strat.icon
		button.tooltip_text = strat.name + "\n" + strat.description
		button.custom_minimum_size = Vector2(90, 105)
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(func(): _toggle_stratagem(strat, button))

		button.connect("mouse_entered", Callable(self, "_on_mouse_entered_button").bind(button))
		button.connect("mouse_exited", Callable(self, "_on_mouse_exited_button").bind(button))
		original_sizes[button] = button.scale

		stratagem_display.add_child(button)

		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(30, 0)
		stratagem_display.add_child(spacer)

	_render_players()

func _toggle_stratagem(strat, button: TextureButton):
	if selected_stratagem == strat:
		_deselect_stratagem()
	else:
		_deselect_stratagem()
		selected_stratagem = strat
		selected_strat_button = button
		_scale_token_to(button, original_sizes[button] * 1.2)

func _preview_tile_target(target_index: int):
	if target_index == last_previewed_target_index:
		return
	last_previewed_target_index = target_index
	_reset_preview_tiles()
	var player = players[current_player_index]
	var current_tile: int = player.current_place

	if abs(target_index - current_tile) <= selected_stratagem.range:
		var affected = _get_affected_tiles(selected_stratagem, target_index)
		for j in affected:
			if j >= 0 and j < tokens.size():
				_pulse_token(tokens[j])
				targeted_tiles.append(j)

func _reset_preview_tiles():
	for i in targeted_tiles:
		if preview_tweens.has(tokens[i]):
			preview_tweens[tokens[i]].kill()
		if original_sizes.has(tokens[i]):
			tokens[i].scale = original_sizes[tokens[i]]
	last_previewed_target_index = -1
	preview_tweens.clear()
	targeted_tiles.clear()

func _deselect_stratagem():
	if selected_strat_button:
		_scale_token_to(selected_strat_button, original_sizes[selected_strat_button])
	selected_stratagem = null
	selected_strat_button = null
	_reset_preview_tiles()

func _get_affected_tiles(strat, origin_tile: int) -> Array:
	var affected_tiles = []
	if strat.blast_radius > 0:
		for offset in range(-strat.blast_radius, strat.blast_radius + 1):
			var idx = origin_tile + offset
			if idx >= 0 and idx < tokens.size():
				affected_tiles.append(idx)
	elif strat.blast_forward > 0:
		for i in range(strat.blast_forward + 1):
			var idx = origin_tile + i
			if idx >= 0 and idx < tokens.size():
				affected_tiles.append(idx)
	elif strat.area_impact > 0:
		if origin_tile >= 0 and origin_tile < tokens.size():
			affected_tiles.append(origin_tile)
	return affected_tiles

func _reset_tile_scale(token: TextureRect):
	if original_sizes.has(token):
		_scale_token_to(token, original_sizes[token])

func update_health(new_health: int):
	var player = players[current_player_index]
	player.health = new_health
	var tween = create_tween()
	tween.tween_property(health_bar, "value", new_health, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_stim_pressed():
	var player = players[current_player_index]
	if player.stims > 0 and player.health < 100:
		player.stims -= 1
		update_health(100)
		stim_count_label.text = str(player.stims) + " / 3"
		stim_button.disabled = (player.stims <= 0)

func _on_next_turn_pressed():
	current_player_index = (current_player_index + 1) % players.size()
	_update_turn()

func _on_damage_pressed():
	var player = players[current_player_index]
	if player.health > 0:
		player.health = max(0, player.health - 10)
		update_health(player.health)

func _fade_out_token(token: TextureRect):
	var tween = create_tween()
	tween.tween_property(token, "modulate:a", 0.0, 0.5)
	tween.tween_callback(Callable(token, "hide"))
