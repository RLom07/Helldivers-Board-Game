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

@onready var enemy_tokens := {
	2: $background/EnemyMarauder1,
	4: $background/EnemyCommissar1,
	6: $background/EnemyMarauder2,
	8: $background/EnemyDevastator1,
	11: $background/EnemyHulk1,
	14: $background/EnemyCommissar2,
	15: $background/EnemyHulk2,
	16: $background/EnemyTank1,
	17: $background/EnemyTank2,
	18: $background/EnemyDevastator2
}

var players = []
var current_player_index := 0
var original_sizes := {}
var round_turn_counter := 0

var selected_stratagem = null
var selected_strat_button = null
var targeted_tiles: Array = []
var last_previewed_target_index := -1
var preview_tweens := {}

# Enemies
var enemies: Array = []
var enemy_tile_map: Dictionary = {}

#Mission
var mission_tile_index = 12
var mission_player: Player = null
var mission_turns_remaining := 3
var mission_complete := false
var mission_random_enemy: Enemy = null
var is_mission_combat := false

# Extraction logic
var extraction_tile_index := 19 
var extraction_active := false
var extraction_turns_remaining := -1
var extraction_triggered_by: Player = null

func _ready():
	randomize()
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

	for index in enemy_tokens.keys():
		var enemy_token = enemy_tokens[index]
		enemy_token.mouse_filter = Control.MOUSE_FILTER_STOP
		enemy_token.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		enemy_token.connect("mouse_entered", Callable(self, "_on_token_mouse_entered").bind(index))
		enemy_token.connect("mouse_exited", Callable(self, "_on_token_mouse_exited").bind(index))
		enemy_token.connect("gui_input", Callable(self, "_on_token_gui_input").bind(index))
		original_sizes[enemy_token] = enemy_token.scale


	_create_enemies()
	_render_players()
	_update_turn()

func _on_token_mouse_entered(index: int) -> void:
	var token: Control = tokens[index]
	if enemy_tokens.has(index) and not tokens[index].visible:
		token = enemy_tokens[index]



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
	if event is InputEventMouseButton and event.pressed:
		var player = players[current_player_index]
		var current_tile: int = player.current_place

		if selected_stratagem:
			var target_tile := index
			if abs(target_tile - current_tile) <= selected_stratagem.range:
				var affected = _get_affected_tiles(selected_stratagem, target_tile)
				if selected_stratagem.type == "Scan":
					for i in affected:
						if i != mission_tile_index and i != extraction_tile_index:
							_fade_out_token(tokens[i])

				else:
					_apply_stratagem_to_tiles(selected_stratagem, affected)

				print("💣 Tile", target_tile + 1, "hit by", selected_stratagem.name)

				# Set cooldown AFTER use
				if selected_stratagem.name != "Reinforce":
					selected_stratagem.cooldown_counter = selected_stratagem.cooldown

				_deselect_stratagem()
				_update_turn()
			else:
				print("❌ Out of range")
		else:
			# No stratagem selected: Move the player
			player.current_place = index

			if enemy_tokens.has(index):
				var enemy_token = enemy_tokens[index]
				enemy_token.visible = true
				_fade_out_token(tokens[index])
				var enemy: Enemy = enemy_tile_map.get(index, null)
				if enemy and not enemy.isdefeated:
					await get_tree().create_timer(2.0).timeout
					_show_enemy_encounter(enemy)
			else:
				if index != mission_tile_index and index != extraction_tile_index:
					_fade_out_token(tokens[index])

			_update_turn()


		# 🔁 Reset visual hover effects
		for i in range(tokens.size()):
			var tok = tokens[i]
			if preview_tweens.has(tok):
				preview_tweens[tok].kill()
			if original_sizes.has(tok):
				tok.scale = original_sizes[tok]

		for idx in enemy_tokens:
			var tok = enemy_tokens[idx]
			if preview_tweens.has(tok):
				preview_tweens[tok].kill()
			if original_sizes.has(tok):
				tok.scale = original_sizes[tok]

		preview_tweens.clear()

func _apply_stratagem_to_tiles(strat, tiles: Array):
	if strat.type == "Scan" or strat.name == "Reinforce":
		return

	var result = strat.process_attack(tiles as Array[int], players, enemy_tile_map)

	# Apply friendly fire damage to players on affected tiles
	for tile_index in tiles:
		for player in players:
			if player.current_place == tile_index and not player.is_dead:
				player.health = max(0, player.health - 25)
				print("💥 Friendly fire! ", player.name, " took 25 damage from ", strat.name, " on tile", tile_index + 1)
				if player.health <= 0:
					player.is_dead = true
					print("💀", player.name, "was killed by friendly fire!")
				if players[current_player_index] == player:
					update_health(player.health)

	# Update visuals and defeated tokens
	for i in result["defeated_tiles"]:
		if enemy_tokens.has(i):
			var token = enemy_tokens[i]
			token.visible = true
			token.modulate.a = 0.6

	_show_stratagem_impact(result["hidden_hits"], result["revealed_hit_names"])


func _on_mouse_entered_button(button: Control):
	if not original_sizes.has(button):
		return
	_scale_token_to(button, original_sizes[button] * 1.2)


func _on_mouse_exited_button(button: Control):
	if not original_sizes.has(button):
		return
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
		if players[i].is_dead:
			label.modulate.a = 0.5  # 50% opacity

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
		button.custom_minimum_size = Vector2(90, 105)
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		original_sizes[button] = button.scale

		# Determine if the stratagem is in cooldown or used (for Reinforce)
		var in_cooldown = strat.cooldown_counter > 0 or (strat.name == "Reinforce" and player.reinforce_used)

		# Set opacity based on cooldown
		button.modulate.a = 0.6 if in_cooldown else 1.0

		# Set tooltip based on cooldown or Reinforce usage
		if strat.name == "Reinforce" and player.reinforce_used:
			button.tooltip_text = "Already been used"
		elif strat.cooldown_counter > 0:
			button.tooltip_text = strat.name + "\n" + strat.description + "\nCooldown: " + str(strat.cooldown_counter) + " turn(s)"
		else:
			button.tooltip_text = strat.name + "\n" + strat.description

		# Only allow interaction if it's not in cooldown or already used
		if not in_cooldown:
			button.pressed.connect(func(): _toggle_stratagem(strat, button))
			button.connect("mouse_entered", Callable(self, "_on_mouse_entered_button").bind(button))
			button.connect("mouse_exited", Callable(self, "_on_mouse_exited_button").bind(button))

		stratagem_display.add_child(button)

		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(30, 0)
		stratagem_display.add_child(spacer)

	_render_players()
	_check_mission_tile_logic(players[current_player_index])
	_check_extraction_tile_logic(player)
	
func _show_extraction_countdown():
	var scene = preload("res://scenes/ui/ExtractionCountdown.tscn")
	var instance = scene.instantiate()
	add_child(instance)
	instance.setup(extraction_turns_remaining)
	instance.continue_pressed.connect(func():
		print("✅ Extraction countdown acknowledged.")
	)
	print("📢 Showing extraction countdown to", players[current_player_index].name)

func _check_extraction_tile_logic(player: Player):
	if extraction_active or player.is_dead:
		return

	if player.current_place == extraction_tile_index:
		_show_extraction_prompt()


func _toggle_stratagem(strat, button: TextureButton):
	# If the same stratagem is clicked again, deselect it
	if selected_stratagem == strat:
		_deselect_stratagem()
		return

	_deselect_stratagem()

	var player = players[current_player_index]

	if strat.name == "Reinforce":
		if player.reinforce_used:
			print("🚫", player.name, "has already used Reinforce.")
			return
		_show_reinforce_menu(player)
		# ❌ Don't set reinforce_used here
	else:
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
				var token: Control = tokens[j]
				if enemy_tokens.has(j) and not tokens[j].visible:
					# Enemy token only pulses if number token is hidden (revealed)
					token = enemy_tokens[j]
				elif not tokens[j].visible:
					continue  # skip if both tokens are hidden
				_pulse_token(token)
				targeted_tiles.append(j)

func _reset_preview_tiles():
	for i in targeted_tiles:
		var token: Control = tokens[i]
		if enemy_tokens.has(i) and not tokens[i].visible:
			token = enemy_tokens[i]

		if preview_tweens.has(token):
			preview_tweens[token].kill()
		if original_sizes.has(token):
			token.scale = original_sizes[token]
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
	var previous_index = current_player_index
	var total_players := players.size()

	# Zoek de volgende levende speler
	var attempts := 0
	while attempts < total_players:
		current_player_index = (current_player_index + 1) % total_players
		if not players[current_player_index].is_dead:
			break
		attempts += 1

	# ✅ Check if all Helldivers are dead
	if players.all(func(p): return p.is_dead):
		_handle_game_over_all_dead()
		return

	# ✅ Show extraction countdown if it's the activating player's turn
	if extraction_active and players[current_player_index] == extraction_triggered_by:
		_show_extraction_countdown()

	# ✅ Volledige ronde afgelopen
	if current_player_index < previous_index or (current_player_index == 0 and previous_index == total_players - 1):
		print("🔁 Full round completed! Decreasing cooldowns...")

		if extraction_active:
			extraction_turns_remaining -= 1
			print("📉 Extraction turns remaining:", extraction_turns_remaining)

			if extraction_turns_remaining <= 0:
				print("🚁 Extraction has arrived! Handling endgame...")
				_handle_extraction_end()
				return  # Stop further turn progression

		# 🔃 Cooldowns
		for player in players:
			for strat in player.stratagems:
				if strat.cooldown_counter > 0:
					strat.cooldown_counter -= 1

		# ✅ Missie-aanval: als missie actief is en spelers op de tegel staan
		if not mission_complete:
			var players_on_tile := players.filter(func(p): return p.current_place == mission_tile_index and not p.is_dead)

			if players_on_tile.size() > 0:
				# Als huidige missie speler niet op de tegel staat, wissel
				if not players_on_tile.has(mission_player):
					mission_player = players_on_tile[0]
					print("🔄 New mission player:", mission_player.name)

				# Start full combat with a random enemy on the mission tile
				var base_enemy: Enemy = mission_enemies[randi() % mission_enemies.size()]
				var random_enemy: Enemy = Enemy.new()
				random_enemy.name = base_enemy.name
				random_enemy.health = base_enemy.health
				random_enemy.attacks = base_enemy.attacks.duplicate()
				random_enemy.weakness = base_enemy.weakness
				random_enemy.resistance = base_enemy.resistance

				print("⚔️ Mission combat triggered against:", random_enemy.name)

				# Save the enemy so we can handle it properly in the encounter
				mission_random_enemy = random_enemy
				is_mission_combat = true

				await get_tree().create_timer(1.5).timeout
				_show_enemy_encounter(random_enemy)

				if mission_player.health <= 0:
					mission_player.is_dead = true
					print("💀", mission_player.name, "died during mission!")

					# Probeer nieuwe missie speler aan te wijzen
					var still_on_tile := players.filter(func(p): return p.current_place == mission_tile_index and not p.is_dead)
					if still_on_tile.size() > 0:
						mission_player = still_on_tile[0]
						print("🆕 New mission player after death:", mission_player.name)
					else:
						mission_player = null
						print("❌ No players left on mission tile. Mission halted.")

				update_health(players[current_player_index].health)

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

func _on_tank_encounter_choice(choice: String) -> void:
	var player = players[current_player_index]
	var tile_index: int = player.current_place

	var enemy: Enemy

	if is_mission_combat:
		enemy = mission_random_enemy
	else:
		if not enemy_tile_map.has(tile_index):
			print("⚠️ No enemy found on tile", tile_index)
			return
		enemy = enemy_tile_map[tile_index]


	if choice == "fight":
		_show_fight_dice_roll(enemy, tile_index)
	elif choice == "flight":
		_show_flight_dice_roll(enemy, player, tile_index)

func _show_flight_dice_roll(enemy: Enemy, player: Player, tile_index: int):
	var flight_scene = preload("res://scenes/ui/FlightDiceRoll.tscn")
	var flight_instance = flight_scene.instantiate()
	add_child(flight_instance)
	flight_instance.setup(enemy)
	flight_instance.flight_attempt_result.connect(func(success: bool):
		_on_flight_result(success, enemy, player, tile_index)
	)

func _on_flight_result(success: bool, enemy: Enemy, player: Player, tile_index: int):
	if success:
		var safe_tile = _find_safe_tile()
		player.current_place = safe_tile

		# 🔁 FULL HOVER/PULSE RESET (tokens + enemy_tokens)
		for i in range(tokens.size()):
			var tok = tokens[i]
			if preview_tweens.has(tok):
				preview_tweens[tok].kill()
			if original_sizes.has(tok):
				tok.scale = original_sizes[tok]

		for idx in enemy_tokens:
			var tok = enemy_tokens[idx]
			if preview_tweens.has(tok):
				preview_tweens[tok].kill()
			if original_sizes.has(tok):
				tok.scale = original_sizes[tok]

		preview_tweens.clear()

		_update_turn()
		_show_flee_result(enemy, player, success, tile_index, safe_tile)
	else:
		var attack = enemy.attacks[randi() % enemy.attacks.size()]
		player.health = max(0, player.health - attack.damage)
		if player.health <= 0:
			player.is_dead = true
			print("💀", player.name, "has died while fleeing!")
			_next_alive_player()


		update_health(player.health)
		_show_flee_result(enemy, player, success, tile_index, tile_index)

func _show_flee_result(enemy: Enemy, player: Player, success: bool, tile_index: int, safe_tile_index: int):
	var scene = preload("res://scenes/ui/FleeResult.tscn")
	var instance = scene.instantiate()
	add_child(instance)

	instance.setup(success, enemy, tile_index, player, safe_tile_index)

	instance.continue_pressed.connect(func(_enemy, _tile_index):
		if not success:
			if player.health > 0:
				_show_enemy_encounter(enemy)
			else:
				print("💀 Player has died!")
		else:
			print("✅ Escape successful")
	)
	
func _find_safe_tile() -> int:
	for i in range(tokens.size()):
		if not enemy_tile_map.has(i):
			return i
	return 0  # fallback

func _show_enemy_encounter(enemy: Enemy):
	var scene_path := ""
	match String(enemy.name):  # <-- 🔧 This fixes your mission combat bug!
		"Annihilator Tank":
			scene_path = "res://scenes/ui/TankEncounter.tscn"
		"Commissar":
			scene_path = "res://scenes/ui/CommissarEncounter.tscn"
		"Devastator":
			scene_path = "res://scenes/ui/DevastatorEncounter.tscn"
		"Hulk":
			scene_path = "res://scenes/ui/HulkEncounter.tscn"
		"Marauder":
			scene_path = "res://scenes/ui/MarauderEncounter.tscn"
		_:
			print("⚠️ No encounter scene for", enemy.name)
			return
		
	var ENEMY_SCENE_PATHS = {
	"Annihilator Tank": "res://scenes/ui/TankEncounter.tscn",
	"Commissar": "res://scenes/ui/CommissarEncounter.tscn",
	"Devastator": "res://scenes/ui/DevastatorEncounter.tscn",
	"Hulk": "res://scenes/ui/HulkEncounter.tscn",
	"Marauder": "res://scenes/ui/MarauderEncounter.tscn"
	}

	var encounter_scene = load(scene_path)
	var encounter_instance = encounter_scene.instantiate()
	add_child(encounter_instance)
	encounter_instance.encounter_choice_made.connect(_on_tank_encounter_choice)

func _show_fight_dice_roll(enemy: Enemy, tile_index: int):
	var fight_scene = preload("res://scenes/ui/FightDiceRoll.tscn")
	var fight_instance = fight_scene.instantiate()
	add_child(fight_instance)
	fight_instance.setup(enemy)
	fight_instance.dice_roll_result.connect(_on_dice_roll_result.bind(enemy, tile_index))

func _on_dice_roll_result(damage: int, enemy: Enemy, tile_index: int) -> void:
	var player = players[current_player_index]
	enemy.health -= damage
	print("🗡️", enemy.name, "takes", damage, "damage! Remaining HP:", enemy.health)

	var is_defeated = enemy.health <= 0
	if is_defeated:
		enemy.isdefeated = true
		if not is_mission_combat and enemy_tokens.has(tile_index):
			var token = enemy_tokens[tile_index]
			token.modulate.a = 0.6  # 60% opacity
		print("💀", enemy.name, "defeated!")


	# Check if player died (e.g., from previous attack or special logic)
	if player.health <= 0:
		player.is_dead = true
		print("💀", player.name, "has died!")
		_next_alive_player()
		return

	_show_combat_result(damage, is_defeated, enemy, tile_index)

func _show_combat_result(damage: int, is_defeated: bool, enemy: Enemy, tile_index: int) -> void:
	var result_scene = preload("res://scenes/ui/CombatResult.tscn")
	var result_instance = result_scene.instantiate()
	add_child(result_instance)
	var player = players[current_player_index]
	result_instance.setup(enemy, damage, tile_index, player)

	result_instance.continue_pressed.connect(func (_enemy, _tile_index):
		update_health(player.health)

		if player.health <= 0:
			player.is_dead = true
			print("💀", player.name, "has died!")
			_next_alive_player()
			return


		if not _enemy.isdefeated:
			_show_enemy_encounter(enemy)
		else:
			print("✅ Combat over.")
	)

var mission_enemies: Array = []

func _create_enemies():
	# Tanks (already done correctly)
	var tank1 = Enemy.new()
	tank1.name = "Annihilator Tank"
	tank1.health = 150
	tank1.attacks = [
		{ "name": "Cannon Blast", "damage": 40, "description": "Fires a powerful cannon round at a target." },
		{ "name": "Missile Barrage", "damage": 25, "description": "Launches a barrage of guided missiles." }
	]
	tank1.weakness = "EMP"
	tank1.resistance = "Explosive"

	var tank2 = Enemy.new()
	tank2.name = "Annihilator Tank"
	tank2.health = 150
	tank2.attacks = [
		{ "name": "Cannon Blast", "damage": 40, "description": "Fires a powerful cannon round at a target." },
		{ "name": "Missile Barrage", "damage": 25, "description": "Launches a barrage of guided missiles." }
	]
	tank2.weakness = "EMP"
	tank2.resistance = "Explosive"

	# Commissars
	var commissar1 = Enemy.new()
	commissar1.name = "Commissar"
	commissar1.health = 180
	commissar1.attacks = [
		{ "name": "Inspiring Shot", "damage": 20, "description": "Shoots while boosting nearby allies." },
		{ "name": "Suppressive Fire", "damage": 15, "description": "Lays down suppressing fire in an area." }
	]
	commissar1.weakness = "Fire"
	commissar1.resistance = "Piercing"

	var commissar2 = Enemy.new()
	commissar2.name = "Commissar"
	commissar2.health = 180
	commissar2.attacks = [
		{ "name": "Inspiring Shot", "damage": 20, "description": "Shoots while boosting nearby allies." },
		{ "name": "Suppressive Fire", "damage": 15, "description": "Lays down suppressing fire in an area." }
	]
	commissar2.weakness = "Fire"
	commissar2.resistance = "Piercing"

	# Devastators
	var devastator1 = Enemy.new()
	devastator1.name = "Devastator"
	devastator1.health = 250
	devastator1.attacks = [
		{ "name": "Laser Beam", "damage": 35, "description": "Shoots a high-energy laser." },
		{ "name": "Shockwave Slam", "damage": 30, "description": "Slams the ground to create a damaging shockwave." }
	]
	devastator1.weakness = "Electric"
	devastator1.resistance = "Fire"

	var devastator2 = Enemy.new()
	devastator2.name = "Devastator"
	devastator2.health = 250
	devastator2.attacks = [
		{ "name": "Laser Beam", "damage": 35, "description": "Shoots a high-energy laser." },
		{ "name": "Shockwave Slam", "damage": 30, "description": "Slams the ground to create a damaging shockwave." }
	]
	devastator2.weakness = "Electric"
	devastator2.resistance = "Fire"

	# Hulks
	var hulk1 = Enemy.new()
	hulk1.name = "Hulk"
	hulk1.health = 400
	hulk1.attacks = [
		{ "name": "Smash", "damage": 45, "description": "Brings down a massive fist on its target." },
		{ "name": "Grab and Throw", "damage": 30, "description": "Grabs a player and throws them." }
	]
	hulk1.weakness = "Piercing"
	hulk1.resistance = "Blunt"

	var hulk2 = Enemy.new()
	hulk2.name = "Hulk"
	hulk2.health = 400
	hulk2.attacks = [
		{ "name": "Smash", "damage": 45, "description": "Brings down a massive fist on its target." },
		{ "name": "Grab and Throw", "damage": 30, "description": "Grabs a player and throws them." }
	]
	hulk2.weakness = "Piercing"
	hulk2.resistance = "Blunt"

	# Marauders
	var marauder1 = Enemy.new()
	marauder1.name = "Marauder"
	marauder1.health = 150
	marauder1.attacks = [
		{ "name": "Quick Stab", "damage": 20, "description": "Stabs quickly with sharp blades." },
		{ "name": "Poison Dart", "damage": 10, "description": "Fires a dart that poisons the target." }
	]
	marauder1.weakness = "Explosive"
	marauder1.resistance = "Electric"

	var marauder2 = Enemy.new()
	marauder2.name = "Marauder"
	marauder2.health = 150
	marauder2.attacks = [
		{ "name": "Quick Stab", "damage": 20, "description": "Stabs quickly with sharp blades." },
		{ "name": "Poison Dart", "damage": 10, "description": "Fires a dart that poisons the target." }
	]
	marauder2.weakness = "Explosive"
	marauder2.resistance = "Electric"
	
	# === ADD MISSION-ONLY ENEMIES ===
	var mission_commissar1 = Enemy.new()
	mission_commissar1.name = "Commissar"
	mission_commissar1.health = 180
	mission_commissar1.attacks = commissar1.attacks.duplicate()
	mission_commissar1.weakness = "Fire"
	mission_commissar1.resistance = "Piercing"

	var mission_commissar2 = Enemy.new()
	mission_commissar2.name = "Commissar"
	mission_commissar2.health = 180
	mission_commissar2.attacks = commissar1.attacks.duplicate()
	mission_commissar2.weakness = "Fire"
	mission_commissar2.resistance = "Piercing"

	var mission_devastator1 = Enemy.new()
	mission_devastator1.name = "Devastator"
	mission_devastator1.health = 250
	mission_devastator1.attacks = devastator1.attacks.duplicate()
	mission_devastator1.weakness = "Electric"
	mission_devastator1.resistance = "Fire"

	var mission_devastator2 = Enemy.new()
	mission_devastator2.name = "Devastator"
	mission_devastator2.health = 250
	mission_devastator2.attacks = devastator1.attacks.duplicate()
	mission_devastator2.weakness = "Electric"
	mission_devastator2.resistance = "Fire"

	var mission_marauder1 = Enemy.new()
	mission_marauder1.name = "Marauder"
	mission_marauder1.health = 150
	mission_marauder1.attacks = marauder1.attacks.duplicate()
	mission_marauder1.weakness = "Explosive"
	mission_marauder1.resistance = "Electric"

	var mission_marauder2 = Enemy.new()
	mission_marauder2.name = "Marauder"
	mission_marauder2.health = 150
	mission_marauder2.attacks = marauder1.attacks.duplicate()
	mission_marauder2.weakness = "Explosive"
	mission_marauder2.resistance = "Electric"

	# Add to enemy list (for debug/statistics)
	enemies.append_array([
		tank1, tank2,
		commissar1, commissar2,
		devastator1, devastator2,
		hulk1, hulk2,
		marauder1, marauder2
	])
	
	mission_enemies.append_array([
		mission_commissar1, mission_commissar2,
		mission_devastator1, mission_devastator2,
		mission_marauder1, mission_marauder2
	])

	# Assign to enemy tiles
	enemy_tile_map[2] = marauder1
	enemy_tile_map[4] = commissar1
	enemy_tile_map[6] = marauder2
	enemy_tile_map[8] = devastator1
	enemy_tile_map[11] = hulk1
	enemy_tile_map[14] = commissar2
	enemy_tile_map[15] = hulk2
	enemy_tile_map[16] = tank1
	enemy_tile_map[17] = tank2
	enemy_tile_map[18] = devastator2

	print("Enemies created:", enemies.size())

func _next_alive_player():
	var total_players := players.size()
	var attempts := 0

	while attempts < total_players:
		current_player_index = (current_player_index + 1) % total_players
		if not players[current_player_index].is_dead:
			break
		attempts += 1

	_update_turn()

func reinforce_player(from_player: Player, to_player: Player):
	if from_player.reinforce_used:
		print(from_player.name, "has already used their reinforcement.")
		return

	if not to_player.is_dead:
		print(to_player.name, "is not dead!")
		return

	# ✅ Play voice line
	var audio = AudioStreamPlayer.new()
	audio.stream = preload("res://assets/voice_lines/Reinforcementslauched.mp3")
	add_child(audio)
	audio.play()

	# ✅ Revive logic
	to_player.is_dead = false
	from_player.reinforce_used = true
	to_player.health = 100
	print("🛬", from_player.name, "reinforced", to_player.name)

	_update_turn()
	_render_players()

func _show_reinforce_menu(from_player: Player):
	var popup := PopupMenu.new()
	popup.name = "ReinforceMenu"

	for i in range(players.size()):
		if players[i].is_dead:
			popup.add_item(players[i].name, i)

	if popup.item_count == 0:
		print("🛡️ No dead players to reinforce.")
		return

	# ✅ Correct way to connect signal
	popup.connect("id_pressed", Callable(self, "_on_reinforce_selected").bind(from_player, popup))

	add_child(popup)
	popup.popup_centered()

func _on_reinforce_selected(id: int, from_player: Player, popup: PopupMenu):
	var to_player: Player = players[id]
	reinforce_player(from_player, to_player)

	# Clean up the popup
	if is_instance_valid(popup):
		remove_child(popup)
		popup.queue_free()

func _show_stratagem_impact(hidden_count: int, revealed_enemies: Array):
	var existing := get_node_or_null("StratagemImpact")
	if existing != null:
		existing.queue_free()

	var scene = preload("res://scenes/ui/StratagemImpact.tscn")
	var instance = scene.instantiate()
	instance.name = "StratagemImpact"  # for safety check above
	add_child(instance)

	instance.setup(hidden_count, revealed_enemies)
	instance.continue_pressed.connect(func():
		print("✅ Player continues after impact message.")
		instance.queue_free()
	)

func _check_mission_tile_logic(player: Player):
	if mission_complete:
		return

	if player.current_place == mission_tile_index:
		var players_on_tile := players.filter(func(p): return p.current_place == mission_tile_index and not p.is_dead)

		if mission_player == null:
			mission_player = player
			mission_turns_remaining = 3
			print("🛟", player.name, "started the evacuation mission!")
			_play_voice_line("res://assets/voice_lines/Important personnel - Sweet liberty, its the helldivers.mp3")

		elif player == mission_player:
			mission_turns_remaining -= 1
			print("🚨", player.name, "survived another turn on mission tile. Remaining:", mission_turns_remaining)
			_play_voice_line("res://assets/voice_lines/Important personnel - Sweet liberty, its the helldivers.mp3")

			if mission_turns_remaining <= 0:
				mission_complete = true
				print("✅ Mission completed by", player.name)
				_play_voice_line("res://assets/music/algemeen/#Objective completed music 2.mp3")
				tokens[mission_tile_index].modulate.a = 0.6

		elif mission_player != null:
			print("👥", player.name, "is supporting the mission.")
	else:
		if player == mission_player:
			var others_on_tile := players.filter(func(p): return p != player and p.current_place == mission_tile_index and not p.is_dead)
			if others_on_tile.size() > 0:
				mission_player = others_on_tile[0]
				print("🔄 Mission player switched to", mission_player.name)
			else:
				print("🏃", player.name, "fled the mission tile. Resetting mission.")
				mission_player = null
				mission_turns_remaining = 3

func _play_voice_line(path: String):
	var audio = AudioStreamPlayer.new()
	audio.stream = load(path)
	add_child(audio)
	audio.play()
	audio.connect("finished", Callable(audio, "queue_free"))

func _show_extraction_prompt():
	var scene = preload("res://scenes/ui/ExtractionPrompt.tscn")
	var instance = scene.instantiate()
	add_child(instance)
	instance.extraction_choice_made.connect(_on_extraction_choice)

	
func _on_extraction_choice(choice: bool):
	if choice:
		extraction_active = true
		extraction_turns_remaining = players.size()  # Everyone gets one more round
		extraction_triggered_by = players[current_player_index]

		# Stop current music
		for node in get_children():
			if node is AudioStreamPlayer and node.playing:
				node.stop()

		# Start extraction music
		var music = AudioStreamPlayer.new()
		music.stream = preload("res://assets/music/algemeen/Extraction.mp3")
		add_child(music)
		music.play()

		print("🚁 Extraction initiated by", extraction_triggered_by.name)
	else:
		print("🛑 Extraction canceled. Player chose to continue normally.")

func _handle_extraction_end():
	var escaped_players = []
	var left_behind_players = []

	for player in players:
		if player.current_place == extraction_tile_index and not player.is_dead:
			escaped_players.append(player.name)
		elif not player.is_dead:
			left_behind_players.append(player.name)

	var message := "✅ Extraction Success!\n\nEscaped:\n" + str(escaped_players) + "\n\nLeft Behind:\n" + str(left_behind_players)
	print(message)

	# Optional: show message on screen while the music and voice play
	var label = _create_label(message, 24, Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(label)

	next_turn_button.disabled = true  # Freeze game input

	# 🎵 Stop any currently playing music
	for node in get_children():
		if node is AudioStreamPlayer and node.playing:
			node.stop()

	# 🎵 Play extraction success music
	var music = AudioStreamPlayer.new()
	music.stream = preload("res://assets/music/algemeen/Extraction successfull.mp3")
	add_child(music)
	music.play()

	# 🕒 Wait 6 seconds, then play voice line
	await get_tree().create_timer(6.0).timeout
	var voice = AudioStreamPlayer.new()
	voice.stream = preload("res://assets/voice_lines/Democracy Officer - Democracy prevails once more.mp3")
	add_child(voice)
	voice.play()

	# 🕒 Wait 8 more seconds (14 total), then change scene
	await get_tree().create_timer(8.0).timeout
	get_tree().change_scene_to_file("res://scenes/endScene/EndScene.tscn")  # ← update if you use a different path

func _handle_game_over_all_dead():
	print("☠️ All Helldivers are dead. Mission failed.")

	# 🔇 Stop all current music
	for node in get_children():
		if node is AudioStreamPlayer and node.playing:
			node.stop()

	# 🎵 Play Game Over music
	var music = AudioStreamPlayer.new()
	music.stream = preload("res://assets/music/automatons/# Relaxed background music - Automaton.mp3")
	add_child(music)
	music.play()

	# 🗣️ After 2 seconds: play voice line
	await get_tree().create_timer(2).timeout
	var voice = AudioStreamPlayer.new()
	voice.stream = preload("res://assets/voice_lines/Democracy officer - Our heroes have fallen, but their bodies shall be replaced and their losses restored (1).mp3")
	add_child(voice)
	voice.play()

	# ⏭️ After 8 more seconds: go to GameOver scene
	await get_tree().create_timer(8).timeout
	get_tree().change_scene_to_file("res://scenes/gameOver/Gameover.tscn")
