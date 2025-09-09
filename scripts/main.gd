extends Node2D

@onready var level_root = $LevelRoot
var current_level: Node = null

func _ready() -> void:
	load_level("res://scenes/level_1.tscn")

	var shop = $CanvasLayer/shop
	shop.request_level_change.connect(_on_request_level_change)

func load_level(path: String) -> void:
	if current_level and current_level.is_inside_tree():
		current_level.queue_free()

	var level_scene = load("res://scenes/level_1.tscn")
	current_level = level_scene.instantiate()
	level_root.add_child(current_level)

func _on_request_level_change(level_path: String) -> void:
	load_level("res://scenes/level_2.tscn")
