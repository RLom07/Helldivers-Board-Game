extends Resource
class_name Stratagem

@export var name: String
@export var description: String
@export var cooldown: int = 1
var cooldown_counter: int = 0
@export var damage: int = 1
@export var icon: Texture2D
@export var type: String # e.g., "Bullet", "Explosion", "Napalm"
@export var range: int = 1

@export var blast_radius: int = 0
@export var area_impact: int = 0
@export var blast_forward: int = 0

func get_targeting_mode() -> String:
	if blast_radius > 0:
		return "BlastRadius"
	elif area_impact > 0:
		return "AreaImpact"
	elif blast_forward > 0:
		return "BlastForward"
	else:
		return "None"

func process_attack(tile_indexes: Array, players: Array, enemy_tile_map: Dictionary) -> Dictionary:
	var defeated_tiles: Array[int] = []
	var hidden_hits := 0
	var revealed_hit_names: Array[String] = []

	for i in tile_indexes:
		if not enemy_tile_map.has(i):
			continue

		var enemy = enemy_tile_map[i]
		if enemy.isdefeated:
			continue

		var final_damage = damage
		if type == "Bullet" and enemy.weakness == "Bullet":
			final_damage *= 1.5

		enemy.health -= final_damage
		if enemy.health <= 0:
			enemy.isdefeated = true
			defeated_tiles.append(i)

		var is_revealed := false
		if "revealed" in enemy and enemy.revealed:
			is_revealed = true
		elif players.any(func(p): return "current_place" in p and p.current_place == i):
			is_revealed = true

		if is_revealed:
			revealed_hit_names.append(enemy.name)
		else:
			hidden_hits += 1

	return {
		"defeated_tiles": defeated_tiles,
		"hidden_hits": hidden_hits,
		"revealed_hit_names": revealed_hit_names
	}
