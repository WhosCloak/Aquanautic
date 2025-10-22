extends "res://scripts/interactable.gd"

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	interact_name = "[E] to Interact"
	is_interactable = true
	interact = Callable(self, "_on_interact")

func _on_interact():
	is_interactable = false

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.multi_shot = true
		audio_stream_player.play()
		await get_tree().create_timer(10.0).timeout
		player.multi_shot = false
		print("multishot expired")

	self.queue_free()
