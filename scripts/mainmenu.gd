extends Control

func _ready() -> void:
	$AudioStreamPlayer2D.play()
	
func _on_button_pressed() -> void: #START
	get_tree().change_scene_to_file("res://scenes/Base_Level/Level1.tscn")

func _on_button_2_pressed() -> void: #OPTIONS
	pass # Replace with settings

func _on_button_3_pressed() -> void: #QUIT
	get_tree().quit()
