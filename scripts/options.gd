extends Control

func _on_button_pressed() -> void:
	$buttonpress.play()
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
