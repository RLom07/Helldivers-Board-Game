extends Node

var players: Array = []
@export var debug_mode := true  # Enable this for testing!

# ✅ Preload Reinforce globally so it’s accessible everywhere
var reinforce = preload("res://scripts/data/stratagems/Reinforce.tres")

func _ready():
	if debug_mode:
		print("🛠 Debug mode enabled — creating fake players.")
		_create_debug_players()

func _create_debug_players():
	clear_players()

	var strat_1 = preload("res://scripts/data/stratagems/Napalm.tres")
	var strat_2 = preload("res://scripts/data/stratagems/Orbital Barage.tres")
	var strat_3 = preload("res://scripts/data/stratagems/Smoke Eagle.tres")
	var strat_4 = preload("res://scripts/data/stratagems/Eagle Drone.tres")
	var strat_5 = preload("res://scripts/data/stratagems/Orbital Scan.tres")
	var strat_6 = preload("res://scripts/data/stratagems/Orbital Nuke.tres")
	var strat_7 = preload("res://scripts/data/stratagems/Eagle Bullet Rain.tres")
	var strat_8 = preload("res://scripts/data/stratagems/Napalm Eagle.tres")

	var player1 = Player.new()
	player1.name = "Debug Alice"
	player1.health = 100
	player1.weapon = "Liberator"
	player1.stratagems = [strat_1, strat_2, strat_3, strat_4]
	player1.current_place = 0
	add_player(player1)

	var player2 = Player.new()
	player2.name = "Debug Bob"
	player2.health = 100
	player2.weapon = "Liberator"
	player2.stratagems = [strat_2, strat_4, strat_1, strat_3]
	player2.current_place = 0
	add_player(player2)

	var player3 = Player.new()
	player3.name = "Debug Garreth"
	player3.health = 100
	player3.weapon = "Liberator"
	player3.stratagems = [strat_5, strat_6, strat_7, strat_8]
	player3.current_place = 0
	add_player(player3)

	var player4 = Player.new()
	player4.name = "Debug Melissa"
	player4.health = 100
	player4.weapon = "Liberator"
	player4.stratagems = [strat_1, strat_6, strat_7, strat_8]
	player4.current_place = 0
	add_player(player4)

func add_player(player: Player) -> void:
	# ✅ Add Reinforce only if not already in stratagems
	if not reinforce in player.stratagems:
		player.stratagems.append(reinforce)
	players.append(player)

func clear_players():
	players.clear()
