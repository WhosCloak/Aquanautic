extends Node2D

var powerup_multishot = preload("res://scenes/multishot.tscn")
var powerup_firerate = preload("res://scenes/firerate.tscn")

var spawn_distance := 400
var spawn_interval := 2
var timer := 0.0
var player: Node2D
var powerup_spawn_chance := 0.5 # 50% chance per interval

func _ready():
	add_to_group("powerup_spawner")
	player = get_tree().get_first_node_in_group("player")

func _process(delta):
	if not player:
		return
		
	timer += delta
	if timer >= spawn_interval:
		timer = 0
		if randf() < powerup_spawn_chance:
			spawn_powerup()

func spawn_powerup():
	var direction = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()
	var spawn_pos = player.global_position + direction * spawn_distance

	var powerup_scene = powerup_multishot if randi() % 2 == 0 else powerup_firerate

	var powerup = powerup_scene.instantiate()
	powerup.global_position = spawn_pos
	get_parent().add_child(powerup)
