# Player.gd
extends Resource
class_name Player

@export var name: String
@export var health: int = 100
@export var weapon: String = "Liberator"
@export var strategems: Array[Resource] = []
@export var current_place: int = 0
