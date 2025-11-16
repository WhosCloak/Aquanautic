class_name OptionsMenu
extends Control

@onready var exit_button: Button = $Exit_Button
@onready var credits_button: Button = $Credits_button

signal exit_options_menu

func _ready() -> void:
	exit_button.button_down.connect(on_exit_pressed)
	set_process(false)

func show_menu() -> void:
	# Call this from pause/main menu when opening options
	show()
	set_process(true)
	exit_button.grab_focus()

func on_exit_pressed() -> void:
	exit_options_menu.emit()
	set_process(false)
	hide()

func _on_credits_button_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/CreditsPlayer.tscn")
