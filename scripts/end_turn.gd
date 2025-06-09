extends Control


var is_hovered = false
func _ready():
	
	pass
#func _input_event(viewport, event, shape_idx):
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			#if is_hovered:
				#_on_click()

func _on_input_event() -> void:
	get_node("/root/Main/GameManager").end_turn()
	print("yeah")
	pass # Replace with function body.


func _on_area_2d_mouse_entered() -> void:
	is_hovered = true
	print(self.name)
	 # Replace with function body.


func _on_area_2d_mouse_exited() -> void:
	is_hovered = false
	 # Replace with function body.


func _on_area_2d_input_event( event: InputEvent) -> void:
	print("yeah")
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_hovered:
				get_node("/root/Main/GameManager").end_turn()
				
	


func _on_mouse_entered() -> void:
	print("yeah")
	pass # Replace with function body.
