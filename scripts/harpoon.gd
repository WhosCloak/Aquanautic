extends RigidBody2D

func _ready():
	add_to_group("projectile")
	await get_tree().create_timer(2.0).timeout
	queue_free()
   
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		if body.is_in_group("shielded_enemy") and body.has_method("take_damage"):
			body.take_damage()
		elif body.has_method("take_damage"):
			body.take_damage(1)
		queue_free()
	elif body.is_in_group("boss"):
		if body.has_method("apply_damage"):
			body.apply_damage(1)
			queue_free()
