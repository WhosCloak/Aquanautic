extends Node2D

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox: Area2D = $Hitbox

signal bite_finished

func _ready():
	if hitbox:
		hitbox.monitoring = true
		if not hitbox.is_connected("body_entered", Callable(self, "_on_hitbox_body_entered")):
			hitbox.body_entered.connect(_on_hitbox_body_entered)

	if sprite:
		sprite.play("Bite")
		await sprite.animation_finished
		bite_finished.emit()
		queue_free()

func _on_hitbox_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1)
