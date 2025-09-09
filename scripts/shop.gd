extends Control

var player = Node2D

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
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Base_Level/Level2.tscn")
