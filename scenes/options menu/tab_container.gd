extends TabContainer

func _ready() -> void:
	# Make sure the first tab's control can get focus
	if get_tab_count() > 0:
		var first_tab_control := get_tab_control(0)
		if first_tab_control is Control:
			first_tab_control.focus_mode = Control.FOCUS_ALL
			first_tab_control.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		current_tab = max(current_tab - 1, 0)
	elif event.is_action_pressed("ui_right"):
		current_tab = min(current_tab + 1, get_tab_count() - 1)
