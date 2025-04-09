extends Resource
class_name Stratagem

@export var name: String
@export var description: String
@export var cooldown: int = 1  # in turns
@export var damage: int = 1
@export var icon: Texture2D
@export var type: String  # e.g. "Explosion", "Napalm"
@export var range: int = 1  # how many spaces on the board it affects
