extends Node2D

const BOSS_1_SCENE := "res://scenes/Level_1_Boss.tscn" #cahnge for furter
const GATE_SCENE := preload("res://scenes/WhirlpoolGate.tscn")

var in_boss := false
var gate_spawned := false
var gate_instance: Area2D

@onready var level_root = $LevelRoot
var current_level: Node = null
var level_reached := 1

func _ready() -> void:
	load_level("res://scenes/levels/Level_1.tscn")

func _process(_delta: float) -> void:
	if not in_boss:
		check_next_level()

func check_next_level() -> void:
	if level_reached == 1 and Global.player_score >= 20 and not gate_spawned:
		_spawn_boss_gate_near_player()
		gate_spawned = true
	
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
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	gate_instance = GATE_SCENE.instantiate()
	gate_instance.global_position = player.global_position + Vector2(120 , 0)
	gate_instance.entered.connect(_on_gate_entered)
	if current_level:
		current_level.add_child(gate_instance)
	else:
		add_child(gate_instance)
		
func _on_gate_entered() -> void: 
	in_boss = true
	_stop_all_spawners_in_tree()
	if is_instance_valid(gate_instance):
		gate_instance.queue_free()
		
	Fade.transition()
	await Fade.on_transition_finished
	_go_to_boss_for_level(1)
	
func _go_to_boss_for_level(_idx: int) -> void:
	load_level(BOSS_1_SCENE)
	_stop_all_spawners_in_tree()
	var player := get_tree().get_first_node_in_group("player")
	var spawn := current_level.find_child("PlayerSpawn", true, false)
	if player and spawn:
		player.global_position = spawn.global_position
		
	var boss := current_level.find_child("WhaleBoss", true, false)
	if boss:
		boss.died.connect(_on_boss_died)

func _on_boss_died() -> void:
	Fade.transition()
	await Fade.on_transition_finished
	level_reached = 2
	in_boss = false
	gate_spawned = false
	go_to_level_2()
	
func load_level(path: String) -> void:
	if current_level and current_level.is_inside_tree():
		current_level.queue_free()
	var level_scene = load(path)
	if not level_scene:
		return
	current_level = level_scene.instantiate()
	level_root.add_child(current_level)
	
func _stop_all_spawners_in_tree() -> void:
	var list := get_tree().get_nodes_in_group("enemy_spawner")
	for s in list:
		s.set_process(false)
		#print("[Main] Stopped spawner:", s.name) debug

func go_to_level_2() -> void:
	load_level("res://scenes/levels/Level_2.tscn")

func go_to_level_3() -> void:
	load_level("res://scenes/levels/Level_3.tscn")
	
func go_to_level_4() -> void:
	load_level("res://scenes/levels/level_4.tscn")
