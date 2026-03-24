extends Button
class_name ActivateEffectButton

@onready var parent: ActionPanel = $".."
@onready var card: Card

func _ready() -> void:
	visible = false
	card = parent.current_card
	# Duplicate material for individual shader control
	var unique_material := material.duplicate()
	material = unique_material
	
	# Set proper mouse filtering
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# IMPORTANT: Connect to prevent event propagation
	pressed.connect(_on_button_pressed)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)


func _on_button_pressed():
	# Mark event as handled to prevent card from receiving it
	get_viewport().set_input_as_handled()
	pressed_action()

func _on_button_down():
	# Mark event as handled to prevent card from receiving it
	get_viewport().set_input_as_handled()

func _on_button_up():
	# Mark event as handled to prevent card from receiving it
	get_viewport().set_input_as_handled()

func pressed_action() -> void:
	print("Activate button pressed for: ", card.state.card_name)
	
	if card.state.effects:
		var activatable = card.state.can_activate_effect(TurnManager.game_manager.gamestate)
		if len(activatable) == 1:
			print("Activating effect: ", activatable[0].spec)
			card.state.apply_effect(activatable[0])
		elif len(activatable) > 1:
			print("Multiple effects available, need selection UI")
			card.state.apply_effect(activatable[0])

func _on_mouse_entered():
	if visible and card.state.controller.is_human:
		# Only handle button visual effect
		material.set_shader_parameter("hover_ratio", 0.3)

func _on_mouse_exited():
	if visible:
		material.set_shader_parameter("hover_ratio", 0.0)
