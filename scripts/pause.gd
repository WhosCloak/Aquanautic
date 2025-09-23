extends Control

#Start Hidden
func _ready() -> void:
	hide()
	$AnimationPlayer.play("RESET")
	
	
func _process(_delta: float) -> void:
	openpause()
	
#Resume
func resume():
	get_tree().paused = false
	hide()
	$AnimationPlayer.play_backwards("pause_blur")

#Pause
func paused():
	get_tree().paused = true
	show()
	$AnimationPlayer.play("pause_blur")

#Open Pause with ESC
func openpause():
	if Input.is_action_just_pressed("escape") and !get_tree().paused:
		paused()
	elif Input.is_action_just_pressed("escape") and get_tree().paused:
		resume()

#Button to resume
func _on_button_pressed() -> void:
	resume()

#Button to reset
func _on_button_2_pressed() -> void:
	resume()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	

#Button to Quit
func _on_button_3_pressed() -> void:
		get_tree().quit()
