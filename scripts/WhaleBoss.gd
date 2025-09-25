extends Node2D
signal died
signal hp_changed(current: int, maximum: int)

@export var max_hp := 90
@export var contact_damage := 1
@export var swim_speed := 60.0
@export var arrive_dist := 8.0
@export var path_a_path: NodePath
@export var path_b_path: NodePath
@export var faces_right_default := false

var hp := 0
var _hit_lock := false

@onready var hurtbox: Area2D = $Hurtbox
@onready var anim:AnimatedSprite2D = $AnimatedSprite2D
@onready var path_a: Marker2D = get_node_or_null(path_a_path)
@onready var path_b: Marker2D = get_node_or_null(path_b_path)
var _target_marker: Marker2D = null
var _target: Vector2


func _ready() -> void:
	add_to_group("boss")
	hp = max_hp
	
	if anim:
		anim.play()
		
	if hurtbox:
		hurtbox.monitoring = true
		hurtbox.area_entered.connect(_on_hurt_area_entered)
		hurtbox.body_entered.connect(_on_hurt_area_entered)
	else:
		push_warning("WhaleBoss, Hurtbox not found")
		
	if path_a and path_b:
		var da := global_position.distance_to(path_a.global_position)
		var db := global_position.distance_to(path_b.global_position)
		_target_marker = path_b if db < da else path_a
		_target = _target_marker.global_position
	else:
		_target_marker = null
		_target = global_position + Vector2(200, 0)

	emit_signal("hp_changed", hp, max_hp)
	
func _physics_process(delta: float) -> void:
	if _hit_lock:
		return
	var to_t := _target - global_position
	if to_t.length() > arrive_dist:
		var step := to_t.normalized() * swim_speed * delta
		global_position += step
		if anim:
			var moving_left := step.x < 0.0
			anim.flip_h = moving_left if faces_right_default else not moving_left
	else:
		if path_a and path_b and _target_marker != null:
			_target_marker = path_a if _target_marker == path_b else path_b
			_target = _target_marker.global_position
		else:
			_target = global_position + Vector2(-_target.x, 0)


func _on_hurt_area_entered(b: Node) -> void:
	if _hit_lock:
		return
	if b.is_in_group("projectile"):
		b.queue_free()
		apply_damage(contact_damage)
		
func apply_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	emit_signal("hp_changed", hp, max_hp)
	if hp == 0:
		_die()
	else:
		_hit_lock = true
		await get_tree().create_timer(0.05).timeout
		_hit_lock = false
		
func _die() -> void:
	emit_signal("died")
	queue_free()
