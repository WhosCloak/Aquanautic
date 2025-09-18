extends Control

var mainmenutheme = preload("res://audios/Into the Abyss.mp3")
var buttonpress = preload("res://audios/menu select.wav")

func _ready() -> void:
	$Mainmenutheme.play()
	
func _on_button_pressed() -> void: #START
	
	Fade.transition()
	$buttonpress.play()
	await Fade.on_transition_finished
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_button_2_pressed() -> void: #OPTIONS
	$buttonpress.play() # add with settings
	get_tree().change_scene_to_file("res://scenes/options.tscn")

func _on_button_3_pressed() -> void: #QUIT
	$buttonpress.play()
	get_tree().quit()
