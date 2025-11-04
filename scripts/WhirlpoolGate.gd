extends Area2D
signal entered
@onready var anim: AnimatedSprite2D = $Icon

func _ready() -> void:
	add_to_group("active_goal")  # ← Make sure this is here
	
	if anim:
		anim.play("loop")
	
	body_entered.connect(func(b: Node2D):
		if b.is_in_group("player"):
			entered.emit()
	)

func _exit_tree() -> void:
	remove_from_group("active_goal")  # ← And this too
