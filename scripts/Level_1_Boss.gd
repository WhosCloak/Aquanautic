extends Node2D

const WHALE_BOSS = preload("res://scenes/BossLevels/WhaleBoss.tscn")
@onready var boss_theme: AudioStreamPlayer2D = $BossTheme

func _ready() -> void:
	if boss_theme:
		boss_theme.play()
		
	var boss = get_node_or_null("BossSpawn/WhaleBoss")
	if not boss:
		push_error("WhaleBoss not found!")
		
	# Set boss arena camera limits
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var cam = player.get_node_or_null("Camera2D")
		if cam:
			cam.limit_left = -576
			cam.limit_right = 576
			cam.limit_top = -324
			cam.limit_bottom = 324
			cam.limit_enabled = true
			cam.zoom = Vector2(2.0, 2.0)
			
func _exit_tree() -> void:
	if boss_theme and boss_theme.playing:
		boss_theme.stop()
		
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var cam = player.get_node_or_null("Camera2D")
		if cam:
			cam.limit_enabled = false
