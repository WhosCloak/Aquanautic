extends CharacterBody2D

var speed = 250
var projectilespeed = 500
var projectile = load("res://scenes/harpoon.tscn")
var score = Global.player_score
var max_health := 3
var health := max_health

@onready var cam := $Camera2D
@onready var muzzle = $Muzzle
@onready var score_label = $CanvasLayer/Score/Label
@onready var hearts := [
	$CanvasLayer/Hearts/Heart1,
	$CanvasLayer/Hearts/Heart2,
	$CanvasLayer/Hearts/Heart3
]

func _ready():
	cam.zoom = Vector2(3.5, 3.5)
	update_hearts()
	cam.set_process(true)

func _physics_process(_delta):
	var input_vector = Input.get_vector("left", "right", "up", "down")
	velocity = input_vector.normalized() * speed
	move_and_slide()
	$AnimatedSprite2D.play("playerswim")
	look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("fire"):
		fire()

func fire():
	var projectile_instance = projectile.instantiate()
	var fire_pos = muzzle.global_position
	var direction = (get_global_mouse_position() - fire_pos).normalized()
	
	projectile_instance.global_position = fire_pos
	projectile_instance.rotation = direction.angle()
	projectile_instance.linear_velocity = direction * projectilespeed

	get_tree().current_scene.add_child(projectile_instance)
	$Harpoon.play()

func add_score(amount: int = 1) -> void:
	score += amount
	Global.player_score = score
	score_label.text = "Score: %d" % score
	if score % 20 == 0:
		heal(max_health)
		$CanvasLayer/Hearts/Label.visible = true
		await get_tree().create_timer(2).timeout
		$CanvasLayer/Hearts/Label.visible = false

func take_damage(amount: int):
	health -= amount
	update_hearts()

	if health <= 0:
		if score > Global.high_score:
			Global.high_score = score
		die()
		
func heal(amount: int):
	health = min(health + amount, max_health)
	update_hearts()


func die() -> void:
	call_deferred("_gameover")

func _gameover():
	Fade.transition()
	await Fade.on_transition_finished
	get_tree().change_scene_to_file("res://scenes/gameover.tscn")
	

func update_hearts():
	for i in range(max_health):
		hearts[i].visible = (i < health)
		
