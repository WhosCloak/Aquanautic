extends Area2D
signal entered

@onready var anim: AnimatedSprite2D = $Icon 
func _ready() -> void:
	if anim:
		anim.play("loop")
	body_entered.connect(func(b: Node2D):
		if b.is_in_group("player"):
			entered.emit()
)
