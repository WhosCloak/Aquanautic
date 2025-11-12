extends Node2D

# --- Preload all enemy scenes ---
var enemy_scenes = [
	preload("res://scenes/Enemies/enemy1.tscn"),
	preload("res://scenes/Enemies/enemy2.tscn"),
	preload("res://scenes/Enemies/enemy3.tscn"),
	preload("res://scenes/Enemies/enemy4.tscn"),
	preload("res://scenes/Enemies/enemy5.tscn"),
	preload("res://scenes/Enemies/enemy6.tscn"),
	preload("res://scenes/Enemies/enemy7.tscn"),
	preload("res://scenes/Enemies/enemy8.tscn"),
	preload("res://scenes/Enemies/enemy9.tscn"),
	preload("res://scenes/Enemies/enemy10.tscn")
]

# --- Level-based enemy groups ---
var enemies_by_level = {
	1: [0, 1],          # Level 1 (0–20)
	2: [2, 3, 4],       # Level 2 (21–40)
	3: [5, 6, 7],       # Level 3 (41–60)
	4: [8, 9]           # Level 4 (61–80)
}

# --- Settings ---
var spawn_distance := 500.0
var spawn_interval := 1.0
var timer := 0.0
var player: Node2D

# --- Called when node is ready ---
func _ready():
	add_to_group("enemy_spawner")
	player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	timer += delta
	if timer >= spawn_interval:
		timer = 0.0
		spawn_enemy()

# --- Determine level based on score ---
func get_player_level(score: int) -> int:
	if score < 20:
		return 1
	elif score < 40:
		return 2
	elif score < 60:
		return 3
	else:
		return 4

# --- Spawn an enemy based on player's score ---
func spawn_enemy() -> void:
	if not player:
		return

	var direction = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()
	var spawn_pos = player.global_position + direction * spawn_distance

	var level = get_player_level(player.score)
	var available_indices = enemies_by_level[level]
	var enemy_index = available_indices[randi() % available_indices.size()]

	var enemy_scene = enemy_scenes[enemy_index]
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos

	get_parent().add_child(enemy)
