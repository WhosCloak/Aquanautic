extends CharacterBody2D

var speed = 200
var player = Node2D

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("get_score"):
			var current_score = body.get_score()
			if current_score > Global.high_score:
				Global.high_score = current_score
		body.call_deferred("queue_free")
		call_deferred("_gameover")
		
func _gameover() -> void:
	get_tree().change_scene_to_file("res://scenes/gameover.tscn")

func die():
	if player and player.has_method("add_score"):
		player.add_score()
	call_deferred("queue_free")
