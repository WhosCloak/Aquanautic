extends Control

var player = Node2D
signal request_level_change(level_path: String)

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	hide()
	
func _process(_delta: float) -> void:
	openshop()
	
func inshop():
	get_tree().paused = true
	show()
	
func openshop():
	if player.score >= 2:
		inshop()



func _on_button_pressed() -> void:  # 1st item
	pass # Replace with function body


func _on_button_2_pressed() -> void:  #2nd item
	pass # Replace with function body.


func _on_button_3_pressed() -> void:  #3rd item
	pass # Replace with function body.


func _on_button_4_pressed() -> void:
	emit_signal("request_level_change", "res://scenes/level_2.tscn")
	get_tree().paused = false
