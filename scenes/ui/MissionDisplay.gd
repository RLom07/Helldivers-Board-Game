extends Control

@onready var close_button = $background/CloseButton

# Called when the node enters the scene tree for the first time.
func _ready():
	close_button.pressed.connect(func():
		queue_free()
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
