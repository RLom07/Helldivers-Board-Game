# enemy.gd
extends Resource
class_name Enemy
@export var name: String
@export var health: int
@export var attacks: Array[Dictionary] = []  # Each attack has { "name": String, "damage": int, "description": String }
@export var weakness: String
@export var resistance: String
