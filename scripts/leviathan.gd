extends CharacterBody2D

signal died
var dying = false
signal hp_changed(current: int, maximum: int)

@export var max_hp := 100
@export var contact_damage := 1
@export var swim_speed := 70.0
@export var arrive_dist := 10.0
@export var path_a_path: NodePath
@export var path_b_path: NodePath
@export var faces_right_default := false
@export var display_name := "The Leviathan"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var lightning_muzzle = $LightningMuzzle
@onready var attack_timer: Timer = $AttackTimer
@onready var shield: AnimatedSprite2D = $Shield
@onready var shield_timer: Timer = Timer.new()
@onready var path_a: Marker2D = get_node_or_null(path_a_path)
@onready var path_b: Marker2D = get_node_or_null(path_b_path)
@onready var spawn_timer: Timer = Timer.new()

# Audio players
@onready var boss_theme_player: AudioStreamPlayer = $boss_theme_player
@onready var roar_player: AudioStreamPlayer = $roar_player
@onready var lightning_player: AudioStreamPlayer = $lightning_player

var enemy7_scene = preload("res://scenes/Enemies/enemy7.tscn")
var shield_active = false
var lightning_bolt_scene = preload("res://scenes/BossLevels/lightning_bolt.tscn")
var hp := 0
var _hit_lock := false
var _target_marker: Marker2D = null
var _target: Vector2

func _ready() -> void:
	if not attack_timer.timeout.is_connected(_on_attack_timer_timeout):
		attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()

	add_child(shield_timer)
	shield_timer.wait_time = 5.0
	shield_timer.one_shot = true
	shield_timer.timeout.connect(_on_shield_timeout)

	add_child(spawn_timer)
	spawn_timer.wait_time = 10.0
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timeout)

	add_to_group("boss")
	hp = max_hp
	emit_signal("hp_changed", hp, max_hp)

	if anim:
		anim.play("swim")

	if boss_theme_player:
		boss_theme_player.play()

	if hurtbox:
		hurtbox.monitoring = true
		hurtbox.area_entered.connect(_on_hurt_area_entered)
		hurtbox.body_entered.connect(_on_hurt_area_entered)

	if path_a and path_b:
		var da = global_position.distance_to(path_a.global_position)
		var db = global_position.distance_to(path_b.global_position)
		_target_marker = path_b if db < da else path_a
		_target = _target_marker.global_position
	else:
		_target_marker = null
		_target = global_position + Vector2(200, 0)

func shoot_lightning(target_pos: Vector2):
	if anim:
		anim.play("swim")
	var bolt = lightning_bolt_scene.instantiate()
	bolt.global_position = lightning_muzzle.global_position
	var dir = (target_pos - bolt.global_position).normalized()
	bolt.rotation = dir.angle()
	bolt.linear_velocity = dir * 300
	get_tree().current_scene.add_child(bolt)

	if lightning_player:
		lightning_player.play()

func activate_shield():
	shield_active = true
	shield.visible = true
	shield.play("shield_activate", true)
	hurtbox.monitoring = false
	shield_timer.start()

	if roar_player:
		roar_player.play()

func _on_shield_timeout():
	shield_active = false
	shield.visible = false
	hurtbox.monitoring = true

func spawn_enemy7():
	var enemy = enemy7_scene.instantiate()
	var offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))
	enemy.global_position = global_position + offset
	get_tree().current_scene.add_child(enemy)

	spawn_timer.start()
	despawn_enemy_later(enemy)

func despawn_enemy_later(enemy: Node):
	await get_tree().create_timer(20.0).timeout
	if enemy and enemy.is_inside_tree():
		enemy.queue_free()

func _on_spawn_timeout():
	pass

func _on_attack_timer_timeout():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		shoot_lightning(player.global_position)

	if not shield_active and randf() < 0.25:
		activate_shield()

	if not spawn_timer.is_stopped():
		return
	if randf() < 0.5:
		spawn_enemy7()

func _physics_process(delta: float) -> void:
	if _hit_lock:
		return

	var to_t = _target - global_position
	var step = Vector2.ZERO

	if to_t.length() > arrive_dist:
		step = to_t.normalized() * swim_speed * delta
		global_position += step

	if anim:
		var moving_left = step.x < 0.0
		var new_flip = moving_left if faces_right_default else not moving_left

		if anim.flip_h != new_flip:
			anim.flip_h = new_flip
			lightning_muzzle.position.x = -lightning_muzzle.position.x

	if to_t.length() <= arrive_dist:
		if path_a and path_b and _target_marker != null:
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

func _die():
	if dying:
		return
	dying = true

	died.emit()

	visible = false
	set_process(false)
	set_physics_process(false)

	if boss_theme_player:
		boss_theme_player.stop()

	if not is_inside_tree():
		return

	Fade.transition()
	await Fade.on_transition_finished

	if is_inside_tree() and get_tree() != null:
		get_tree().change_scene_to_file("res://scenes/CreditsPlayer.tscn")
