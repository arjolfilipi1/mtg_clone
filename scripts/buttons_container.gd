extends HBoxContainer

func _ready() -> void:
	# Let mouse events pass through container
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Connect signals for all children with type safety
	for child: Control in get_children():
		if child is Control:  # Ensure it's a Control node
			child.mouse_entered.connect(_on_child_mouse_entered.bind(child))
			# Optional: Connect mouse_exited as well
			child.mouse_exited.connect(_on_child_mouse_exited.bind(child))

func _on_child_mouse_entered(child: Control) -> void:
	print("Mouse entered child: ", child.name)
	# Handle child-specific behavior

func _on_child_mouse_exited(child: Control) -> void:
	print("Mouse exited child: ", child.name)
