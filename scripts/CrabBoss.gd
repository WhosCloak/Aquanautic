extends Node2D

signal died
signal hp_changed(current: int, maximum: int)

@export var max_hp := 100
@export var contact_damage := 1
@export var walk_speed := 50.0
@export var arrive_dist := 10.0
@export var path_a_path: NodePath
@export var path_b_path: NodePath
@export var faces_right_default := true
@export var display_name := "Crab Tyrant"

# Attack timing 
@export var slam_cooldown := 3.0
@export var cointoss_cooldown := 6.0

# Phase 2 tweaks
@export var phase2_walk_speed := 70.0
@export var phase2_slam_cooldown := 2.5
@export var phase2_cointoss_cooldown := 4.5
@export var gold_spriteframes: SpriteFrames


# Internal state
var hp := 0
var _hit_lock := false
var _target_marker: Marker2D = null
var _target: Vector2
var _is_attacking := false
var _is_blocking := false
var _in_phase2 := false
var flash_duration := 0.1

# Preloads
var coin_scene := preload("res://scenes/CrabBossNormal/GoldCoinProjectile.tscn")
var rock_scene := preload("res://scenes/CrabBossNormal/rock_boulder.tscn")
@export var rock_drop_markers_path: NodePath
@onready var rock_drop_root: Node = get_node_or_null(rock_drop_markers_path)
@export var rock_fall_sound: AudioStream = preload("res://audios/rock fall.mp3")

@export var slam_attack_sound: AudioStream = preload("res://audios/crab_ground_slam_2.mp3")
@export var coin_attack_sound: AudioStream = preload("res://audios/crab_coin_toss_2.mp3")


# Cached nodes
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var path_a: Marker2D = get_node_or_null(path_a_path)
@onready var path_b: Marker2D = get_node_or_null(path_b_path)
@onready var attack_timer: Timer = $AttackTimer
@onready var coin_muzzle := $CoinMuzzle


func _ready() -> void:
	if Global.testing_mode:
		max_hp = 10
	_duplicate_materials_recursive(self)
	add_to_group("boss")
	hp = max_hp
	emit_signal("hp_changed", hp, max_hp)
	
	if anim:
		anim.play("Walk")
		anim.animation_finished.connect(_on_anim_finished)
		
	if hurtbox:
		hurtbox.monitoring = true
		hurtbox.area_entered.connect(_on_hurt_area_entered)
		hurtbox.body_entered.connect(_on_hurt_area_entered)
		
	# pick initial patrol target
	if path_a and path_b:
		var da := global_position.distance_to(path_a.global_position)
		var db := global_position.distance_to(path_b.global_position)
		_target_marker = path_b if db < da else path_a
		_target = _target_marker.global_position
		
	# start attack pattern
	if attack_timer:
		attack_timer.wait_time = slam_cooldown
		attack_timer.start()
		
func _physics_process(delta: float) -> void:
	if _hit_lock or _is_attacking:
		return
	
	# move toward current target 
	var to_t := _target - global_position
	if to_t.length() > arrive_dist:
		var step := to_t.normalized() * walk_speed * delta
		global_position += step
		if anim:
			var moving_left := step.x < 0
			anim.flip_h = moving_left if faces_right_default else not moving_left
	else:
		# reach one end, switch direction
		if path_a and path_b and _target_marker:
			_target_marker = path_a if _target_marker == path_b else path_b
			_target = _target_marker.global_position
			
func _on_hurt_area_entered(b: Node) -> void:
	if _hit_lock:
		return
	if b.is_in_group("projectile"):
		b.queue_free()
		apply_damage(contact_damage)
		
func apply_damage(amount: int) -> void:
	await flash_hit()
	if _is_blocking:
		return  # takes no damage

	hp = max(0, hp - amount)
	emit_signal("hp_changed", hp, max_hp)

	# checks if phase2 should start
	if not _in_phase2 and hp <= max_hp * 0.5:
		_enter_phase2()

	if hp == 0:
		_die()
	else:
		_hit_lock = true
		await get_tree().create_timer(0.05).timeout
		_hit_lock = false
		

# ===== FLASH EFFECT WHEN HIT =====
func flash_hit() -> void:
	var affected_nodes = _get_flashable_nodes(self)
	
	for node in affected_nodes:
		var mat: ShaderMaterial = node.material
		if mat and mat is ShaderMaterial:
			mat.set_shader_parameter("flash_strength", 1.0)

	await get_tree().create_timer(0.1).timeout

	for node in affected_nodes:
		var mat: ShaderMaterial = node.material
		if mat and mat is ShaderMaterial:
			mat.set_shader_parameter("flash_strength", 0.0)

# ===== RECURSIVE SEARCH FOR FLASHABLE MATERIALS =====
func _get_flashable_nodes(root: Node) -> Array:
	var nodes := []
	for child in root.get_children():
		if child is CanvasItem and child.material and child.material is ShaderMaterial:
			nodes.append(child)
		
		# Check children recursively
		nodes += _get_flashable_nodes(child)
	return nodes

# ===== DUPLICATE MATERIALS RECURSIVELY =====
func _duplicate_materials_recursive(root: Node) -> void:
	for child in root.get_children():
		if child is CanvasItem and child.material and child.material is ShaderMaterial:
			child.material = child.material.duplicate()
		_duplicate_materials_recursive(child)

func _enter_phase2() -> void:
	_in_phase2 = true
	
	if gold_spriteframes and anim:
		anim.sprite_frames = gold_spriteframes
		anim.play("Walk")
	
	walk_speed = phase2_walk_speed
	slam_cooldown = phase2_slam_cooldown
	cointoss_cooldown = phase2_cointoss_cooldown

func _die() -> void:
	emit_signal("died")
	queue_free()
	
# Animation control
func _on_anim_finished() -> void:
	_is_attacking = false
	if anim:
		anim.play("Walk")
	_is_blocking = false # resets blocking when animation ends
	

# --- ATTACKS --- #

func _perform_slam() -> void:
	if _is_attacking:
		return
	_is_attacking = true
	anim.play("slam")

	# Drop rocks after delay
	await get_tree().create_timer(1.2).timeout
	_spawn_rocks()

	# Wait roughly as long as the slam animation duration
	await get_tree().create_timer(1.0).timeout

	# Return to walking
	anim.play("Walk")
	_is_attacking = false

	# Walk break before next attack
	await get_tree().create_timer(2.0).timeout
	if attack_timer:
		attack_timer.wait_time = randf_range(slam_cooldown, cointoss_cooldown)
		attack_timer.start()

func _perform_cointoss() -> void:
	if _is_attacking:
		return
	_is_attacking = true
	anim.play("cointoss")

	# Wait a short moment before tossing coin
	await get_tree().create_timer(0.5).timeout
	_shoot_coin()

	# Wait roughly same as the cointoss animation length
	await get_tree().create_timer(1.0).timeout

	anim.play("Walk")
	_is_attacking = false

	await get_tree().create_timer(2.0).timeout
	if attack_timer:
		attack_timer.wait_time = randf_range(slam_cooldown, cointoss_cooldown)
		attack_timer.start()


func _perform_block() -> void:
	if _is_attacking:
		return
	_is_attacking = true
	_is_blocking = true
	anim.play("block")

	# Stay blocking for a bit
	await get_tree().create_timer(1.5).timeout
	_is_blocking = false
	_is_attacking = false

	# Return to walking
	anim.play("Walk")

	await get_tree().create_timer(2.0).timeout
	if attack_timer:
		attack_timer.wait_time = randf_range(slam_cooldown, cointoss_cooldown)
		attack_timer.start()


func _perform_sword_slash() -> void:
	if _is_attacking:
		return
	_is_attacking = true
	anim.play("flame_slash")

	# Create short-lived hitbox
	var hitbox := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.extents = Vector2(40, 20)
	shape.shape = rect
	hitbox.add_child(shape)

	hitbox.position = Vector2(-60 if anim.flip_h else 60, 0)
	add_child(hitbox)
	hitbox.set_deferred("monitoring", true)
	hitbox.body_entered.connect(func(b):
		if b.is_in_group("player") and b.has_method("apply_damage"):
			b.apply_damage(2)
	)

	# Keep hitbox active for a moment
	await get_tree().create_timer(0.4).timeout
	hitbox.queue_free()

	# Wait roughly same as the sword slash animation
	await get_tree().create_timer(1.0).timeout

	anim.play("Walk")
	_is_attacking = false

	await get_tree().create_timer(2.0).timeout
	if attack_timer:
		attack_timer.wait_time = randf_range(slam_cooldown, cointoss_cooldown)
		attack_timer.start()

func _spawn_rocks():
	if not rock_drop_root or not rock_scene:
		return

	var fall_audio = AudioStreamPlayer2D.new()
	fall_audio.stream = rock_fall_sound
	add_child(fall_audio)
	fall_audio.play()
	

	for marker in rock_drop_root.get_children():
		if marker is Marker2D:
			var rock = rock_scene.instantiate()
			rock.global_position = marker.global_position
			get_tree().current_scene.add_child(rock)

func _shoot_coin():
	if not coin_scene or not coin_muzzle:
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
		
	var coin = coin_scene.instantiate()
	coin.global_position = coin_muzzle.global_position
	get_tree().current_scene.add_child(coin)
		
	if coin.has_method("set_target"):
		coin.set_target(player)


func _on_attack_timer_timeout() -> void:
	if _is_attacking:
		return

	var attacks = ["slam", "cointoss", "sword_slash", "block"]
	var attack = attacks[randi() % attacks.size()]

	match attack:
		"slam":
			_perform_slam()
		"cointoss":
			_perform_cointoss()
		"sword_slash":
			_perform_sword_slash()
		"block":
			_perform_block()
