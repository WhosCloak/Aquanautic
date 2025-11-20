extends CheckButton

@onready var status_label = $"../StatusLabel"

func _ready():
	button_pressed = Global.testing_mode
	update_status_label()

func _toggled(new_value):
	Global.testing_mode = new_value
	update_status_label()

func update_status_label():
	if Global.testing_mode:
		status_label.text = "Testing mode on"
	else:
		status_label.text = "Testing mode off"
