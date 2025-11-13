extends Node

@onready var vhs_filter := get_tree().get_first_node_in_group("vhs_filter")

var is_enabled := true

func _ready():
	update_filter()


func toggle_filter():
	is_enabled = !is_enabled
	update_filter()

func update_filter():
	if vhs_filter:
		vhs_filter.visible = is_enabled


func _on_check_button_toggled(_toggled_on: bool) -> void:
	if vhs_filter:
		vhs_filter.visible = !vhs_filter.visible
