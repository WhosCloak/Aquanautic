extends CharacterBody2D

#Variables
var speed = 150
var player = Node2D
@onready var _death_sound: AudioStreamPlayer2D = $Death
var fallback_sound := preload("res://audios/enemydeath.wav")
@onready var art:AnimatedSprite2D = $AnimatedSprite2D
@onready var shield_sprite: AnimatedSprite2D = $ShieldSprite
var flip_threshold := 1.0
var shield_active := true
var flash_duration := 0.1

#Model Flip
func _update_art_facing() -> void:
	if art == null:
		return 
	if abs(velocity.x) > flip_threshold:
		art.flip_h = velocity.x > 0.0
	art.rotation = 0.0

#Find Player
func _ready():
	player = get_tree().get_first_node_in_group("player")
	shield_sprite.play("shield_activate")
	if art.material and art.material is ShaderMaterial:
		art.material = art.material.duplicate()
		art.material.set_shader_parameter("flash_strength", 0.0)

func _physics_process(_delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		_update_art_facing()

#Player Damage
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		die()

func take_damage():
	if shield_active:
		shield_active = false
		shield_sprite.visible = false
	else:
		flash_hit()
		await get_tree().create_timer(flash_duration).timeout
		die()

func flash_hit():
	var mat := art.material
	if mat and mat is ShaderMaterial:
		mat.set_shader_parameter("flash_strength", 1.0)
		await get_tree().create_timer(0.1).timeout
		mat.set_shader_parameter("flash_strength", 0.0)
		
#Enemy Death
func die():
	if player and player.has_method("add_score"):
		player.add_score()
	call_deferred("queue_free")
	_play_death_sound()
	
func _play_death_sound():
	var sound_player := AudioStreamPlayer2D.new()
	var stream: AudioStream = _death_sound.stream if _death_sound and _death_sound.stream else fallback_sound

	if stream:
		sound_player.stream = stream
		sound_player.global_position = global_position
		get_tree().current_scene.add_child(sound_player)
		sound_player.play()
		sound_player.finished.connect(func(): sound_player.queue_free())
