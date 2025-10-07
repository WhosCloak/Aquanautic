extends "res://scripts/interactable.gd"

func _ready() -> void:
	interact_name = "Multishot"
	is_interactable = true
	interact = Callable(self, "_on_interact")

func _on_interact():
	is_interactable = false
	print("player is interacting!")
	self.hide() # Optional: hide powerup after pickup
