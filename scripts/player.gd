extends CharacterBody2D
# ==============================================
# PLAYER CONTROLLER SCRIPT
# Handles movement, shooting, HUD updates, bubble trail,
# boss UI, damage, healing, and game-over logic.
# ==============================================


# ===== MOVEMENT & STATS =====
var speed := 250                     
var projectilespeed := 500        
var projectile = load("res://scenes/harpoon.tscn") 
var score = Global.player_score     
var max_health := 3
var health := max_health
var multi_shot := false
var firerate := false
var _is_stunned: bool = false
var flash_duration := 0.1
var flip_threshold: float = 1.0

# ===== ARM SOCKET ANIMATION =====
var idle_arm_position: Vector2 = Vector2.ZERO
var swim_arm_position: Vector2 = Vector2(10, 0)

# ===== AUDIO =====
@onready var harpoon: AudioStreamPlayer2D = $Harpoon
@onready var damage_taken: AudioStreamPlayer2D = $DamageTaken
@onready var high_score: AudioStreamPlayer2D = $HighScore


# ===== BUBBLE TRAIL CONFIG =====
var bubble_mat: ParticleProcessMaterial
var emit_speed := 10.0
var base_amount := 80
var max_amount := 180

# ===== INTERNAL REFERENCES =====
var _current_boss: Node = null

# ===== NODE REFERENCES =====
@onready var diver_anim: AnimatedSprite2D = $diver_anim
@onready var diver_arm: Sprite2D = $diver_anim/arm_socket/diver_arm
@onready var arm_socket: Node2D = $diver_anim/arm_socket
@onready var boss_hud: Control = $CanvasLayer/BossHUD
@onready var boss_name: Label = $CanvasLayer/BossHUD/HBoxContainer/BossName
@onready var boss_bar: Range = $CanvasLayer/BossHUD/HBoxContainer/BossBar
@onready var cam := $Camera2D
@onready var score_label = $CanvasLayer/Score/Label
@onready var bubbles: GPUParticles2D = $BubbleTrail
@onready var cooldowntimer: Timer = $cooldowntimer
@onready var cooldownbar: ProgressBar = $CanvasLayer/cooldown/cooldownbar
@onready var controller_manager: Node = $Controller_manager
@onready var hearts := [
	$CanvasLayer/Hearts/Heart1,
	$CanvasLayer/Hearts/Heart2,
	$CanvasLayer/Hearts/Heart3
]
# ==============================================
# ==== LIFECYCLE & INITIALIZATION ====
# ==============================================
func _ready():
	cam.zoom = Vector2(3.5, 3.5)
	update_hearts()
	cam.set_process(true)
	if boss_hud:
		boss_hud.visible = false
	cooldownbar.max_value = cooldowntimer.wait_time
	cooldownbar.value = cooldowntimer.wait_time
	
	if arm_socket:
		idle_arm_position = arm_socket.position
		swim_arm_position = Vector2(10, 0)
	
	if bubbles:
		if bubbles.process_material and bubbles.process_material is ParticleProcessMaterial:
			bubble_mat = bubbles.process_material
		else:
			bubble_mat = ParticleProcessMaterial.new()
			bubbles.process_material = bubble_mat
		
		bubbles.emitting = false
		bubbles.local_coords = false
		bubbles.amount = base_amount
		bubble_mat.gravity = Vector3(0, -40, 0)
		bubble_mat.direction = Vector3(0, -1, 0)
		bubble_mat.spread = 45.0
		bubble_mat.initial_velocity_min = 20.0
		bubble_mat.initial_velocity_max = 40.0
# ==============================================
# ==== PHYSICS AND MOVEMENT ====
# ==============================================
func _physics_process(_delta):
	if _is_stunned:
		return
		
	# --- Movement ---
	var input_vector = Input.get_vector("left", "right", "up", "down")
	velocity = input_vector.normalized() * speed
	move_and_slide()

	# --- Aiming (now handled by controller_manager) ---
	if controller_manager:
		diver_arm.look_at(controller_manager.get_aim_position())
	else:
		diver_arm.look_at(get_global_mouse_position())

	# --- Shooting ---
	if Input.is_action_just_pressed("fire") and cooldowntimer.is_stopped():
		fire()

	# --- Animation ---
	var move_input := Input.get_vector("left", "right", "up", "down")
	var is_moving := move_input.length() > 0.0
	
	if is_moving:
		if diver_anim.animation != "playerswim" or diver_anim.is_playing() == false:
			diver_anim.play("playerswim")
		
		if arm_socket:
			var swim_progress = diver_anim.frame / float(diver_anim.sprite_frames.get_frame_count("playerswim"))
			var bob_offset = sin(swim_progress * PI * 2) * 2.0
			arm_socket.position = swim_arm_position + Vector2(0, bob_offset)
	else:
		if diver_anim.animation != "playeridle" or diver_anim.is_playing() == false:
			diver_anim.play("playeridle")
		
		if arm_socket:
			arm_socket.position = idle_arm_position
	
	model_facing()
	
	# --- Bubble Trail ---
	_update_bubble_trail()
	
	# --- Cooldown Progress Bar ---
	if cooldowntimer.time_left > 0:
		cooldownbar.value = cooldowntimer.time_left
	else:
		cooldownbar.value = 100

func model_facing() -> void:
	if diver_anim == null:
		return
	
	# Get aim position from controller handler
	var mouse_pos = get_global_mouse_position()
	if controller_manager:
		mouse_pos = controller_manager.get_aim_position()
	
	var player_pos = global_position
	
	if mouse_pos.x < player_pos.x: 
		diver_anim.flip_h = true 
		diver_arm.flip_v = true
		if arm_socket:
			arm_socket.position.x = -abs(arm_socket.position.x)
	elif mouse_pos.x > player_pos.x: 
		diver_anim.flip_h = false 
		diver_arm.flip_v = false
		if arm_socket:
			arm_socket.position.x = abs(arm_socket.position.x)
# ==============================================
# ==== BUBBLE TRAIL LOGIC ====
# ==============================================
func _update_bubble_trail():
	if bubbles == null or bubble_mat == null:
		return

	var input_vector = Input.get_vector("left", "right", "up", "down")
	var is_moving = input_vector.length() > 0.1
	
	if not is_moving:
		bubbles.emitting = false
		return
	
	bubbles.emitting = true
	
	var move_direction = -input_vector.normalized()
	bubble_mat.direction = Vector3(move_direction.x, move_direction.y, 0.0)
	var current_speed = velocity.length()
	
	bubble_mat.initial_velocity_min = 20.0 + current_speed * 0.02
	bubble_mat.initial_velocity_max = 40.0 + current_speed * 0.05
	
	var bubble_count = int(clamp(base_amount + current_speed * 0.6, base_amount, max_amount))
	bubbles.amount = bubble_count
# ==============================================
# ==== COMBAT: FIRING & MULTISHOT ====
# ==============================================
func fire():
	harpoon.play()
	cooldowntimer.start()
	var fire_pos = diver_arm.global_position
	
	# Get aim position from controller handler
	var target_pos = get_global_mouse_position()
	if controller_manager:
		target_pos = controller_manager.get_aim_position()
	
	var direction = (target_pos - fire_pos).normalized()
	
	if not firerate:
		cooldowntimer.start()
	else:
		cooldowntimer.stop()
	
	if multi_shot:
		var spread = deg_to_rad(10)
		for angle_offset in [-spread, 0, spread]:
			var projectile_instance = projectile.instantiate()
			projectile_instance.global_position = fire_pos
			projectile_instance.rotation = direction.angle() + angle_offset
			projectile_instance.linear_velocity = Vector2.RIGHT.rotated(projectile_instance.rotation) * projectilespeed
			projectile_instance.add_to_group("projectile")
			get_tree().current_scene.add_child(projectile_instance)
	else:
		var projectile_instance = projectile.instantiate()
		projectile_instance.global_position = fire_pos
		projectile_instance.rotation = direction.angle()
		projectile_instance.linear_velocity = direction * projectilespeed
		projectile_instance.add_to_group("projectile")
		get_tree().current_scene.add_child(projectile_instance)
# ==============================================
# ==== PLAYER DAMAGE, HEALING & FLASH ====
# ==============================================
func take_damage(amount: int):
	await flash_hit()
	await get_tree().create_timer(flash_duration).timeout
	cam.apply_shake()

	health -= amount
	update_hearts()
	damage_taken.play()

	if health <= 0:
		if score > Global.high_score:
			Global.high_score = score
		die()


func heal(amount: int = 3):
	health = min(health + amount, max_health)
	update_hearts()

func flash_hit() -> void:
	var original_modulate = diver_anim.modulate
	
	diver_anim.modulate = Color(10, 10, 10, 1)
	
	await get_tree().create_timer(flash_duration).timeout
	
	diver_anim.modulate = original_modulate
# ==============================================
# ==== PLAYER STATUS & STUN ====
# ==============================================
func stun(duration: float) -> void:
	if _is_stunned:
		return
	_is_stunned = true
	velocity = Vector2.ZERO

	if $StunEffect:
		$StunEffect.visible = true
		$StunEffect.play("stun_flash")

	await get_tree().create_timer(duration).timeout

	if $StunEffect:
		$StunEffect.visible = false
		$StunEffect.stop()
	_is_stunned = false

	if diver_anim:
		if Input.get_vector("left", "right", "up", "down").length() > 0:
			diver_anim.play("playerswim")
		else:
			diver_anim.pause()
# ==============================================
# ==== SCORE SYSTEM ====
# ==============================================
func add_score(amount: int = 1) -> void:
	score += amount
	Global.player_score = score
	score_label.text = "Score: %d" % score

	if score % 20 == 0:
		heal(max_health)
		$CanvasLayer/Hearts/Label.visible = true
		await get_tree().create_timer(2).timeout
		$CanvasLayer/Hearts/Label.visible = false
		high_score.play()
# ==============================================
# ==== DEATH & GAMEOVER ====
# ==============================================
func die() -> void:
	score = 0
	Global.player_score = 0
	call_deferred("_gameover")

func _gameover():
	var tree := get_tree()
	if tree == null:
		return

	Fade.transition()
	await Fade.on_transition_finished
	tree.change_scene_to_file("res://scenes/gameover.tscn")
# ==============================================
# ==== HEARTS & MATERIAL UTILITIES ====
# ==============================================
func update_hearts():
	for i in range(max_health):
		hearts[i].visible = (i < health)
# ==============================================
# ==== BOSS UI ====
# ==============================================
func boss_ui_show(boss: Node, display_name: String) -> void:
	if _current_boss and is_instance_valid(_current_boss):
		if _current_boss.has_signal("hp_changed"):
			_current_boss.hp_changed.disconnect(_on_boss_hp_changed)
		if _current_boss.has_signal("died"):
			_current_boss.died.disconnect(_on_boss_died_hide)

	_current_boss = boss
	boss_name.text = display_name
	boss_hud.visible = true

	if boss and boss.has_signal("hp_changed"):
		boss.hp_changed.connect(_on_boss_hp_changed)
	if boss and boss.has_signal("died"):
		boss.died.connect(_on_boss_died_hide)

	if "max_hp" in boss:
		_on_boss_hp_changed(boss.max_hp, boss.max_hp)


func boss_ui_hide() -> void:
	boss_hud.visible = false
	if _current_boss and is_instance_valid(_current_boss):
		if _current_boss.has_signal("hp_changed"):
			_current_boss.hp_changed.disconnect(_on_boss_hp_changed)
		if _current_boss.has_signal("died"):
			_current_boss.died.disconnect(_on_boss_died_hide)
	_current_boss = null

func _on_boss_hp_changed(cur: int, mx: int) -> void:
	if boss_bar:
		boss_bar.max_value = mx
		boss_bar.value = cur

func _on_boss_died_hide() -> void:
	boss_ui_hide()
