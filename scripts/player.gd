extends CharacterBody2D

#Variables
var speed = 250
var projectilespeed = 500
var projectile = load("res://scenes/harpoon.tscn")
var score = Global.player_score
var max_health := 3
var health := max_health
var harpoonsound = preload("res://audios/harpoon_shot.mp3")
var highscore = preload("res://audios/high-score.mp3")
var hittaken = preload("res://audios/player_damage_taken.wav")
var bubble_mat: ParticleProcessMaterial
var emit_speed := 10.0
var base_amount := 80 
var max_amount := 180

#Reading assests
@onready var cam := $Camera2D
@onready var muzzle = $Muzzle
@onready var score_label = $CanvasLayer/Score/Label
@onready var bubbles: GPUParticles2D = $BubbleTrail
@onready var hearts := [
	$CanvasLayer/Hearts/Heart1,
	$CanvasLayer/Hearts/Heart2,
	$CanvasLayer/Hearts/Heart3
]

#Camera Zoom
func _ready():
	cam.zoom = Vector2(3.5, 3.5)
	update_hearts()
	cam.set_process(true)

#Basic Movement and animation
func _physics_process(_delta):
	var input_vector = Input.get_vector("left", "right", "up", "down")
	velocity = input_vector.normalized() * speed
	move_and_slide()
	look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("fire"):
		fire()
	if input_vector:
		$AnimatedSprite2D.play("playerswim")
	else:
		$AnimatedSprite2D.pause()
	
	#Bubble trail
	if bubbles == null or bubble_mat == null:
		return 
	var input_len := Input.get_vector("left","right","up","down").length()
	var spd := velocity.length()
	var moving := spd > emit_speed and input_len > 0.0
	
	if not moving:
		bubbles.emitting = false
		bubbles.amount = 0
		return
	
	bubbles.emitting = moving
	if moving:
		var dir := Vector2.ZERO
		if spd > 0.0:
			dir = -velocity.normalized()
		bubble_mat.direction = Vector3(dir.x, dir.y, 0.0)

		bubble_mat.initial_velocity_min = 20.0 + spd * 0.02
		bubble_mat.initial_velocity_max = 40.0 + spd * 0.05
		bubbles.amount = int(clamp(base_amount + spd * 0.6, base_amount, max_amount))


func _enter_tree() -> void:
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
	
# Firing Harpoon
func fire():
	$Harpoon.play()
	var projectile_instance = projectile.instantiate()
	var fire_pos = muzzle.global_position
	var direction = (get_global_mouse_position() - fire_pos).normalized()
	
	projectile_instance.global_position = fire_pos
	projectile_instance.rotation = direction.angle()
	projectile_instance.linear_velocity = direction * projectilespeed
	
	projectile_instance.add_to_group("projectile")

	get_tree().current_scene.add_child(projectile_instance)


#Enumerate Score
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

# Take damage
func take_damage(amount: int):
	health -= amount
	update_hearts()
	$DamageTaken.play()

	if health <= 0:
		if score > Global.high_score:
			Global.high_score = score
		die()
		

#Heal HP
func heal(amount: int):
	health = min(health + amount, max_health)
	update_hearts()

func update_hearts():
	for i in range(max_health):
		hearts[i].visible = (i < health)

#Player death
func die() -> void:
	call_deferred("_gameover")

func _gameover():
	var tree:= get_tree()
	if tree == null:
		return
	Fade.transition()
	await Fade.on_transition_finished
	
	tree.change_scene_to_file("res://scenes/gameover.tscn")
