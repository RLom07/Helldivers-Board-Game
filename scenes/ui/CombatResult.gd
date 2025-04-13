extends Control

signal continue_pressed(enemy: Enemy, tile_index: int)

@onready var title_label: Label = $background/TitleLabel
@onready var damage_label: Label = $background/DamageLabel
@onready var outcome_label: Label = $background/OutcomeLabel
@onready var enemy_attack_label: Label = $background/EnemyAttackLabel
@onready var continue_button: Button = $background/ContinueButton

var enemy: Enemy
var damage: int = 0
var tile_index: int = -1
var player: Player  # ✅ Declare it here!

func _ready():
	randomize()
	continue_button.pressed.connect(_on_continue_pressed)

func setup(enemy_data: Enemy, damage_amount: int, tile: int, player_ref: Player):
	enemy = enemy_data
	damage = damage_amount
	tile_index = tile
	player = player_ref  # ✅ Now this is valid!

	damage_label.text = "You dealt %d damage to the enemy!" % damage

	if enemy.health <= 0:
		outcome_label.text = "The enemy has been defeated!"
	else:
		# Enemy counterattack
		var attack = enemy.attacks[randi() % enemy.attacks.size()]
		player.health = max(0, player.health - attack.damage)

		outcome_label.text = "The enemy is still standing and: \nIt used %s dealing %d damage!" % [attack.name, attack.damage]

func _on_continue_pressed():
	emit_signal("continue_pressed", enemy, tile_index)
	queue_free()
