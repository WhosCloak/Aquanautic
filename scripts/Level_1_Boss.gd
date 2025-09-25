extends Node2D

# Refrence to the boss health UI bar, found at runtime
var bossbar: ProgressBar = null
# Refrence to the boss instance in the scene, found at runtime
var boss: Node = null

func _ready() -> void:
	# Find all nodes that are tagged with group "boss_bar"
	# Only the actual bar node should be in this group 
	var bars := get_tree().get_nodes_in_group("boss_bar")
	print("[BossLevel] boss_bar group count:", bars.size())
	for n in bars:
		# Debug, list every candidate that is in the grouop at runtime
		print(" candidate:", n.get_path(), " type:", n.get_class())
		
	# Pick the first UI Range type from the candidates
	# This supports ProgressBar or TextureProgressBar, both inherit Range and Control
	for n in bars:
		if n is Range and n is Control:
			bossbar = n as Range
			break
	
	# Fallback, if the group search did not find it, try a direct node path
	# Update this path if you change your UI hierarchy
	if bossbar == null and has_node("BossUI/BossBar"):
		bossbar = get_node("BossUI/BossBar") as Range
		
	# If we have a bar, initialize it an make sure it is visible
	if bossbar:
		# Temporary values so it shows something before the boss connects
		bossbar.max_value = 100
		bossbar.value = 100
		if bossbar is Control:
			var c := bossbar as Control
			# Keep layout simple, a top wide bar, you place exact offsets in the editor 
			c.set_anchors_preset(Control.PRESET_TOP_WIDE)
			c.visible = true
			# Debug, print the global rectangle for quick checks
			print("[BossLevel] bar rect:", c.get_global_rect())
		else:
			# Warning if the node found is not a Control, which would be unusual for UI
			push_warning("[BossLevel] BossBar not found. Keep the group only on the real bar.")
			
		# Find the boss group "boss", the WhaleBoss adds itself to this group in its _ready
		boss = get_tree().get_first_node_in_group("boss")
		print("[BossLevel] boss found:", boss)
		if boss and boss.has_signal("hp_changed"):
			# Connect boss health updates to the UI update handler 
			boss.hp_changed.connect(_on_boss_hp_changed)
			print("[BossLevel] connected hp_changed")
			# Initialize the bar to the boss current max if available 
			if "max_hp" in boss:
				_on_boss_hp_changed(boss.max_hp, boss.max_hp)
				
# Update the bar whenever the boss reports a health change 
func _on_boss_hp_changed(cur: int, mx: int) -> void:
	if bossbar:
		bossbar.max_value = mx
		bossbar.value = cur
		
