# GoalArrow.gd
extends Sprite2D

func _process(_delta):
	# Find all active goals (whirlpool gates)
	var goals = get_tree().get_nodes_in_group("active_goal")
	
	if goals.size() > 0 and is_instance_valid(goals[0]):
		# Point to the first goal
		var goal = goals[0]
		
		# Debug: print to see what we found
		print("Goal found at: ", goal.global_position)
		
		var direction = (goal.global_position - global_position).normalized()
		rotation = direction.angle()
		visible = true
	else:
		# No goal active, hide arrow
		visible = false
