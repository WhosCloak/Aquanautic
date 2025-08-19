extends CharacterBody2D

var speed = 500
var laserspeed = 2000
var laser = preload("res://scenes/Laser.tscn")

func _physics_process(_delta):
	var input_vector = Input.get_vector("left", "right", "up", "down")
	velocity = input_vector.normalized() * speed
	move_and_slide()
	look_at(get_global_mouse_position())

	if Input.is_action_just_pressed("fire"):
		fire()

func fire():
	var laser_instance = laser.instantiate()
	laser_instance.global_position = global_position

	var direction = (get_global_mouse_position() - global_position).normalized()
	laser_instance.rotation = direction.angle()
	laser_instance.linear_velocity = direction * laserspeed

	get_tree().current_scene.add_child(laser_instance)
	
func _on_body_entered(body):
	if body.is_in_group("enemy"):
		get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
