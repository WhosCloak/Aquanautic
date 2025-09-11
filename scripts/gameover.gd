extends Control


var gameover = preload("res://audios/game-over.mp3")
var buttonpress = preload("res://audios/menu select.wav")

func _ready() -> void:
	$Label2.text = "High Score: %d" % Global.high_score
	$Gameovertheme.play()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	$buttonpress.play()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
