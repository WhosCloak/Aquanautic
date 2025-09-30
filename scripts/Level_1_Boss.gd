extends Node2D

@onready var boss_theme: AudioStreamPlayer2D = $BossTheme

func _ready() -> void:
	if boss_theme:
		boss_theme.play()

func _exit_tree() -> void:
	# optional, tidy stop when leaving the scene
	if boss_theme and boss_theme.playing:
		boss_theme.stop()
