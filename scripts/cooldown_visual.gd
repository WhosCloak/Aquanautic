extends AnimatedSprite2D

@onready var cooldownbar: ProgressBar = $"../cooldownbar"

func _process(_delta: float) -> void:
	if cooldownbar == null:
		return

	var ratio := cooldownbar.value / cooldownbar.max_value

	var frame_count := sprite_frames.get_frame_count(animation)
	var new_frame := int((1.0 - ratio) * (frame_count - 1)) 
	frame = clamp(new_frame, 0, frame_count - 1)
