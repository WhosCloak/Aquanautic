extends Node2D

#Enemy Scene Loader
var multishot = preload("res://scenes/multishot.tscn")


# Spawn tuning 
var spawn_distance = 500 # how far from the player to spawn
var spawn_interval = 0.8 # seconds between spawns
var timer := 0.0 # counts up to spawn_interval
var player: Node2D # cached player refrence

func _ready():
	player = get_tree().get_first_node_in_group("player") # find the player once

func _process(delta):
	# simple timer, spawn on interval
	timer += delta
	if timer >= spawn_interval:
		timer = 0
		spawn_powerup()

func spawn_powerup():
	# do nothing if we did not find a player yet
	if not player:
		return
	var direction = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()
	var spawn_pos = player.global_position + direction * spawn_distance

	var powerups = [multishot, multishot, multishot]
	var poweruprandomizer = powerups[randi() % powerups.size()]
	 
	var spawnpowerup = poweruprandomizer.instantiate()
	spawnpowerup.global_position = spawn_pos
	get_parent().add_child(spawnpowerup)
