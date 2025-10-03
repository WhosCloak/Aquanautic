extends RigidBody2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var proximity_area: Area2D = $Area2D

var exploded := false

func _ready():
	anim_sprite.play("normal")
	proximity_area.body_entered.connect(_on_proximity_body_entered)
	self.body_entered.connect(_on_ground_body_entered)

func _on_proximity_body_entered(body):
	if exploded:
		return
	if body.is_in_group("player"):
		explode(body)
		
func _on_ground_body_entered(body):
	if exploded:
		return
		
	#if body.is_in_group("ground") or body is Tilemap:
	#	explode()
	
func explode(body = null):
	exploded = true 
	anim_sprite.play("explode")
	if body and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1)
		
	await anim_sprite.animation_finished
	queue_free()
