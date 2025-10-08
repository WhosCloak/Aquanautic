extends "res://scripts/interactable.gd"

func _ready() -> void:
	interact_name = "[E] to Interact"
	is_interactable = true
	interact = Callable(self, "_on_interact")

func _on_interact():
	is_interactable = false
	print("Player picked up Multishot!")
	self.hide()  # hide the pickup after collecting

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.multi_shot = true
		print("Multishot activated!")

		# Optional: make the effect temporary (e.g., 10 seconds)
		await get_tree().create_timer(10.0).timeout
		player.multi_shot = false
		print("Multishot expired!")
