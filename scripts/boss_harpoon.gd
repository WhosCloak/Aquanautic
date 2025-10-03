extends RigidBody2D

@onready var anim_sprite: AnimatedSprite2D = $Sprite2D

func _ready():
	anim_sprite.play()
	await get_tree().create_timer(2.0).timeout
	queue_free()
   
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		queue_free()
