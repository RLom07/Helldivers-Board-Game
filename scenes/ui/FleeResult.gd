extends Control

signal continue_pressed(enemy: Enemy, tile_index: int)

@onready var title_label: Label = $background/TitleLabel
@onready var outcome_label: Label = $background/OutcomeLabel
@onready var enemy_attack_label: Label = $background/EnemyAttackLabel
@onready var continue_button: Button = $background/ContinueButton

var enemy: Enemy
var tile_index: int = -1
var player: Player
var success: bool = false
var safe_tile_index: int = -1

func _ready():
	randomize()
	continue_button.pressed.connect(_on_continue_pressed)

func setup(successful: bool, enemy_data: Enemy, tile: int, player_ref: Player, safe_tile: int = -1):
	success = successful
	enemy = enemy_data
	tile_index = tile
	player = player_ref
	safe_tile_index = safe_tile

	if success:
		outcome_label.text = "✅ You managed to escape to tile %d!" % (safe_tile_index + 1)
		enemy_attack_label.text = ""
	else:
		# Enemy attacks
		var attack = enemy.attacks[randi() % enemy.attacks.size()]
		player.health = max(0, player.health - attack.damage)

		outcome_label.text = "❌ You did not manage to escape!"
		enemy_attack_label.text = "The enemy used %s dealing %d damage!" % [attack.name, attack.damage]

func _on_continue_pressed():
	emit_signal("continue_pressed", enemy, tile_index)
	queue_free()
