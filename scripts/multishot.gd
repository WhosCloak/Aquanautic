extends Area2D

@onready var interactable: Area2D = $interactable


func _ready() -> void:
	interactable.is_interactable = true
	interactable.interact_name = "Multishot"
	interactable.interact = _on_interact
	
func _on_interact():
	interactable.is_interactable = false
	print("player is interacting")
