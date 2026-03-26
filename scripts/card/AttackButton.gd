extends TextureButton
class_name AttackButton

@onready var action_panel: ActionPanel = $".."
@onready var card: Card
var highlight: float = 0.0
func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var unique_material := material.duplicate()
	material = unique_material

func _on_mouse_entered() -> void:
	if visible:
		material.set_shader_parameter("hover_ratio", 0.3)

func _on_mouse_exited() -> void:
	if visible:
		material.set_shader_parameter("hover_ratio", 0.0)

func _attack_pressed(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if TurnManager.current_phase != GameEnums.TurnEnum.MAIN:
		UI_Manager.debug.text += "attack button pressed but turn is not correct"
		return
	if TurnManager.waiting_for_input:
		UI_Manager.debug.text += "waiting for other inputs to take place"
		return

	card = action_panel.current_card
	var valid_targets: Array = card.state.can_attack(Game_Manager.gamestate)
	if valid_targets.is_empty():
		return

	get_viewport().set_input_as_handled()
	AttackManager.begin_attack(card, valid_targets)

func _on_color_rect_gui_input(event: InputEvent) -> void:
	_attack_pressed(event)
