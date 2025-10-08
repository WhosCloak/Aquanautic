extends CharacterBody2D
# Player controller, movement, shooting, HUD updates, bubble trail, death flow.

#Variables
var speed := 250   # Move speed in pixles per second
var projectilespeed := 500  #harpoon speed
var projectile = load("res://scenes/harpoon.tscn") # packed scene for the harpoon
var score = Global.player_score  # Score is mirrored to a global for persistance
var max_health := 3
var health := max_health
var multi_shot := false


# Audio assets
var harpoonsound = preload("res://audios/harpoon_shot.mp3")
var highscore = preload("res://audios/high-score.mp3")
var hittaken = preload("res://audios/player_damage_taken.wav")
# Bubble trail particles, configured at runtime
var bubble_mat: ParticleProcessMaterial # cached process material 
var emit_speed := 10.0 # minimum movement speed before emitting 
var base_amount := 80  # baseline particle amount 
var max_amount := 180 # clamp to avoid spikes

var  _current_boss: Node = null

#Reading assests
@onready var boss_hud: Control = $CanvasLayer/BossHUD
@onready var boss_name: Label = $CanvasLayer/BossHUD/HBoxContainer/BossName
@onready var boss_bar: Range = $CanvasLayer/BossHUD/HBoxContainer/BossBar
@onready var cam := $Camera2D # gameplay camera
@onready var muzzle = $Muzzle # spawn point for harpoons
@onready var score_label = $CanvasLayer/Score/Label
@onready var bubbles: GPUParticles2D = $BubbleTrail
@onready var hearts := [   #heart sprites in the HUD
	$CanvasLayer/Hearts/Heart1,
	$CanvasLayer/Hearts/Heart2,
	$CanvasLayer/Hearts/Heart3
]

#Camera Zoom/lifecycle 
func _ready():
	# Set inital camera zoom, refresh hearts, allow camera processing 
	cam.zoom = Vector2(3.5, 3.5)
	update_hearts()
	cam.set_process(true)
	if boss_hud:
		boss_hud.visible = false

#Basic Movement and animation
func _physics_process(_delta):
	# Read movements input and move
	var input_vector = Input.get_vector("left", "right", "up", "down")
	velocity = input_vector.normalized() * speed
	move_and_slide()
	# Face the mouse when aiming 
	muzzle.look_at(get_global_mouse_position())
	# Fire on click mapped to "fire"
	if Input.is_action_just_pressed("fire"):
		fire()
	# Swim animation while moving, pause when idle 
	if input_vector:
		$AnimatedSprite2D.play("playerswim")
	else:
		$AnimatedSprite2D.pause()
	
	#Bubble trail, depends on current velocity and input 
	if bubbles == null or bubble_mat == null:
		return 
	var input_len := Input.get_vector("left","right","up","down").length()
	var spd := velocity.length()
	var moving := spd > emit_speed and input_len > 0.0
	
	if not moving:
		# stop emission and clear any pending particles
		bubbles.emitting = false
		bubbles.amount = 0
		return
	# Emit, set direction opposite to movement, push velocity based params
	bubbles.emitting = moving
	if moving:
		var dir := Vector2.ZERO
		if spd > 0.0:
			dir = -velocity.normalized()
		# GPUParticls2D expects a Vector3 for direction 
		bubble_mat.direction = Vector3(dir.x, dir.y, 0.0)

		bubble_mat.initial_velocity_min = 20.0 + spd * 0.02
		bubble_mat.initial_velocity_max = 40.0 + spd * 0.05
		bubbles.amount = int(clamp(base_amount + spd * 0.6, base_amount, max_amount))

# Bubble trial set up
func _enter_tree() -> void:
	# Ensure the particles have a usuable process material
	if bubbles == null:
		return 
	if bubbles.process_material and bubbles.process_material is ParticleProcessMaterial:
		bubble_mat = bubbles.process_material
	else:
		bubble_mat = ParticleProcessMaterial.new()
		bubbles.process_material = bubble_mat
	# Default emission off, draw in world space
	bubbles.emitting = false
	bubbles.local_coords = false
	# Emit immediately when turned on, no warm up
	bubbles.preprocess = 0.0
	# Light upward drift, like buoyant bubbles
	bubble_mat.gravity = Vector3(0, -40, 0)
	bubble_mat.direction = Vector3(0, -1, 0)
	
# Firing Harpoon
func fire():
	$Harpoon.play()
	var fire_pos = muzzle.global_position
	var direction = (get_global_mouse_position() - fire_pos).normalized()
	
	if multi_shot:
		# Fire 3 harpoons spread slightly apart
		var spread = deg_to_rad(10)  # spread angle
		for angle_offset in [-spread, 0, spread]:
			var projectile_instance = projectile.instantiate()
			projectile_instance.global_position = fire_pos
			projectile_instance.rotation = direction.angle() + angle_offset
			projectile_instance.linear_velocity = Vector2.RIGHT.rotated(projectile_instance.rotation) * projectilespeed
			projectile_instance.add_to_group("projectile")
			get_tree().current_scene.add_child(projectile_instance)
	else:
		# Single harpoon
		var projectile_instance = projectile.instantiate()
		projectile_instance.global_position = fire_pos
		projectile_instance.rotation = direction.angle()
		projectile_instance.linear_velocity = direction * projectilespeed
		projectile_instance.add_to_group("projectile")
		get_tree().current_scene.add_child(projectile_instance)

	
#Enumerate Score
func add_score(amount: int = 1) -> void:
	# Increment local and global, update label
	score += amount
	Global.player_score = score
	score_label.text = "Score: %d" % score
	
	# Reward every 20, heal to full and show a small message
	if score % 20 == 0:
		heal(max_health)
		$CanvasLayer/Hearts/Label.visible = true
		await get_tree().create_timer(2).timeout
		$CanvasLayer/Hearts/Label.visible = false
		$HighScore.play()

# Health,damage,healing
func take_damage(amount: int):
	# Reduce health, refresh hearts, play hit sound
	health -= amount
	update_hearts()
	$DamageTaken.play()
# Death check, record high score, then die
	if health <= 0:
		if score > Global.high_score:
			Global.high_score = score
		die()
		
#Heal HP
func heal(amount: int):
	# Clamp heal to max and refresh hearts
	health = min(health + amount, max_health)
	update_hearts()

func update_hearts():
	# Toggle heart sprites based on current health
	for i in range(max_health):
		hearts[i].visible = (i < health)

#Player death/gameover
func die() -> void:
# Reset local and global score to 0 on death
	score = 0
	Global.player_score = 0
	#Global.reset()
	# Defer to avoid changing scenes mid signal
	call_deferred("_gameover")

func _gameover():
	# Guard against rare cases where the tree is not ready
	var tree:= get_tree()
	if tree == null:
		return
	# Fade out, then go to the game over scene
	Fade.transition()
	await Fade.on_transition_finished
	tree.change_scene_to_file("res://scenes/gameover.tscn")
	
func boss_ui_show(boss: Node, display_name: String) -> void:
	print("[Player] boss_ui_show, name:", display_name)
	# disconnect old boss, if any
	if _current_boss and is_instance_valid(_current_boss):
		if _current_boss.has_signal("hp_changed"):
			_current_boss.hp_changed.disconnect(_on_boss_hp_changed)
		if _current_boss.has_signal("died"):
			_current_boss.died.disconnect(_on_boss_died_hide)

	_current_boss = boss

	# set name and show HUD
	boss_name.text = display_name
	boss_hud.visible = true

	# connect signals to drive the bar
	if boss and boss.has_signal("hp_changed"):
		boss.hp_changed.connect(_on_boss_hp_changed)
	if boss and boss.has_signal("died"):
		boss.died.connect(_on_boss_died_hide)

	# initialize the bar
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
	


func _on_power_up() -> void:
	if multi_shot == true:
		pass
