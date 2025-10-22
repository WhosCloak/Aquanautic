extends Node2D
# Whale boss root script. Handles Hp, taking damage, patrol movement, and UI signals
signal died    # Emitted once when HP reaches zero, Main listens to advance level
signal hp_changed(current: int, maximum: int) # Emitted on init and every time HP changes for the UI bar

# Boss tuning , editable in the Inspector 
@export var max_hp := 90 # Total health for this boss
@export var contact_damage := 1 # Damage applied per projectile hit via the Hurtbox
@export var swim_speed := 60.0 # Units per second while patrolling
@export var arrive_dist := 8.0 # Distance threshold to consider a waypoint reached
@export var path_a_path: NodePath #Drag PAthA Marker2D here in the Inspector
@export var path_b_path: NodePath # Drag PathB Marker2D here in the Inspector
@export var faces_right_default := false # True if the base sprite faces right by default
@export var display_name := "Wrath of the Deep" #here ur able to change the name of the boss
@onready var harpoon_shot: AudioStreamPlayer2D = $AttackTimer/harpoon_shot
@onready var barnacle_drop_audio: AudioStreamPlayer2D = $BarnacleTimer/barnacle_drop_audio


# Internal state
var hp := 0       # Current health, initialized in _ready
var _hit_lock := false # Short lockout to avoid double hits in one frame
#barnacle preload scene 
var barnacle_scene = preload("res://scenes/BossLevels/barnacle.tscn")
@onready var barnacle_drop = $BarnacleDrop


var boss_harpoon_scene = preload("res://scenes/BossLevels/boss_harpoon.tscn")
@onready var harpoon_muzzle = $HarpoonMuzzle

# Cached node refrences 
@onready var hurtbox: Area2D = $Hurtbox      # Area2D that receives projectile overlaps
@onready var anim:AnimatedSprite2D = $AnimatedSprite2D  # Aniomated art for the whale
@onready var path_a: Marker2D = get_node_or_null(path_a_path) # Resolved PathA marker 
@onready var path_b: Marker2D = get_node_or_null(path_b_path) # Resolved PathB marker
@onready var attack_timer: Timer = $AttackTimer
# Patrol target bookkeeping
var _target_marker: Marker2D = null # Which marker we are currently headed toward
var _target: Vector2    # The world position we are moving toward

func _ready() -> void:
	add_to_group("boss")  # Lets the level script find this boss by group
	hp = max_hp    # Start at full health
	
	# Starts the swimn animation if the node sxists and has frames
	if anim:
		anim.play()
		
	if anim:
		anim.animation_finished.connect(_on_anim_finished)
		
	# Hook damage events from the Hurtbox to our handler
	if hurtbox:
		hurtbox.monitoring = true
		hurtbox.area_entered.connect(_on_hurt_area_entered)
		hurtbox.body_entered.connect(_on_hurt_area_entered)
	else:
		push_warning("WhaleBoss, Hurtbox not found")
		
	# Pick the initial patrol target based on which marker is farther
	if path_a and path_b:
		var da := global_position.distance_to(path_a.global_position)
		var db := global_position.distance_to(path_b.global_position)
		_target_marker = path_b if db < da else path_a
		_target = _target_marker.global_position
	else:
		# Falback if markers are missing, drift to the right 
		_target_marker = null
		_target = global_position + Vector2(200, 0)
	#Initialize the UI bar
	emit_signal("hp_changed", hp, max_hp)

func _on_anim_finished():
	if anim.animation == "spit":
		anim.play("swim")

func _physics_process(delta: float) -> void:
	# Skip motion during the brief damage lock, keeps movement and hits from figthing 
	if _hit_lock:
		return
	# Move toward the current target
	var to_t := _target - global_position
	if to_t.length() > arrive_dist:
		var step := to_t.normalized() * swim_speed * delta
		global_position += step
		# Flip art so the whale faces the swim direction, with a switch for default facing 
		if anim:
			var moving_left := step.x < 0.0
			anim.flip_h = moving_left if faces_right_default else not moving_left
	else:
		# At target, switch to the other marker, or pick a simple fallback
		if path_a and path_b and _target_marker != null:
			_target_marker = path_a if _target_marker == path_b else path_b
			_target = _target_marker.global_position
		else:
			_target = global_position + Vector2(-_target.x, 0)

func _on_hurt_area_entered(b: Node) -> void:
	# Only process hits if not locked, and only from projectiles
	if _hit_lock:
		return
	if b.is_in_group("projectile"):
		b.queue_free() #Consume the harpoon on hit
		apply_damage(contact_damage) # Apply damage and update UI
		
func apply_damage(amount: int) -> void:
	# Subtract HP, clamp at zero, and inform the UI
	hp = max(0, hp - amount)
	emit_signal("hp_changed", hp, max_hp)
	if hp == 0:
		_die()
	else:
		# Brief invulnerability to prevent multi hit in the same frame
		_hit_lock = true
		await get_tree().create_timer(0.05).timeout
		_hit_lock = false
		
func shoot_harpoon(target_pos: Vector2):
	if anim:
		anim.play("spit")
	var harpoon = boss_harpoon_scene.instantiate()
	harpoon.global_position = harpoon_muzzle.global_position
	var direction = (target_pos - harpoon.global_position).normalized()
	harpoon.rotation = direction.angle() 
	harpoon.linear_velocity = direction * 200 #adjust speed 
	get_tree().current_scene.add_child(harpoon)
	# harpoon sound
	if harpoon_shot:
		harpoon_shot.play()
func _on_attack_timer_timeout():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		shoot_harpoon(player.global_position)

func drop_barnacle():
	var barnacle = barnacle_scene.instantiate()
	barnacle.global_position = barnacle_drop.global_position
	get_tree().current_scene.add_child(barnacle)

	if barnacle_drop_audio:
		barnacle_drop_audio.play()

func _on_barnacle_timer_timeout() -> void:
	drop_barnacle()

func _die() -> void:
	# Tell listeners the boss is dead, then remove this node
	emit_signal("died")
	queue_free()
