extends Control

const MENU_SCENE := "res://scenes/main.tscn"

@onready var label_high : Label = $Label2
@onready var theme_player: AudioStreamPlayer2D = $Gameovertheme
@onready var click_player: AudioStreamPlayer2D = $buttonpress

func _ready() -> void:
	if label_high:
		label_high.text = "High Score: %d" % Global.high_score
	if theme_player:
		theme_player.play()
		
func _on_button_pressed() -> void:
	click_player.play()
	await click_player.finished
	get_tree().change_scene_to_file(MENU_SCENE)
