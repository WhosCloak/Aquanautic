extends Node2D

var enemy_scene_1 = preload("res://scenes/Enemies/enemy1.tscn")
var enemy_scene_2 = preload("res://scenes/Enemies/enemy2.tscn")
var enemy_scene_3 = preload("res://scenes/Enemies/enemy3.tscn")
var enemy_scene_4 = preload("res://scenes/Enemies/enemy4.tscn")
var enemy_scene_5 = preload("res://scenes/Enemies/enemy5.tscn")

var spawn_distance = 500 
var spawn_interval = 1
var timer := 0.0
var player: Node2D 

func _ready():
	add_to_group("enemy_spawner")
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
	var enemy_scene = enemy_scene_1
	
	if player.score >= 10:
		enemy_scene = enemy_scene_2
	if player.score >= 20:
		enemy_scene = enemy_scene_3
	if player.score >= 25:
		enemy_scene = enemy_scene_4
	if player.score >= 30:
		enemy_scene = enemy_scene_5

	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	get_parent().add_child(enemy) 
