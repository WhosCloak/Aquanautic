extends Node2D

@export var sea_mine_scene: PackedScene = preload("res://scenes/BossLevels/sea_mine.tscn")
@export var sea_mine_root_path: NodePath
@onready var sea_mine_root: Node = get_node_or_null(sea_mine_root_path)
@onready var boss_theme: AudioStreamPlayer2D = $BossTheme

func _ready() -> void:
	if boss_theme:
		boss_theme.play()
	await get_tree().create_timer(5.0).timeout
	_spawn_seamines()

	var player = get_tree().get_first_node_in_group("player")
	if player:
		var cam = player.get_node_or_null("Camera2D")
		if cam:
			cam.limit_left = -560
			cam.limit_right = 560
			cam.limit_top = -320
			cam.limit_bottom = 320
			cam.limit_enabled = true
			cam.zoom = Vector2(2.0, 2.0)

func _spawn_seamines():
	if not sea_mine_root or not sea_mine_scene:
		return
	for marker in sea_mine_root.get_children():
		if marker is Marker2D:
			var mine = sea_mine_scene.instantiate()
			mine.global_position = marker.global_position
			get_tree().current_scene.add_child(mine)


func _exit_tree() -> void:
	if boss_theme and boss_theme.playing:
		boss_theme.stop()

	var player = get_tree().get_first_node_in_group("player")
	if player:
		var cam = player.get_node_or_null("Camera2D")
		if cam:
			cam.limit_enabled = false
