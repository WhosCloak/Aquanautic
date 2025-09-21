extends CharacterBody2D

var speed = 100
var player = Node2D
var deathsound = preload("res://audios/enemydeath.wav")
@onready var art:AnimatedSprite2D = $Sprite2D
const FLIP_THRESHOLD := 1.0

func _update_art_facing() -> void:
	if art == null:
		return 
	if abs(velocity.x) > FLIP_THRESHOLD:
		art.flip_h = velocity.x > 0.0
	art.rotation = 0.0

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		_update_art_facing()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		die()


func die():
	if player and player.has_method("add_score"):
		player.add_score()
	call_deferred("queue_free")
	$Death.play()
