extends Node2D
signal died
signal hp_changed(current: int, maximum: int)

@export var max_hp := 90
@export var contact_damage := 1

var hp := 0
var _hit_lock := false

@onready var hurtbox: Area2D = $Hurtbox

func _ready() -> void:
	add_to_group("boss")
	hp = max_hp
	if hurtbox:
		hurtbox.monitoring = true
		hurtbox.area_entered.connect(_on_hurt_area_entered)
		hurtbox.body_entered.connect(_on_hurt_area_entered)
	else:
		push_warning("WhaleBoss, Hurtbox not found")
	emit_signal("hp_changed", hp, max_hp)

func _on_hurt_area_entered(b: Node) -> void:
	if _hit_lock:
		return
	if b.is_in_group("projectile"):
		b.queue_free()
		apply_damage(contact_damage)
		
func apply_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	emit_signal("hp_changed", hp, max_hp)
	if hp == 0:
		_die()
	else:
		_hit_lock = true
		await get_tree().create_timer(0.05).timeout
		_hit_lock = false
		
func _die() -> void:
	emit_signal("died")
	queue_free()
