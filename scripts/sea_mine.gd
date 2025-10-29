extends RigidBody2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var proximity_area: Area2D = $Area2D
@onready var explode_sound: AudioStreamPlayer2D = $ExplodeSound

var exploded := false
@export var rise_speed := 100.0

func _ready():
	anim_sprite.play("idle")
	proximity_area.body_entered.connect(_on_proximity_body_entered)
	gravity_scale = 0.0  # stops gravity from pulling it down

func _physics_process(delta):
	if not exploded:
		position.y -= rise_speed * delta  # makes it rise upward

func _on_proximity_body_entered(body):
	if exploded:
		return
	if body.is_in_group("player"):
		explode(body)

func explode(body = null):
	if exploded:
		return
	exploded = true
	anim_sprite.play("explode")
	if explode_sound:
		explode_sound.play()
	if body and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1)
	await anim_sprite.animation_finished
	queue_free()
