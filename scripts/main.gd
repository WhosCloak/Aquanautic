extends Node2D

@onready var level_root = $LevelRoot
@onready var shop = $CanvasLayer/shop
var current_level: Node = null
var level_requirements = {
	"res://scenes/levels/level_1.tscn": 2,
	"res://scenes/levels/level_2.tscn": 5,
	"res://scenes/levels/level_3.tscn": 1000000
}

func _ready() -> void:
	load_level("res://scenes/levels/level_1.tscn")
	shop.request_level_change.connect(_on_request_level_change)

func load_level(path: String) -> void:
	if current_level:
		current_level.queue_free()

	var new_level = load(path).instantiate()
	level_root.add_child(new_level)
	current_level = new_level

	var req = level_requirements.get(path, 2)
	shop.reset_for_new_level(req)

func _on_request_level_change(path: String) -> void:
	load_level(path)
