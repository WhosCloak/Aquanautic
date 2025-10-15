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

#Internal state
var hp := 0
var _hit_lock := false
var _target_marker: Marker2D = null
var _target: Vector2
var _is_attacking := false

#Preloads (for later)
var coin_scene := preload("res://scenes/GoldCoinProjectile.tscn")
var rock_scene := preload("res://scenes/rock_boulder.tscn")
@export var rock_drop_markers_path: NodePath
@onready var rock_drop_root: Node = get_node_or_null(rock_drop_markers_path)
@export var rock_fall_sound: AudioStream = preload("res://audios/rock fall.mp3")


#Cached nodes
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var path_a: Marker2D = get_node_or_null(path_a_path)
@onready var path_b: Marker2D = get_node_or_null(path_b_path)
@onready var attack_timer: Timer = $AttackTimer
@onready var coin_muzzle := $CoinMuzzle

func _ready() -> void:
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
	
# move toward current  target 
	var to_t := _target - global_position
	if to_t.length() > arrive_dist:
		var step := to_t.normalized() * walk_speed * delta
		global_position += step
		if anim:
			var moving_left := step.x < 0
			anim.flip_h = moving_left if faces_right_default else not moving_left
	else:
		#reach one end, switch direction
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
	
# Animation control
func _on_anim_finished() -> void:
	_is_attacking = false
	if anim:
		anim.play("Walk")
		
# Attack pattern cycle

	
#Attacks
func _perform_slam():
	if anim:
		anim.play("slam")
	_is_attacking = true

	# Play slam sound if it exists
	var slam_audio = $SlamSound if has_node("SlamSound") else null
	if slam_audio:
		slam_audio.play()

	# Delay slightly so rocks fall right after the impact frame
	await get_tree().create_timer(1.2).timeout
	_spawn_rocks()

	await anim.animation_finished
	_is_attacking = false

func _spawn_rocks():
	if not rock_drop_root or not rock_scene:
		return

	# Play falling sound
	var fall_audio = AudioStreamPlayer2D.new()
	fall_audio.stream = rock_fall_sound
	add_child(fall_audio)
	fall_audio.play()

	# For every Marker2D under the root, spawn a rock
	for marker in rock_drop_root.get_children():
		if marker is Marker2D:
			var rock = rock_scene.instantiate()
			rock.global_position = marker.global_position
			get_tree().current_scene.add_child(rock)

func _perform_cointoss():
	if anim:
		anim.play("cointoss")
	_is_attacking = true
	
	await get_tree().create_timer(0.5).timeout #wait before firing coin
	_shoot_coin()
	
func _shoot_coin():
	if not coin_scene or not coin_muzzle:
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
		
	var coin = coin_scene.instantiate()
	coin.global_position = coin_muzzle.global_position
	get_tree().current_scene.add_child(coin)
		
	# give the coin a refrence to the player for homing
	if coin.has_method("set_target"):
		coin.set_target(player)

func _perform_block():
	if anim:
		anim.play("block")
	_is_attacking = true
	await get_tree().create_timer(1.5).timeout
	_is_attacking = false


func _on_attack_timer_timeout() -> void:
	if hp <= 0:
		return
		
	# choose attack based on HP
	if hp <= max_hp * 0.3:
		_perform_block()
	elif randi() % 2 == 0:
		_perform_slam()
	else:
		_perform_cointoss()
		
	attack_timer.wait_time = randf_range(slam_cooldown, cointoss_cooldown)
	attack_timer.start()
