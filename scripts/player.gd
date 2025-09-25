extends CharacterBody2D
# Player controller, movement, shooting, HUD updates, bubble trail, death flow.

#Variables
var speed = 250   # Move speed in pixles per second
var projectilespeed = 500  #harpoon speed
var projectile = load("res://scenes/harpoon.tscn") # packed scene for the harpoon

var score = Global.player_score  # Score is mirrored to a global for persistance
var max_health := 3
var health := max_health

# Audio assets
var harpoonsound = preload("res://audios/harpoon_shot.mp3")
var highscore = preload("res://audios/high-score.mp3")
var hittaken = preload("res://audios/player_damage_taken.wav")
# Bubble trail particles, configured at runtime
var bubble_mat: ParticleProcessMaterial # cached process material 
var emit_speed := 10.0 # minimum movement speed before emitting 
var base_amount := 80  # baseline particle amount 
var max_amount := 180 # clamp to avoid spikes

#Reading assests
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

#Basic Movement and animation
func _physics_process(_delta):
	# Read movements input and move
	var input_vector = Input.get_vector("left", "right", "up", "down")
	velocity = input_vector.normalized() * speed
	move_and_slide()
	# Face the mouse when aiming 
	look_at(get_global_mouse_position())
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
	$Harpoon.play() # uses the AudioStreamPlayer node in the scene
	var projectile_instance = projectile.instantiate()
	var fire_pos = muzzle.global_position
	var direction = (get_global_mouse_position() - fire_pos).normalized()
	
	# Position and launch the harpoon
	projectile_instance.global_position = fire_pos
	projectile_instance.rotation = direction.angle()
	projectile_instance.linear_velocity = direction * projectilespeed
	
	# Tag so enemies and bosses can identify hits
	projectile_instance.add_to_group("projectile")

# Add to the activate scene
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
