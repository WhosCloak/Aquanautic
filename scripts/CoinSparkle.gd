extends AnimatedSprite2D

func _ready():
	# Automatically queue_free after the animation finishes
	await animation_finished
	queue_free()
