extends Node2D


@export var enemy_scene: PackedScene
@export var spawn_distance := 800  # how far from camera to spawn
@export var spawn_interval := 2.0

var timer := 0.0
var player = null

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _process(delta):
	timer += delta
	if timer >= spawn_interval:
		timer = 0
		spawn_enemy()

func spawn_enemy():
	if not player: return

	var direction = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()
	var spawn_position = player.global_position + direction * spawn_distance

	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_position
	get_tree().current_scene.add_child(enemy)
