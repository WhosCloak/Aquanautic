extends CharacterBody2D
# ==============================================
# PLAYER CONTROLLER SCRIPT
# Handles movement, shooting, HUD updates, bubble trail,
# boss UI, damage, healing, and game-over logic.
# ==============================================


# ===== MOVEMENT & STATS =====
var speed := 250                      # Move speed in pixels per second
var projectilespeed := 500            # Harpoon speed
var projectile = load("res://scenes/harpoon.tscn") # Packed harpoon scene
var score = Global.player_score       # Local mirror of global score
var max_health := 3
var health := max_health
var multi_shot := false
var _is_stunned: bool = false
var flash_duration := 0.1


# ===== AUDIO =====
var harpoonsound = preload("res://audios/harpoon_shot.mp3")
var highscore = preload("res://audios/high-score.mp3")
var hittaken = preload("res://audios/player_damage_taken.wav")


# ===== BUBBLE TRAIL CONFIG =====
var bubble_mat: ParticleProcessMaterial
var emit_speed := 10.0
var base_amount := 80
var max_amount := 180


# ===== INTERNAL REFERENCES =====
var _current_boss: Node = null


# ===== NODE REFERENCES =====
@onready var boss_hud: Control = $CanvasLayer/BossHUD
@onready var boss_name: Label = $CanvasLayer/BossHUD/HBoxContainer/BossName
@onready var boss_bar: Range = $CanvasLayer/BossHUD/HBoxContainer/BossBar
@onready var cam := $Camera2D
@onready var gun = $gun
@onready var score_label = $CanvasLayer/Score/Label
@onready var bubbles: GPUParticles2D = $BubbleTrail
@onready var hearts := [
	$CanvasLayer/Hearts/Heart1,
	$CanvasLayer/Hearts/Heart2,
	$CanvasLayer/Hearts/Heart3
]


# ==============================================
# ==== LIFECYCLE & INITIALIZATION ====
# ==============================================

func _ready():
	# Initial camera setup
	cam.zoom = Vector2(3.5, 3.5)
	update_hearts()
	cam.set_process(true)

	# Duplicate shader materials (for hit flash)
	_duplicate_materials_recursive(self)

	# Hide boss HUD at start
	if boss_hud:
		boss_hud.visible = false


func _enter_tree() -> void:
	# Prepare the bubble trail material and settings
	if bubbles == null:
		return 
	if bubbles.process_material and bubbles.process_material is ParticleProcessMaterial:
		bubble_mat = bubbles.process_material
	else:
		bubble_mat = ParticleProcessMaterial.new()
		bubbles.process_material = bubble_mat

	bubbles.emitting = false
	bubbles.local_coords = false
	bubbles.preprocess = 0.0
	bubble_mat.gravity = Vector3(0, -40, 0)
	bubble_mat.direction = Vector3(0, -1, 0)


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

	# --- Aiming ---
	gun.look_at(get_global_mouse_position())

	# --- Shooting ---
	if Input.is_action_just_pressed("fire"):
		fire()

	# --- Animation ---
	if input_vector:
		$AnimatedSprite2D.play("playerswim")
	else:
		$AnimatedSprite2D.pause()

	# --- Bubble Trail ---
	_update_bubble_trail()


# ==============================================
# ==== BUBBLE TRAIL LOGIC ====
# ==============================================

func _update_bubble_trail():
	if bubbles == null or bubble_mat == null:
		return

	var input_len := Input.get_vector("left", "right", "up", "down").length()
	var spd := velocity.length()
	var moving := spd > emit_speed and input_len > 0.0

	if not moving:
		bubbles.emitting = false
		bubbles.amount = 0
		return

	bubbles.emitting = true
	var dir := Vector2.ZERO
	if spd > 0.0:
		dir = -velocity.normalized()

	bubble_mat.direction = Vector3(dir.x, dir.y, 0.0)
	bubble_mat.initial_velocity_min = 20.0 + spd * 0.02
	bubble_mat.initial_velocity_max = 40.0 + spd * 0.05
	bubbles.amount = int(clamp(base_amount + spd * 0.6, base_amount, max_amount))


# ==============================================
# ==== COMBAT: FIRING & MULTISHOT ====
# ==============================================

func fire():
	$Harpoon.play()
	var fire_pos = gun.global_position
	var direction = (get_global_mouse_position() - fire_pos).normalized()

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
	$DamageTaken.play()

	if health <= 0:
		if score > Global.high_score:
			Global.high_score = score
		die()


func heal(amount: int):
	health = min(health + amount, max_health)
	update_hearts()


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


# ==============================================
# ==== PLAYER STATUS & STUN ====
# ==============================================

func stun(duration: float) -> void:
	if _is_stunned:
		return
	_is_stunned = true
	velocity = Vector2.ZERO
	print("Player stunned!")

	if $StunEffect:
		$StunEffect.visible = true
		$StunEffect.play("stun_flash")

	await get_tree().create_timer(duration).timeout

	if $StunEffect:
		$StunEffect.visible = false
		$StunEffect.stop()

	_is_stunned = false
	print("Player recovered")

	if $AnimatedSprite2D:
		if Input.get_vector("left", "right", "up", "down").length() > 0:
			$AnimatedSprite2D.play("playerswim")
		else:
			$AnimatedSprite2D.pause()


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
		$HighScore.play()


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


func _get_flashable_nodes(root: Node) -> Array:
	var nodes := []
	for child in root.get_children():
		if child is CanvasItem and child.material and child.material is ShaderMaterial:
			nodes.append(child)
		nodes += _get_flashable_nodes(child)
	return nodes


func _duplicate_materials_recursive(root: Node) -> void:
	for child in root.get_children():
		if child is CanvasItem and child.material and child.material is ShaderMaterial:
			child.material = child.material.duplicate()
		_duplicate_materials_recursive(child)


# ==============================================
# ==== BOSS UI ====
# ==============================================

func boss_ui_show(boss: Node, display_name: String) -> void:
	print("[Player] boss_ui_show, name:", display_name)

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
