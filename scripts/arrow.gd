extends Sprite2D

func _process(_delta):
	var goals = get_tree().get_nodes_in_group("active_goal")
	
	if goals.size() > 0 and is_instance_valid(goals[0]):
		var goal = goals[0]
		
		var direction = (goal.global_position - global_position).normalized()
		rotation = direction.angle()
		visible = true
	else:
		visible = false
