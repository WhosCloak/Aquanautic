extends Camera2D
#the following code prevents the player from seeing past the ocean floor#
@export var floor_y: float = 830.0
@export var padding: float = 0.0

func _process(delta: float) -> void:
	var half_h := get_viewport_rect().size.y * 0.5 / zoom.y
	var  max_cam_y := floor_y - half_h + padding
	global_position.y = min(global_position.y, max_cam_y)
