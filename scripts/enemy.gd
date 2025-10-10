extends CharacterBody2D
class_name EnemyBase

@export var speed: float = 100.0
@export var damage: int = 1
@export var score_value: int = 1

var player: Node2D
var _is_dying: bool = false
var flip_threshold: float = 1.0
var flash_duration := 0.1

@onready var art: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hurtbox: Area2D = $Area2D
@onready var _death_sound: AudioStreamPlayer2D = $Death
var fallback_sound := preload("res://audios/enemydeath.wav")

func _ready():
	player = get_tree().get_first_node_in_group("player")
	_duplicate_materials_recursive(self)
	

func _physics_process(_delta: float) -> void:
	if player and not _is_dying:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		_update_art_facing()

func _update_art_facing() -> void:
	if not art:
		return
	if abs(velocity.x) > flip_threshold:
		art.flip_h = velocity.x > 0.0
	art.rotation = 0.0

func take_damage(_amount: int = 1) -> void:
	await flash_hit()
	await get_tree().create_timer(flash_duration).timeout
	die()

func flash_hit() -> void:
	var affected_nodes = _get_flashable_nodes(self)
	for node in affected_nodes:
		var mat: ShaderMaterial =  node.material
		if mat and mat is ShaderMaterial:
			mat.set_shader_parameter("flash_strength", 1.0)

	await get_tree().create_timer(0.1).timeout

	for node in affected_nodes:
		var mat: ShaderMaterial =  node.material
		if mat and mat is ShaderMaterial:
			mat.set_shader_parameter("flash_strength", 0.0)

func _get_flashable_nodes(root: Node) -> Array:
	var nodes := []
	for child in root.get_children():
		if child is CanvasItem and child.material and child.material is ShaderMaterial:
			nodes.append(child)
		nodes += _get_flashable_nodes(child) # recursive
	return nodes

func _duplicate_materials_recursive(root: Node) -> void:
	for child in root.get_children():
		if child is CanvasItem and child.material and child.material is ShaderMaterial:
			child.material = child.material.duplicate()
		_duplicate_materials_recursive(child)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if _is_dying:
		return
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			await flash_hit()
			await get_tree().create_timer(flash_duration).timeout
			die()

func die():
	if _is_dying:
		return
	_is_dying = true

	if is_instance_valid(_hurtbox):
		_hurtbox.set_deferred("monitoring", false)

	if player and player.has_method("add_score"):
		player.add_score(score_value)

	_play_death_sound()
	queue_free()

func _play_death_sound():
	var sound_player := AudioStreamPlayer2D.new()
	var stream: AudioStream = _death_sound.stream if _death_sound and _death_sound.stream else fallback_sound

	if stream:
		sound_player.stream = stream
		sound_player.global_position = global_position
		get_tree().current_scene.add_child(sound_player)
		sound_player.play()
		sound_player.finished.connect(func(): sound_player.queue_free())
