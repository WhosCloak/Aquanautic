extends Node2D

var enemy_scene_basic = preload("res://scenes/enemy1.tscn")
var enemy_scene_fast = preload("res://scenes/enemy2.tscn")
var enemy_scene_tank = preload("res://scenes/enemy3.tscn")

var spawn_distance = 500
var spawn_interval = 2.0
var timer := 0.0
var player: Node2D

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _process(delta):
	timer += delta
	if timer >= spawn_interval:
		timer = 0
		spawn_enemy()

func spawn_enemy():
	if not player:
		return

	var direction = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()
	var spawn_pos = player.global_position + direction * spawn_distance

	var enemy_scene = enemy_scene_basic
	if player.score >= 5 and player.score < 10:
		enemy_scene = enemy_scene_fast
	elif player.score >= 10:
		enemy_scene = enemy_scene_tank

	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	get_tree().current_scene.add_child(enemy)
