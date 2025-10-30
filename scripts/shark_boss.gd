extends Node2D

signal died
signal hp_changed(current_hp: int, max_hp: int)


@export var dive_speed := 200.0
@export var disappear_delay := 0.5
@export var reappear_delay := 1.5
@export var shark_bite_scene: PackedScene
@export var swim_speed := 60.0
@export var arrive_dist := 8.0
@export var path_a_path: NodePath
@export var path_b_path: NodePath
@export var faces_right_default := false
@export var max_hp: int = 20
@export var display_name := "Terror of the Abyss"
@export var lunge_speed := 400.0
@export var lunge_duration := 0.8
@export var lunge_cooldown := 4.0
@export var contact_damage := 1

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var path_a: Marker2D = get_node_or_null(path_a_path)
@onready var path_b: Marker2D = get_node_or_null(path_b_path)
@onready var hurtbox: Area2D = get_node_or_null("Hurtbox")


enum BossState { SWIM, ATTACK, COOLDOWN }
var _state: BossState = BossState.SWIM
var _action_lock := false  # true while performing any attack or transition
var _swim_timer: Timer
var _rng := RandomNumberGenerator.new()
var hp: int
var _target_marker: Marker2D
var _target: Vector2
var _is_lunging := false
var _lunge_timer := 0.0
var _lunge_dir := Vector2.ZERO
var _hit_lock := false
var _is_diving := false

# -------------------------------
# INITIAL SETUP
# -------------------------------
func _ready() -> void:
	add_to_group("boss")
	hp = max_hp
	if anim:
		if "Swim" in anim.sprite_frames.get_animation_names():
			anim.play("Swim")
		else:
			anim.play()

	if path_a and path_b:
		var da = global_position.distance_to(path_a.global_position)
		var db = global_position.distance_to(path_b.global_position)
		_target_marker = path_b if db < da else path_a
		_target = _target_marker.global_position
	else:
		push_warning("SharkBoss missing path markers")

	if hurtbox:
		hurtbox.monitoring = true
		if not hurtbox.is_connected("area_entered", Callable(self, "_on_hurt_area_entered")):
			hurtbox.area_entered.connect(_on_hurt_area_entered)
		if not hurtbox.is_connected("body_entered", Callable(self, "_on_hurt_body_entered")):
			hurtbox.body_entered.connect(_on_hurt_body_entered)
	else:
		push_warning("SharkBoss: Hurtbox node missing or not found")

	hp_changed.emit(hp, max_hp)
	_rng.randomize()
	_swim_timer = Timer.new()
	_swim_timer.one_shot = true
	add_child(_swim_timer)
	await _run_state_loop()


# -------------------------------
# HELPER: UPDATE FACING
# -------------------------------
func update_facing(dir: Vector2) -> void:
	if not anim:
		return
	if abs(dir.x) > 0.1:
		var moving_left = dir.x < 0
		anim.flip_h = moving_left if faces_right_default else not moving_left

# -------------------------------
# DAMAGE + DEATH
# -------------------------------
func take_damage(amount: int) -> void:
	if _hit_lock:
		return
	hp = max(0, hp - amount)
	hp_changed.emit(hp, max_hp)
	if hp == 0:
		die()
	else:
		_hit_lock = true
		await get_tree().create_timer(0.05).timeout
		_hit_lock = false

func apply_damage(amount: int) -> void:
	take_damage(amount)

func die() -> void:
	died.emit()
	queue_free()

# -------------------------------
# HURTBOX SIGNALS
# -------------------------------
func _on_hurt_area_entered(area: Area2D) -> void:
	if _hit_lock:
		return
	if area.is_in_group("projectile"):
		area.queue_free()
		take_damage(1)

func _on_hurt_body_entered(body: Node) -> void:
	if _hit_lock:
		return
	if body.is_in_group("projectile"):
		body.queue_free()
		take_damage(1)
	elif body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(contact_damage)

# -------------------------------
# MOVEMENT + ATTACKS
# -------------------------------
func _physics_process(delta: float) -> void:
	if not _target_marker:
		return

	# Lunge movement still handled here while lunging
	if _is_lunging:
		global_position += _lunge_dir * lunge_speed * delta
		update_facing(_lunge_dir)
		_lunge_timer -= delta
		if _lunge_timer <= 0.0:
			_is_lunging = false
			# ---- Add this to reset the animation after lunge ----
			if anim and "Swim" in anim.sprite_frames.get_animation_names():
				anim.play("Swim")
		return


	# Only swim-pathing during SWIM state and when not diving/lunging
	if _state == BossState.SWIM and not _is_diving and not _action_lock:
		var to_target = _target - global_position
		if to_target.length() > arrive_dist:
			var step = to_target.normalized() * swim_speed * delta
			global_position += step
			update_facing(step)
		else:
			_target_marker = path_a if _target_marker == path_b else path_b
			_target = _target_marker.global_position


func _run_state_loop() -> void:
	while hp > 0:
		# SWIM PHASE: 15–25 seconds patrolling A<->B, no attacks can start
		_state = BossState.SWIM
		_action_lock = false
		var swim_dur := _rng.randi_range(15, 25)
		_swim_timer.start(float(swim_dur))
		while _swim_timer.time_left > 0.0 and hp > 0:
			await get_tree().process_frame

		# ATTACK PHASE: pick exactly one attack, run it to completion
		_state = BossState.ATTACK
		_action_lock = true
		var do_lunge := _rng.randf() < 0.5
		if do_lunge:
			await _do_charge_then_lunge()
		else:
			await _do_dive_then_bite()

		# COOLDOWN PHASE: brief settle to avoid immediate overlaps
		_state = BossState.COOLDOWN
		await get_tree().create_timer(0.4).timeout



# -------------------------------
# DIVE ATTACK
# -------------------------------

func _do_dive_then_bite() -> void:
	if _is_diving:
		return
	_is_diving = true
	var dir = (_target - global_position).normalized()
	update_facing(dir)
	var offscreen_target = global_position + dir * 800.0
	var travel_time = (offscreen_target - global_position).length() / dive_speed
	if anim:
		anim.modulate = Color(0.7, 0.7, 0.7)
		anim.play("Swim")
	var tween = create_tween()
	tween.tween_property(self, "global_position", offscreen_target, travel_time)
	await tween.finished
	visible = false
	await get_tree().create_timer(disappear_delay).timeout
	summon_shark_bite()
	await get_tree().create_timer(reappear_delay).timeout
	visible = true
	anim.modulate = Color(1, 1, 1)
	_is_diving = false


func start_dive_attack() -> void:
	if _action_lock or _state != BossState.ATTACK:
		return
	await _do_dive_then_bite()
	if _is_diving:
		return
	_is_diving = true
	print("SharkBoss begins dive attack!")

	var dir = (_target - global_position).normalized()
	update_facing(dir)
	var offscreen_target = global_position + dir * 800.0
	var travel_time = (offscreen_target - global_position).length() / dive_speed

	if anim:
		anim.modulate = Color(0.7, 0.7, 0.7)
		anim.play("Swim")

	var tween = create_tween()
	tween.tween_property(self, "global_position", offscreen_target, travel_time)
	await tween.finished

	visible = false
	await get_tree().create_timer(disappear_delay).timeout

	summon_shark_bite()
	await get_tree().create_timer(reappear_delay).timeout
	reappear()

func reappear() -> void:
	print("SharkBoss returns to battle!")
	visible = true
	anim.modulate = Color(1, 1, 1)
	_is_diving = false

# -------------------------------
# SHARK BITE SUMMON
# -------------------------------
func summon_shark_bite() -> void:
	if not shark_bite_scene:
		push_warning("No shark_bite_scene assigned in Inspector.")
		return

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("No player found for Shark Bite.")
		return

	var bite = shark_bite_scene.instantiate()
	bite.global_position = player.global_position
	get_parent().add_child(bite)
	print("Summoned Shark Bite attack at player position!")

# -------------------------------
# LUNGE ATTACK
# -------------------------------

func _do_charge_then_lunge() -> void:
	# Play charge warning if available
	if anim:
		if "Charge" in anim.sprite_frames.get_animation_names():
			anim.play("Charge")
			await anim.animation_finished
	# Start lunge towards player
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	_is_lunging = true
	_lunge_timer = lunge_duration
	_lunge_dir = (player.global_position - global_position).normalized()
	update_facing(_lunge_dir)
	if anim and "Lunge" in anim.sprite_frames.get_animation_names():
		anim.play("Lunge")
	# Wait until lunge timer ends
	while _is_lunging:
		await get_tree().physics_frame


func start_lunge() -> void:
	if _action_lock or _state != BossState.ATTACK:
		return
	await _do_charge_then_lunge()
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	_is_lunging = true
	_lunge_timer = lunge_duration
	_lunge_dir = (player.global_position - global_position).normalized()
	update_facing(_lunge_dir) # fix flip before lunging

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
