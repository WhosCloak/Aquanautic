extends Control

var player: Node2D
var score_requirement: int = 2
var shop_opened := false
signal request_level_change(level_path: String)

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	hide()

func _process(_delta: float) -> void:
	if player and not shop_opened and player.score >= score_requirement:
		inshop()

func inshop() -> void:
	get_tree().paused = true
	show()
	shop_opened = true


func close_shop() -> void:
	get_tree().paused = false
	hide()


func reset_for_new_level(required_score: int) -> void:
	shop_opened = false
	score_requirement = required_score
	hide()

func _on_end_pressed() -> void:
	close_shop()
	emit_signal("request_level_change", "res://scenes/levels/level_2.tscn")


func _on_end_2_pressed() -> void:
		close_shop()
		emit_signal("request_level_change", "res://scenes/levels/level_3.tscn")
