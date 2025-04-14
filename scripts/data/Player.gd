extends Resource
class_name Player

@export var name: String = ""
@export var health: int = 100
@export var weapon: String = "Liberator"
@export var stratagems: Array[Stratagem] = []
@export var current_place: int = 1
@export var reinforce_used := false
@export var stims: int = 3
@export var is_dead: bool = false
@export var stratagem_cooldowns := {}
