extends Control

func _ready() -> void:
	hide()
	$AnimationPlayer.play("RESET")
	
func _process(_delta: float) -> void:
	openpause()
	
	
func resume():
	get_tree().paused = false
	hide()
	$AnimationPlayer.play_backwards("pause_blur")
	
func paused():
	get_tree().paused = true
	show()
	$AnimationPlayer.play("pause_blur")
	
func openpause():
	if Input.is_action_just_pressed("escape") and !get_tree().paused:
		paused()
	elif Input.is_action_just_pressed("escape") and get_tree().paused:
		resume()


func _on_button_pressed() -> void:
	resume()


func _on_button_2_pressed() -> void:
	pass # Replace with function body. #ADD OPNTIONS MENU


func _on_button_3_pressed() -> void:
		get_tree().quit()
