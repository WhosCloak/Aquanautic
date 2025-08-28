extends CharacterBody2D

var speed = 250
var projectilespeed = 500
var projectile = load("res://scenes/harpoon.tscn")
var score = 0

@onready var cam := $Camera2D
@onready var muzzle = $Muzzle

func _ready():
	cam.zoom = Vector2(3.5, 3.5)
	cam.set_process(true)

func _physics_process(_delta):
	var input_vector = Input.get_vector("left", "right", "up", "down")
	velocity = input_vector.normalized() * speed
	move_and_slide()
	
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
	

func add_score(amount: int = 1) -> void:
	score += amount
	$CanvasLayer/Control/Label.text = "Score: %d" % score

func get_score() -> int:
	return score
