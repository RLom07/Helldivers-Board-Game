extends Control

signal dice_roll_result(damage: int)

@onready var label: Label = $background/Label
@onready var buttons := {
	1: $"background/1",
	2: $"background/2",
	3: $"background/3",
	4: $"background/4",
	5: $"background/5",
	6: $"background/6"
}

var enemy: Enemy
var enemy_name := ""
var base_damage := 0

func _ready():
	for i in buttons.keys():
		buttons[i].pressed.connect(func(): _on_dice_pressed(i))

func setup(enemy_data: Enemy):
	enemy = enemy_data
	enemy_name = enemy.name
	label.text = "Roll your dice to attack the " + enemy_name + " with your Liberator!"

func _on_dice_pressed(value: int):
	var damage = _calculate_damage(enemy_name, value)
	print("🎲 Rolled:", value, "-> 💥 Damage:", damage)
	emit_signal("dice_roll_result", damage)
	queue_free()

func _calculate_damage(name: String, roll: int) -> int:
	match name:
		"Commissar":
			return roll * 15  # 8–48
		"Marauder":
			return roll * 15  # 10–60
		"Devastator":
			return roll * 13  # 12–72
		"Hulk":
			return roll * 10  # 15–90
		"Annihilator Tank":
			return roll * 8  # 18–108
		_:
			return roll * 10  # default fallback
