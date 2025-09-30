extends Area2D


var player = Node2D



func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	
	
	

func _on_body_entered(body: Node2D) -> void:
	print("player entered power up")
