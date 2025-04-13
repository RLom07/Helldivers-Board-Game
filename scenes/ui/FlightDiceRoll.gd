extends Control

signal flight_attempt_result(success: bool)

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

func _ready():
	for i in buttons.keys():
		buttons[i].pressed.connect(func(): _on_dice_pressed(i))

func setup(enemy_data: Enemy):
	enemy = enemy_data
	label.text = "Roll your dice to escape from the " + enemy.name + "!"

func _on_dice_pressed(value: int):
	var difficulty = _get_escape_difficulty(enemy.name)
	var success = value >= difficulty
	var result_text = "successful!" if success else "failed!"
	print("🎲 Rolled:", value, "-> 🏃‍♂️ Escape " + result_text)
	emit_signal("flight_attempt_result", success)
	queue_free()

func _get_escape_difficulty(enemy_name: String) -> int:
	match enemy_name:
		"Commissar": return 2
		"Marauder": return 3
		"Devastator": return 4
		"Hulk": return 5
		"Annihilator Tank": return 6
		_: return 3  # default difficulty
