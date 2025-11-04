extends Node

@onready var video: VideoStreamPlayer = $Video
@onready var fade = get_node("/root/Fade")

func _ready():
	fade.transition()
	await fade.on_transition_finished
	video.play()

	video.finished.connect(_on_video_finished)
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_end_credits()

func _on_video_finished():
	_end_credits()

func _end_credits():
	fade.transition()
	await fade.on_transition_finished
	get_tree().change_scene_to_file("res://scenes/mainmenu/main_menu.tscn")
