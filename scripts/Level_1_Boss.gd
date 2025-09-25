extends Node2D

var bossbar: ProgressBar = null
var boss: Node = null

func _ready() -> void:
	var bars := get_tree().get_nodes_in_group("boss_bar")
	print("[BossLevel] boss_bar group count:", bars.size())
	for n in bars:
		print(" candidate:", n.get_path(), " type:", n.get_class())
		
	for n in bars:
		if n is Range and n is Control:
			bossbar = n as Range
			break
	
	if bossbar == null and has_node("BossUI/BossBar"):
		bossbar = get_node("BossUI/BossBar") as Range
		
	if bossbar:
		bossbar.max_value = 100
		bossbar.value = 100
		if bossbar is Control:
			var c := bossbar as Control
			c.set_anchors_preset(Control.PRESET_TOP_WIDE)
			c.visible = true
			print("[BossLevel] bar rect:", c.get_global_rect())
		else:
			push_warning("[BossLevel] BossBar not found. Keep the group only on the real bar.")
			
		boss = get_tree().get_first_node_in_group("boss")
		print("[BossLevel] boss found:", boss)
		if boss and boss.has_signal("hp_changed"):
			boss.hp_changed.connect(_on_boss_hp_changed)
			print("[BossLevel] connected hp_changed")
			if "max_hp" in boss:
				_on_boss_hp_changed(boss.max_hp, boss.max_hp)
				
func _on_boss_hp_changed(cur: int, mx: int) -> void:
	if bossbar:
		bossbar.max_value = mx
		bossbar.value = cur
		
