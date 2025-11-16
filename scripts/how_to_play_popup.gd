extends CanvasLayer

@onready var close_button: Button = $Panel/Button

func _ready() -> void:
	visible = true
	get_tree().paused = true
	close_button.grab_focus()	# controller starts on this button

func _on_button_pressed() -> void:
	visible = false
	get_tree().paused = false
