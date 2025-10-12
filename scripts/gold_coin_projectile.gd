extends Area2D

@export var speed: float = 200.0
@export var damage: int = 10
@export var homing_strength: float = 2.5
@export var lifetime: float = 5.0

var target: Node2D = null
var velocity: Vector2

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	$AnimatedSprite2D.play("spin") # make sure your animation is named "spin" or change this
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func set_target(player: Node2D):
	target = player
	look_at(player.global_position)
	velocity = (player.global_position - global_position).normalized() * speed

func _physics_process(delta):
	if target and is_instance_valid(target):
		var desired = (target.global_position - global_position).normalized() * speed
		velocity = velocity.lerp(desired, homing_strength * delta)
	
	position += velocity * delta
	
func _spawn_sparkle():
	var sparkle = preload("res://scenes/CoinSparkle.tscn").instantiate()
	sparkle.global_position = global_position
	get_tree().current_scene.add_child(sparkle)
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(1)
	_spawn_sparkle()
	queue_free()
