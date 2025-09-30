extends Node2D

#Enemy Scene Loader
var enemy_scene_1 = preload("res://scenes/enemy1.tscn")
var enemy_scene_2 = preload("res://scenes/enemy2.tscn")
var enemy_scene_3 = preload("res://scenes/enemy3.tscn")
var enemy_scene_4 = preload("res://scenes/enemy4.tscn")
var enemy_scene_5 = preload("res://scenes/enemy5.tscn")

# Spawn tuning 
var spawn_distance = 500 # how far from the player to spawn
var spawn_interval = 0.8 # seconds between spawns
var timer := 0.0 # counts up to spawn_interval
var player: Node2D # cached player refrence

func _ready():
	add_to_group("enemy_spawner") # lets Main stop all spawners by group
	player = get_tree().get_first_node_in_group("player") # find the player once

func _process(delta):
	# simple timer, spawn on interval
	timer += delta
	if timer >= spawn_interval:
		timer = 0
		spawn_enemy()

func spawn_enemy():
	# do nothing if we did not find a player yet
	if not player:
		return

# choose a random direction and spawn at a ring around the player
	var direction = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()
	var spawn_pos = player.global_position + direction * spawn_distance

# Pick enemy based on player score, higher score, tougher enemy
	var enemy_scene = enemy_scene_1
	if player.score >= 10:
		enemy_scene = enemy_scene_2
	if player.score >= 20:
		enemy_scene = enemy_scene_3
	if player.score >= 25:
		enemy_scene = enemy_scene_4
	if player.score >= 30:
		enemy_scene = enemy_scene_5
# instance and parent under the level, not under the root scene 
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	get_parent().add_child(enemy) # parent beside the spawner so it is cleaned with the level 
