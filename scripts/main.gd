extends Node2D
# ===============================
# 🔹 LEVEL MANAGEMENT VARIABLES
# ===============================
var boss_1_scene := "res://scenes/BossLevels/level_1_Boss.tscn"
var boss_2_scene := "res://scenes/BossLevels/level_2_Boss.tscn"
var boss_3_scene := "res://scenes/BossLevels/level_3_boss.tscn"
var boss_4_scene := "res://scenes/BossLevels/level_4_Boss.tscn"
var gate_scene := preload("res://scenes/WhirlpoolGate.tscn")

var in_boss := false
var gate_spawned := false
var gate_instance: Area2D

@onready var level_root = $LevelRoot
var current_level: Node = null
var level_reached := 1

# ===============================
# 🔹 READY & PROCESS
# ===============================
func _ready() -> void:
	load_level("res://scenes/levels/level_1.tscn")

func _process(_delta: float) -> void:
	if not in_boss:
		check_next_level()

# ===============================
# 🔹 LEVEL PROGRESSION LOGIC
# ===============================
func check_next_level() -> void:
	if level_reached == 1 and Global.player_score >= 2 and not gate_spawned:
		_spawn_boss_gate_near_player()
		gate_spawned = true

	elif level_reached == 2 and Global.player_score >= 4 and not gate_spawned:
		_spawn_boss_gate_near_player()
		gate_spawned = true

	elif level_reached == 3 and Global.player_score >= 6 and not gate_spawned:
		_spawn_boss_gate_near_player()
		gate_spawned = true

	elif level_reached == 4 and Global.player_score >= 8 and not gate_spawned:
		_spawn_boss_gate_near_player()
		gate_spawned = true

# ===============================
# 🔹 BOSS GATE HANDLING
# ===============================
func _spawn_boss_gate_near_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	gate_instance = gate_scene.instantiate()
	gate_instance.global_position = player.global_position + Vector2(120, 0)
	gate_instance.entered.connect(_on_gate_entered)

	if current_level:
		current_level.add_child(gate_instance)
	else:
		add_child(gate_instance)


func _on_gate_entered() -> void:
	in_boss = true
	_stop_all_spawners_in_tree()
	_purge_enemies()
	call_deferred("_stop_all_spawners_in_tree")
	call_deferred("_purge_enemies")
	if is_instance_valid(gate_instance):
		gate_instance.queue_free()

	Fade.transition()
	await Fade.on_transition_finished

	if level_reached == 1:
		_go_to_boss_for_level(1)
	elif level_reached == 2:
		_go_to_boss_for_level(2)
	elif level_reached == 3:
		_go_to_boss_for_level(3)
	elif level_reached == 4:
		_go_to_boss_for_level(4)

# ===============================
# 🔹 BOSS LEVEL TRANSITION
# ===============================
func _go_to_boss_for_level(idx: int) -> void:
	var boss_scene_path := ""
	match idx:
		1:
			boss_scene_path = boss_1_scene
		2:
			boss_scene_path = boss_2_scene
		3:
			boss_scene_path = boss_3_scene
		4:
			boss_scene_path = boss_4_scene

	load_level(boss_scene_path)
	_stop_all_spawners_in_tree()
	_purge_enemies()

	call_deferred("_stop_all_spawners_in_tree")
	call_deferred("_purge_enemies")

	var player := get_tree().get_first_node_in_group("player")
	var spawn := current_level.find_child("PlayerSpawn", true, false)
	if player and spawn:
		player.global_position = spawn.global_position

	var boss := current_level.find_child("SharkBoss", true, false)
	if not boss:
		boss = current_level.find_child("WhaleBoss", true, false)
	if not boss:
		boss = current_level.find_child("CrabBoss", true, false)
	if not boss:
		boss = current_level.find_child("Leviathan", true, false)

	if boss:
		var pname := "Boss"
		if "display_name" in boss:
			pname = boss.display_name

		if player and player.has_method("boss_ui_show"):
			player.boss_ui_show(boss, pname)
		boss.died.connect(_on_boss_died)

# ===============================
# 🔹 BOSS DEFEAT HANDLING
# ===============================
func _on_boss_died() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("boss_ui_hide"):
		player.boss_ui_hide()

	Fade.transition()
	await Fade.on_transition_finished

	if is_instance_valid(player):
		var cam = player.get_node_or_null("Camera2D")
		if cam:
			cam.zoom = Vector2(3.3, 3.3)
			cam.limit_enabled = false

	if level_reached == 1:
		level_reached = 2
		in_boss = false
		gate_spawned = false
		go_to_level_2()
	elif level_reached == 2:
		level_reached = 3
		in_boss = false
		gate_spawned = false
		go_to_level_3()
	elif level_reached == 3:
		level_reached = 4
		in_boss = false
		gate_spawned = false
		go_to_level_4()
	elif level_reached == 4:
		_show_credits_scene()

func _show_credits_scene() -> void:
	Fade.transition()
	await Fade.on_transition_finished

	var credits_scene = load("res://scenes/CreditsPlayer.tscn")
	if credits_scene:
		var instance = credits_scene.instantiate()
		get_tree().root.add_child(instance)
		queue_free()  

# ===============================
# 🔹 LEVEL LOADING
# ===============================
func load_level(path: String) -> void:
	if current_level and current_level.is_inside_tree():
		current_level.queue_free()

	var level_scene = load(path)
	if not level_scene:
		return

	current_level = level_scene.instantiate()
	level_root.add_child(current_level)

# ===============================
# 🔹 SPAWNER & ENEMY MANAGEMENT
# ===============================
func _start_all_spawners_in_tree() -> void:
	var list := get_tree().get_nodes_in_group("enemy_spawner")
	for s in list:
		s.set_process(true)


func _stop_all_spawners_in_tree() -> void:
	if get_tree() == null:
		return
	var list := get_tree().get_nodes_in_group("enemy_spawner")
	for s in list:
		if is_instance_valid(s):
			s.set_process(false)


func _purge_enemies() -> void:
	if get_tree() == null:
		return
	var list := get_tree().get_nodes_in_group("enemy")
	for e in list:
		if is_instance_valid(e):
			e.queue_free()

# ===============================
# 🔹 PLAYER DEATH / RESTART
# ===============================
func _on_player_death_or_restart():
	if is_instance_valid(gate_instance):
		gate_instance.queue_free()
		gate_instance = null
		gate_spawned = false

# ===============================
# 🔹 LEVEL TRANSITION HELPERS
# ===============================
func _reset_camera_for_regular_level():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var cam = player.get_node_or_null("Camera2D")
		if cam:
			cam.zoom = Vector2(3.3, 3.3)
			cam.limit_enabled = false

func go_to_level_2() -> void:
	load_level("res://scenes/levels/level_2.tscn")
	_start_all_spawners_in_tree()
	call_deferred("_reset_camera_for_regular_level")

func go_to_level_3() -> void:
	load_level("res://scenes/levels/level_3.tscn")
	_start_all_spawners_in_tree()
	call_deferred("_reset_camera_for_regular_level")

func go_to_level_4() -> void:
	load_level("res://scenes/levels/level_4.tscn")
	_start_all_spawners_in_tree()

func go_to_main_menu() -> void:
	load_level("res://scenes/mainmenu/main_menu.tscn")
	_reset_camera_for_regular_level()
