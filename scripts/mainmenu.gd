extends Control

func _on_button_pressed() -> void: #START
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_button_2_pressed() -> void: #OPTIONS
	pass # Replace with function body.

func _on_button_3_pressed() -> void: #QUIT
	get_tree().quit()
