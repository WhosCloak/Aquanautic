extends CharacterBody2D

var speed = 500
var laserspeed = 2000
var laser = load("res://scenes/laser.tscn")
var score = 0

@onready var cam := $Camera2D
@onready var muzzle = $Muzzle

func _ready():
	cam.zoom = Vector2(2, 2)
	cam.set_process(true)

func _physics_process(_delta):
	var input_vector = Input.get_vector("left", "right", "up", "down")
	velocity = input_vector.normalized() * speed
	move_and_slide()
	
	look_at(get_global_mouse_position())

	if Input.is_action_just_pressed("fire"):
		fire()

func fire():
	var laser_instance = laser.instantiate()

	var fire_pos = muzzle.global_position
	var direction = (get_global_mouse_position() - fire_pos).normalized()

	laser_instance.global_position = fire_pos
	laser_instance.rotation = direction.angle()
	laser_instance.linear_velocity = direction * laserspeed

	get_tree().current_scene.add_child(laser_instance)
	

func add_score(amount: int = 1) -> void:
	score += amount
	$CanvasLayer/Control/Label.text = "Score: %d" % score

func get_score() -> int:
	return score
