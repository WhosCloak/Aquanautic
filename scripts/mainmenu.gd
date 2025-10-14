extends Control

@onready var mainbuttons: VBoxContainer = $Mainbuttons
@onready var options: Panel = $Options

var mainmenutheme = preload("res://audios/Into the Abyss(Main Menu).mp3")
var buttonpress = preload("res://audios/menu_select.wav")

func _ready() -> void:
	$Mainmenutheme.play()
	mainbuttons.visible = true
	options.visible = false
	
	
func _on_button_pressed() -> void: #START
	Fade.transition()
	$buttonpress.play()
	await Fade.on_transition_finished
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_button_2_pressed() -> void: #OPTIONS
	mainbuttons.visible = false
	options.visible = true
	

func _on_button_3_pressed() -> void: #QUIT
	$buttonpress.play()
	get_tree().quit()


func _on_back_options_pressed() -> void:
	_ready()
