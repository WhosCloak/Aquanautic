extends Node2D

@onready var bossbar: ProgressBar = $BossUI/UIFrame/BossBar
var boss: Node = null

func _ready() -> void:
	boss = find_child("WhaleBoss", true, false)
	
	if boss and boss.has_signal("hp_changed"):
		boss.hp_changed.connect(_on_boss_hp_changed)
		_on_boss_hp_changed(boss.max_hp, boss.max_hp)
	else:
		bossbar.max_value = 100
		bossbar.value = 100
		
	bossbar.visible = true 

func _on_boss_hp_changed(cur: int, mx: int) -> void:
	bossbar.max_value = mx
	bossbar.value = cur
