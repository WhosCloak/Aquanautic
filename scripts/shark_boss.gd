extends Node2D
signal died

# SharkBoss: swims between PathA and PathB

@export var swim_speed := 60.0
@export var arrive_dist := 8.0
@export var path_a_path: NodePath
@export var path_b_path: NodePath
@export var faces_right_default := false
@export var display_name := "Terror of the Abyss"

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var path_a: Marker2D = get_node_or_null(path_a_path)
@onready var path_b: Marker2D = get_node_or_null(path_b_path)

var _target_marker: Marker2D
var _target: Vector2

func _ready() -> void:
	add_to_group("boss")

	if anim:
		anim.play("Swim")

	# Pick the closer marker to start swimming toward the other
	if path_a and path_b:
		var da = global_position.distance_to(path_a.global_position)
		var db = global_position.distance_to(path_b.global_position)
		_target_marker = path_b if db < da else path_a
		_target = _target_marker.global_position
	else:
		push_warning("SharkBoss missing path markers")

func _physics_process(delta: float) -> void:
	if not _target_marker:
		return

	var to_target = _target - global_position
	if to_target.length() > arrive_dist:
		var step = to_target.normalized() * swim_speed * delta
		global_position += step
		if anim:
			var moving_left = step.x < 0
			anim.flip_h = moving_left if faces_right_default else not moving_left
	else:
		# Switch target marker
		_target_marker = path_a if _target_marker == path_b else path_b
		_target = _target_marker.global_position

func die() -> void:
	print("SharkBoss defeated!")
	died.emit()
	queue_free()
