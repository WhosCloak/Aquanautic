extends Area2D
# Whirlpool portal Area2D. When the player overlaps, we emit "entered" so Main can transition

signal entered # Custom signal, emmitted once a player body enters this Area2D

@onready var anim: AnimatedSprite2D = $Icon  # Animated whirlpool icon under this node 

func _ready() -> void:
	# Start the whirlpool animation if the AnimatedSprite2D exists
	if anim:
		anim.play("loop")
	
	#Listen for any physics body entering this Area2D
	# If that body is the player, emit our "entered" signal
	body_entered.connect(func(b: Node2D):
		if b.is_in_group("player"):
			entered.emit()
)
