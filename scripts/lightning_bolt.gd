extends RigidBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
#@onready var zap_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready():
	anim.play("strike")
#	if zap_sound:
#		zap_sound.play()
	await get_tree().create_timer(1.5).timeout
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(2)  # stronger than harpoon
		queue_free()
