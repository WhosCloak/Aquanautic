extends "res://scripts/interactable.gd"

func _ready() -> void:
	interact_name = "[E] to Interact"
	is_interactable = true
	interact = Callable(self, "_on_interact")

func _on_interact():
	is_interactable = false

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.heal()
		$maxhealthaudio.play()
	self.queue_free()
