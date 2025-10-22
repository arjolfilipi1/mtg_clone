extends TextureButton
@onready var card:Card = $"../.."
@onready var container = $".."
@onready var image:ColorRect = $ColorRect
var highlight: float

func _ready():
	var unique_material := material.duplicate()
	material = unique_material
	_on_visibility_changed()

func _on_visibility_changed():
	# Only process input when visible
	self.get_parent().mouse_filter = MOUSE_FILTER_IGNORE if not visible else MOUSE_FILTER_PASS
	

func _is_hovered() -> bool:
	return get_global_rect().has_point(get_global_mouse_position())

func _on_mouse_entered():
	if visible and card.state.controller.is_human:
		TurnManager.highlighted = card
		card.parts_highlighted = true
		material.set_shader_parameter("hover_ratio", 0.3)
		highlight = 0.3
		card.hilight_on()

func _on_mouse_exited():
	
	if visible:
		material.set_shader_parameter("hover_ratio", 0.0)
		pass
		#card.hilight_off()
func _process(_delta: float) -> void:
	highlight = highlight - (_delta/5)
	material.set_shader_parameter("hover_ratio", highlight)
	pass
func _attack_pressed(event: InputEvent) -> void:
	if event is InputEventMouseButton: 
		if event.button_index == MOUSE_BUTTON_LEFT:
			if TurnManager.current_phase == TurnManager.TurnEnum.MAIN and card.state.can_attack(TurnManager.game_manager.gamestate):
				TurnManager.current_phase = TurnManager.TurnEnum.ATTACK
				card.movement.attack_target()

func _on_color_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton: 
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("rect click")
			_attack_pressed(event)
