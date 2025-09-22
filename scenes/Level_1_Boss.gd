extends Node2D
@onready var boss: Node = get_node_or_null("BossSpawn/WhaleBoss")
@onready var bossbar: TextureProgressBar = $BossUI/BossBar
@onready var spawn: Marker2D = $BossSpawn

func _ready() -> void:
	if boss and spawn:
		boss.global_position = spawn.global_position
		
	if boss and bossbar:
		boss.hp_changed.connect(_on_boss_hp_changed)
		_on_boss_hp_changed(boss.max_hp, boss.max_hp)
		
func _on_boss_hp_changed(cur: int, mx: int) -> void:
	bossbar.max_value = mx
	bossbar.value = cur
