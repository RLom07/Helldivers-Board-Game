extends Node

var players: Array[Player] = []

func add_player(player: Player) -> void:
	players.append(player)

func clear_players() -> void:
	players.clear()
