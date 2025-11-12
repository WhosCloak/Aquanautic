extends Node
# ==============================================
# CONTROLLER HANDLER
# Manages controller input for aiming
# ==============================================

signal aim_position_updated(position: Vector2)
signal aim_mode_changed(using_controller: bool)

var controller_aim_position: Vector2 = Vector2.ZERO
var use_controller_aim: bool = false
var controller_deadzone: float = 0.2  # Adjust to prevent stick drift

var _player_ref: Node2D = null
var _last_mouse_position: Vector2 = Vector2.ZERO

func _ready():
	_player_ref = get_parent()
	_last_mouse_position = get_viewport().get_mouse_position()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # Start with visible cursor

func _process(_delta: float) -> void:
	if _player_ref == null:
		return
	
	update_aim()

func update_aim() -> void:
	# Get right stick input
	var right_stick = Vector2(
		Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left"),
		Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
	)
	
	# Check if right stick is being used (beyond deadzone)
	if right_stick.length() > controller_deadzone:
		if not use_controller_aim:
			use_controller_aim = true
			aim_mode_changed.emit(true)
			# Hide cursor and move to corner when switching to controller
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			get_viewport().warp_mouse(Vector2.ZERO)
		
		# Update controller aim position relative to player
		controller_aim_position = _player_ref.global_position + (right_stick.normalized() * 100)
		aim_position_updated.emit(controller_aim_position)
	else:
		# Check for mouse movement to switch back
		var current_mouse_pos = get_viewport().get_mouse_position()
		var mouse_velocity = current_mouse_pos - _last_mouse_position
		_last_mouse_position = current_mouse_pos
		
		if mouse_velocity.length() > 0.1 and use_controller_aim:
			use_controller_aim = false
			aim_mode_changed.emit(false)
			# Show cursor again when switching back to mouse
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func get_aim_position() -> Vector2:
	if use_controller_aim:
		return controller_aim_position
	else:
		return _player_ref.get_global_mouse_position()

func is_using_controller() -> bool:
	return use_controller_aim
