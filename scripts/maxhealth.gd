extends "res://scripts/interactable.gd"

func _ready() -> void:
	interact_name = "[E] to Heal"
	is_interactable = true
	interact = Callable(self, "_on_interact")

func _on_interact():
	is_interactable = false

	var player = get_tree().get_first_node_in_group("player")
	if player and player.health < player.max_health:
		player.heal(1)
		if $maxhealthaudio:
			$maxhealthaudio.play()
		await get_tree().create_timer(0.1).timeout
		queue_free()
	else:
		is_interactable = true
