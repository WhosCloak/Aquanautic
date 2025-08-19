extends RigidBody2D


var speed = 2000

func _ready():
	connect("area_entered", Callable(self,"_on_area_entered"))
	
func _physics_process(delta):
	global_position += Vector2(speed * delta, 0).rotated(rotation)
	
func _on_area_entered(area):
	if area.is_in_group("enemy"):
		area.queue_free()
		queue_free()
