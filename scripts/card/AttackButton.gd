extends TextureButton
class_name AttackButton

@onready var parent: ActionPanel = $".."
@onready var card: Card
var highlight: float = 0.0
func _ready():
	var unique_material := material.duplicate()
	material = unique_material
	card = parent.current_card
	# Set proper mouse filtering
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# IMPORTANT: Connect to prevent event propagation
	pressed.connect(_on_button_pressed)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	visible = false

func _on_button_pressed():
	get_viewport().set_input_as_handled()

func _on_button_down():
	get_viewport().set_input_as_handled()

func _on_button_up():
	get_viewport().set_input_as_handled()

func _on_mouse_entered():

	if parent.visible and card.state.controller.is_human:
		# Only handle button visual effect
		material.set_shader_parameter("hover_ratio", 0.3)
		highlight = 0.01

func _on_mouse_exited():
	if visible:
		material.set_shader_parameter("hover_ratio", 0.0)

func _process(_delta: float) -> void:
	if visible:
		if not card:
			card = parent.current_card
	
	# Fade out hover effect
	if highlight > 0:
		highlight = max(0, highlight - _delta / 5)
		material.set_shader_parameter("hover_ratio", highlight)



func _attack_pressed(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if TurnManager.current_phase == GameEnums.TurnEnum.MAIN and not TurnManager.waiting_for_input:
				var can_attack = card.state.can_attack(Game_Manager.gamestate)
				if can_attack:
					TurnManager.current_phase = GameEnums.TurnEnum.ATTACK
					print("start_attack_targeting")
					UI_Manager.start_attack_targeting(card)
					# Mark event as handled
					get_viewport().set_input_as_handled()

func _on_color_rect_gui_input(event: InputEvent) -> void:
	_attack_pressed(event)
