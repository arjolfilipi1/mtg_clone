extends Node2D

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		check_objects_at_position(mouse_pos)

func check_objects_at_position(position: Vector2):
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = position
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_point(query)
	
	print("Objects at position ", position, ":")
	for result in results:
		var collider = result["collider"]
		print(" - ", collider.name, " (", collider.get_class(), ")")
