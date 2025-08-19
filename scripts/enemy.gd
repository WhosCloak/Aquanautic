extends CharacterBody2D


var speed = 300
var player = null

func _ready():
	player = get_tree().get_first_node_in_group("player")
	
func _physics_process(delta):
	if player:
		var direction = (player.global_position- global_position).normalized()
		velocity = direction * speed
		move_and_slide()
