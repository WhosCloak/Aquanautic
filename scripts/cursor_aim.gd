extends Sprite2D

@export var cursor_distance: float = 120.0   # Distance from player
var aim_direction: Vector2 = Vector2.RIGHT

func _process(_delta):
	# Reference your player correctly! Adjust path as needed
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var axis_x := Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left")
	var axis_y := Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
	var axis := Vector2(axis_x, axis_y)
	if axis.length() > 0.1:
		aim_direction = axis.normalized()

	var cursor_pos: Vector2 = player.global_position + aim_direction * cursor_distance

	# Clamp cursor position to viewport bounds
	var rect = get_viewport().get_visible_rect()
	cursor_pos = cursor_pos.clamp(rect.position, rect.position + rect.size)
	global_position = cursor_pos
