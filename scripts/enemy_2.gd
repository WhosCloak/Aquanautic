extends CharacterBody2D

#Variables
var speed = 150
var player = Node2D
var deathsound = preload("res://audios/enemydeath.wav")
@onready var art:AnimatedSprite2D = $Sprite2D
@onready var shield_sprite: AnimatedSprite2D = $ShieldSprite
var flip_threshold := 1.0
var shield_active := true

#Model Flip
func _update_art_facing() -> void:
	if art == null:
		return 
	if abs(velocity.x) > flip_threshold:
		art.flip_h = velocity.x > 0.0
	art.rotation = 0.0

#Find Player
func _ready():
	player = get_tree().get_first_node_in_group("player")
	shield_sprite.play("shield_activate")

func _physics_process(_delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		_update_art_facing()

#Player Damage
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		die()

func take_damage():
	if shield_active:
		shield_active = false
		shield_sprite.visible = false
	else:
		die()

#Enemy Death
func die():
	if player and player.has_method("add_score"):
		player.add_score()
	call_deferred("queue_free")
	$Death.play()
