extends RigidBody2D

func _ready():
	await get_tree().create_timer(2.0).timeout
	queue_free()
   
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("die"):
			body.die()
		queue_free()
