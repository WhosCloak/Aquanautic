extends CharacterBody2D
# Enemy 1, simple chaser that homes toward the player

#Variables
var speed = 100  # move speed in pixels per seconds
var player = Node2D # will cache the player node at runtime
var deathsound = preload("res://audios/enemydeath.wav") #not used directly here, kept for parity with other enemies
@onready var art:AnimatedSprite2D = $Sprite2D #animated art node, name "Sprite2D" in the scene
var flip_threshold := 1.0  #minimum horizontal speed before flipping the sprite

#Model Flip
func _update_art_facing() -> void:
	if art == null:
		return 
	# Flip horizontally only when moving enough on X to avoid jitters at low speeds
	if abs(velocity.x) > flip_threshold:
		art.flip_h = velocity.x > 0.0
	# Keep sprite upright, do not inherit rotation from movement 
	art.rotation = 0.0

#Find Player by group "players"
func _ready():
	player = get_tree().get_first_node_in_group("player")

#Movement
func _physics_process(_delta):
	# Home toward the player and slide using CharacterBody2D
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		_update_art_facing()

#Player Damage/contact with player
func _on_area_2d_body_entered(body: Node2D) -> void:
	# If we touch the player, deal 1 damage and then die
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		die()

#Enemy Death
func die():
	# Award score to the player that exists in the scene
	if player and player.has_method("add_score"):
		player.add_score()
	# Remove this enemy safely after current frame
	call_deferred("queue_free")
	# Play death SFX via a child AudioStreamPlayer2D node named "Death"
	$Death.play()
