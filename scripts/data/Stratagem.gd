extends Resource
class_name Stratagem

@export var name: String
@export var description: String
@export var cooldown: int = 1  # in turns
@export var damage: int = 1
@export var icon: Texture2D
@export var type: String  # e.g. "Explosion", "Napalm"
@export var range: int = 1  # how many spaces on the board it affects

# ✅ Targeting effect values (0 = not used, > 0 = active with radius/size)
@export var blast_radius: int = 0         # affects surrounding area
@export var area_impact: int = 0          # affects a large rectangular area
@export var blast_forward: int = 0        # affects spaces in a line ahead

# ✅ Convenience getter to determine targeting mode
func get_targeting_mode() -> String:
	if blast_radius > 0:
		return "BlastRadius"
	elif area_impact > 0:
		return "AreaImpact"
	elif blast_forward > 0:
		return "BlastForward"
	else:
		return "None"
