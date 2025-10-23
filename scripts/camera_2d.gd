extends Camera2D

@export var shakefade: float = 5
var random = RandomNumberGenerator.new()
var shake_strength: float = 0
var player = Node2D

func _process(delta) -> void:
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shakefade * delta)
		offset = randomoffset()

func apply_shake():
	shake_strength = Global.randomstrength
	
func randomoffset() -> Vector2:
	return Vector2(random.randf_range(-shake_strength, shake_strength),random.randf_range(-shake_strength, shake_strength))
