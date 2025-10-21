extends Button
@onready var card:Card = $"../.."
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	visible = false
	var unique_material := material.duplicate()
	material = unique_material
	_on_visibility_changed()
func _is_hovered() -> bool:
	return get_global_rect().has_point(get_global_mouse_position())

func _on_mouse_entered():
	if visible and card.state.controller.is_human:
		TurnManager.highlighted = card
		card.parts_highlighted = true
		material.set_shader_parameter("hover_ratio", 0.3)
		card.hilight_on()

func _on_mouse_exited():
	
	if visible:
		material.set_shader_parameter("hover_ratio", 0.0)
		pass
		#card.hilight_off()
func _on_visibility_changed():
	# Only process input when visible
	self.get_parent().mouse_filter = MOUSE_FILTER_IGNORE if not visible else MOUSE_FILTER_PASS
func pressed() -> void:
	print("pressed")
	if card.state.effects:
		var activatable = card.state.can_activate_effect(TurnManager.game_manager.gamestate)
		if  len(activatable) == 1:
			print("acctivating")
			card.state.apply_effect(activatable[0])
		else:
			pass

func _process(_delta:float) -> void:
	if card.state.effects:
		if  card.state.can_activate_effect(TurnManager.game_manager.gamestate):
			visible = true
		else:
			visible = false


func _on_gui_input(event: InputEvent) -> void:
	pass # Replace with function body.
