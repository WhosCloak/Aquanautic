extends Control

@onready var options_button: Button = $VBoxContainer/Options
@onready var options_menu: Control = $Options_Menu

func _ready() -> void:
	hide()
	$AnimationPlayer.play("RESET")
	options_menu.hide() # start hidden
	options_button.pressed.connect(_on_options_pressed)
	
	# connect the exit signal from options menu
	if options_menu.has_signal("exit_options_menu"):
		options_menu.exit_options_menu.connect(_on_exit_options_menu)

func _process(_delta: float) -> void:
	openpause()

# Resume
func resume():
	get_tree().paused = false
	hide()
	$AnimationPlayer.play_backwards("pause_blur")

# Pause
func paused():
	get_tree().paused = true
	show()
	$AnimationPlayer.play("pause_blur")

# Open Pause with ESC
func openpause():
	if Input.is_action_just_pressed("escape") and not get_tree().paused:
		paused()
	elif Input.is_action_just_pressed("escape") and get_tree().paused:
		resume()

# Resume Button
func _on_button_pressed() -> void:
	resume()

# Reset Button
func _on_button_2_pressed() -> void:
	resume()
	get_tree().change_scene_to_file("res://scenes/mainmenu/main_menu.tscn")

# Quit Button
func _on_button_3_pressed() -> void:
	get_tree().quit()

# Options Button
func _on_options_pressed() -> void:
	options_menu.show()
	$VBoxContainer.hide()

# Exit from options menu back to pause menu
func _on_exit_options_menu() -> void:
	options_menu.hide()
	$VBoxContainer.show()
