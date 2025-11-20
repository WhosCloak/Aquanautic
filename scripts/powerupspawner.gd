extends Node2D

# ---------------------------------------------------------
# Preloads
# ---------------------------------------------------------
var powerup_multishot = preload("res://scenes/multishot.tscn")
var powerup_firerate = preload("res://scenes/firerate.tscn")
var powerup_speedup = preload("res://scenes/speedup.tscn")
var powerup_maxhealth = preload("res://scenes/maxhealth.tscn")

var powerup_options = []

# ---------------------------------------------------------
# Settings
# ---------------------------------------------------------
var spawn_distance := 400
var spawn_interval := 2.0
var powerup_spawn_chance := 0.5

# ---------------------------------------------------------
# Internals
# ---------------------------------------------------------
var timer := 0.0
var player: Node2D
var last_purge_score := -1   # prevents repeated purging
# ---------------------------------------------------------

func _ready():
	add_to_group("powerup_spawner")
	player = get_tree().get_first_node_in_group("player")
	
	powerup_options = [
		powerup_multishot, 
		powerup_firerate, 
		powerup_speedup,
		powerup_maxhealth
	]

func _process(delta):
	if not player:
		return

	# Spawn loop
	timer += delta
	if timer >= spawn_interval:
		timer = 0.0
		if randf() < powerup_spawn_chance:
			spawn_powerup()

	# Purge check (separate!)
	purge_powerup()


# ---------------------------------------------------------
# Spawn
# ---------------------------------------------------------
func spawn_powerup():
	var direction = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()
	var spawn_pos = player.global_position + direction * spawn_distance

	var scene = powerup_options[randi() % powerup_options.size()]
	var p = scene.instantiate()
	p.global_position = spawn_pos

	get_parent().add_child(p)


# ---------------------------------------------------------
# Purge
# ---------------------------------------------------------
func purge_powerup():
	if Global.player_score <= 0:
		return
	
	if Global.player_score % 20 == 0 and Global.player_score != last_purge_score:
		last_purge_score = Global.player_score

		var list := get_tree().get_nodes_in_group("powerup")
		for e in list:
			e.queue_free()

		print("Purged all powerups at score:", Global.player_score)
