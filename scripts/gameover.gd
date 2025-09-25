extends Control

# Path to the main menu or first gameplay scene
var menu_scene := "res://scenes/main.tscn"

# Cached UI and audio nodes
@onready var label_high : Label = $Label2   # Shows the saved high score
@onready var theme_player: AudioStreamPlayer2D = $Gameovertheme # background music on the game over screen
@onready var click_player: AudioStreamPlayer2D = $buttonpress  # click sound for the restart button

#Dynamic Score card
func _ready() -> void:
	if label_high:
		label_high.text = "High Score: %d" % Global.high_score
	if theme_player:
		theme_player.play()

#Button to Restart game
func _on_button_pressed() -> void:
	click_player.play()
	await click_player.finished
	get_tree().change_scene_to_file(menu_scene)

#Press ESC to quit
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
