extends Node2D

# Path to the boss level scene for Level 1
var boss_1_scene := "res://scenes/Level_1_Boss.tscn" #change for future levels
# Preloaded portal scene that the player enters to start the boss fight
var gate_scene := preload("res://scenes/WhirlpoolGate.tscn")

#True when the game is currently in a boss encounter
var in_boss := false
#True once the portal has been spawned for the current level
var gate_spawned := false
# Reference to the spawned portal instance, used so we can free itr later
var gate_instance: Area2D

# Node that holds the currenrtly loaded level as a child
@onready var level_root = $LevelRoot
# Refrence to the current level instance under level_root
var current_level: Node = null
# Simple progresssion flag to know which level we have reahced
var level_reached := 1

func _start_all_spawners_in_tree() -> void:
	var list := get_tree().get_nodes_in_group("enemy_spawner")
	for s in list:
		s.set_process(true)

func _ready() -> void:
	# Start the game on Level 1
	load_level("res://scenes/levels/Level_1.tscn")

func _process(_delta: float) -> void:
	# While not in a boss fight, keep checking if we should advance or spawn the gate
	if not in_boss:
		check_next_level()

func check_next_level() -> void:
	# Level 1, when score hits 20 and no gate yet, spawn the boss portal
	if level_reached == 1 and Global.player_score >= 20 and not gate_spawned:
		_spawn_boss_gate_near_player()
		gate_spawned = true
	#After boss 1 is done, these handle later level transitions by score
	elif level_reached == 2 and Global.player_score >= 40:
		Fade.transition()
		await Fade.on_transition_finished
		go_to_level_3()
		level_reached = 3
	elif level_reached == 3 and Global.player_score >= 60:
		Fade.transition()
		await Fade.on_transition_finished
		go_to_level_4()
		level_reached = 4
		
func _spawn_boss_gate_near_player() -> void:
	# Find the player by group and place the portal a bit to the right 
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	gate_instance = gate_scene.instantiate()
	gate_instance.global_position = player.global_position + Vector2(120 , 0)
	# Listen for the portals entered signal to begin the boss flow
	gate_instance.entered.connect(_on_gate_entered)
	# Parent the poretal inside the current level if possible 
	if current_level:
		current_level.add_child(gate_instance)
	else:
		add_child(gate_instance)
		
func _on_gate_entered() -> void: 
	# Mark that we are entering a boss, stop spawning, and clear leftovers
	in_boss = true
	_stop_all_spawners_in_tree()
	_purge_enemies()
	
	# Remove the portal once used 
	if is_instance_valid(gate_instance):
		gate_instance.queue_free()
		
	# Fade, then load the boss level
	Fade.transition()
	await Fade.on_transition_finished
	_go_to_boss_for_level(1)
	
func _go_to_boss_for_level(_idx: int) -> void:
	# Load the boss scene for the current level
	load_level(boss_1_scene)
	# Make sure spawners are stopped and any stragglers are cleared
	_stop_all_spawners_in_tree()
	_purge_enemies()
	
	# Move the player to the PlayerSpawn marker inside the boss scene
	var player := get_tree().get_first_node_in_group("player")
	var spawn := current_level.find_child("PlayerSpawn", true, false)
	if player and spawn:
		player.global_position = spawn.global_position
	# Hook the boss death signal so we can advance after the fight 
	var boss := current_level.find_child("WhaleBoss", true, false)
	if boss:
		# show the HUD on the player
		var pname := "Boss"
		if  "display_name" in boss:
			pname = boss.display_name
		if player and player.has_method("boss_ui_show"):
			player.boss_ui_show(boss, pname)
			print("[Main] calling boss_ui_show with:", pname)
		boss.died.connect(_on_boss_died)

func _on_boss_died() -> void:
	# hide HUD
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("boss_ui_hide"):
		player.boss_ui_hide()
	
	# After the boss is defeated, fade and advance to Level 2
	Fade.transition()
	await Fade.on_transition_finished
	level_reached = 2
	in_boss = false
	gate_spawned = false
	go_to_level_2()
	
func load_level(path: String) -> void:
	# Replace the current level under level_root with a new instance from path
	if current_level and current_level.is_inside_tree():
		current_level.queue_free()
	var level_scene = load(path)
	if not level_scene:
		return
	current_level = level_scene.instantiate()
	level_root.add_child(current_level)
	
func _stop_all_spawners_in_tree() -> void:
	# Disable all enemy psawners, requires spawners to be in group "enemy_spawner"
	var list := get_tree().get_nodes_in_group("enemy_spawner")
	for s in list:
		s.set_process(false)
		
func _purge_enemies() -> void:
	# Remove any live enemies, requires enemies to be in group "enemy"
	var list := get_tree().get_nodes_in_group("enemy")
	for e in list:
		if is_instance_valid(e):
			e.queue_free()
		print("[Main] Purged enemies:", list.size())

func go_to_level_2() -> void:
	load_level("res://scenes/levels/Level_2.tscn")
	_start_all_spawners_in_tree()

func go_to_level_3() -> void:
	load_level("res://scenes/levels/Level_3.tscn")
	_start_all_spawners_in_tree()
	
func go_to_level_4() -> void:
	load_level("res://scenes/levels/level_4.tscn")
	_start_all_spawners_in_tree()
