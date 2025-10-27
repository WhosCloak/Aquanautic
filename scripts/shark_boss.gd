extends Node2D

signal died
signal hp_changed(current_hp: int, max_hp: int)

@export var swim_speed := 60.0
@export var arrive_dist := 8.0
@export var path_a_path: NodePath
@export var path_b_path: NodePath
@export var faces_right_default := false
@export var max_hp: int = 20
@export var display_name := "Terror of the Abyss"
@export var lunge_speed := 600.0
@export var lunge_duration := 0.8
@export var lunge_cooldown := 4.0
@export var contact_damage := 1

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var path_a: Marker2D = get_node_or_null(path_a_path)
@onready var path_b: Marker2D = get_node_or_null(path_b_path)
@onready var hurtbox: Area2D = get_node_or_null("Hurtbox")

var hp: int
var _target_marker: Marker2D
var _target: Vector2
var _is_lunging := false
var _lunge_timer := 0.0
var _lunge_dir := Vector2.ZERO
var _hit_lock := false

func _ready() -> void:
	add_to_group("boss")
	hp = max_hp
	if anim:
		# Play any default swim/idle animation if present
		if "Swim" in anim.sprite_frames.get_animation_names():
			anim.play("Swim")
		else:
			anim.play()

	# Pick initial patrol target
	if path_a and path_b:
		var da = global_position.distance_to(path_a.global_position)
		var db = global_position.distance_to(path_b.global_position)
		_target_marker = path_b if db < da else path_a
		_target = _target_marker.global_position
	else:
		push_warning("SharkBoss missing path markers")

	# Hook hurtbox signals robustly (both area and body), and ensure monitoring is on
	if hurtbox:
		hurtbox.monitoring = true
		if not hurtbox.is_connected("area_entered", Callable(self, "_on_hurt_area_entered")):
			hurtbox.area_entered.connect(_on_hurt_area_entered)
		if not hurtbox.is_connected("body_entered", Callable(self, "_on_hurt_body_entered")):
			hurtbox.body_entered.connect(_on_hurt_body_entered)
	else:
		push_warning("SharkBoss: Hurtbox node missing or not found")

	# Initialize boss HP UI
	hp_changed.emit(hp, max_hp)

func take_damage(amount: int) -> void:
	if _hit_lock:
		return
	hp = max(0, hp - amount)
	hp_changed.emit(hp, max_hp)
	if hp == 0:
		die()
	else:
		# brief invulnerability to prevent multi-hit in a single frame
		_hit_lock = true
		await get_tree().create_timer(0.05).timeout
		_hit_lock = false

# Area2D overlaps (projectile as Area2D)
func _on_hurt_area_entered(area: Area2D) -> void:
	# Debug prints help confirm collisions in case of filter issues
	# print("Shark hurtbox area_entered:", area.name)
	if _hit_lock:
		return
	if area.is_in_group("projectile"):
		area.queue_free()
		take_damage(1)

# PhysicsBody2D overlaps (projectile as Body)
func _on_hurt_body_entered(body: Node) -> void:
	# print("Shark hurtbox body_entered:", body.name)
	if _hit_lock:
		return

	# If projectile is implemented as a Body in this level
	if body.is_in_group("projectile"):
		if body is Node:
			body.queue_free()
		take_damage(1)
		return

	# Player contact damage while lunging or on contact
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(contact_damage)

# Back-compat: allow other code to apply damage directly
func apply_damage(amount: int) -> void:
	take_damage(amount)

func _physics_process(delta: float) -> void:
	if not _target_marker:
		return

	if _is_lunging:
		global_position += _lunge_dir * lunge_speed * delta
		_lunge_timer -= delta
		if _lunge_timer <= 0.0:
			_is_lunging = false
		return

	# Swim toward target marker
	var to_target = _target - global_position
	if to_target.length() > arrive_dist:
		var step = to_target.normalized() * swim_speed * delta
		global_position += step
		if anim:
			var moving_left = step.x < 0.0
			anim.flip_h = moving_left if faces_right_default else not moving_left
	else:
		# Reached marker: swap target and possibly lunge
		_target_marker = path_a if _target_marker == path_b else path_b
		_target = _target_marker.global_position

		# Simple random lunge trigger on turns
		if randi_range(0, 2) == 0:
			start_lunge()

func start_lunge() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	_is_lunging = true
	_lunge_timer = lunge_duration
	_lunge_dir = (player.global_position - global_position).normalized()

	# Telegraph with animation or tint
	if anim:
		if "Charge" in anim.sprite_frames.get_animation_names():
			anim.play("Charge")
		else:
			anim.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.3).timeout
	if anim:
		anim.modulate = Color(1, 1, 1)
		if "Lunge" in anim.sprite_frames.get_animation_names():
			anim.play("Lunge")

func die() -> void:
	# print("SharkBoss defeated!")
	died.emit()
	queue_free()
