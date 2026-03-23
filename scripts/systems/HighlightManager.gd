extends Node
class_name CardHighlightManager

@onready var card: Card = get_parent()
@onready var buttons_container: HBoxContainer = null
@onready var visual: Node = null

var is_hovered: bool = false
var has_button_hover: bool = false
var is_highlighted: bool = false
var current_scale_tween: Tween
var _clear_timer: SceneTreeTimer = null
func _exit_tree():
	"""Clean up when highlight manager is destroyed"""
	if current_scale_tween and current_scale_tween.is_valid():
		current_scale_tween.kill()
		current_scale_tween = null
	
	if _clear_timer:
		_clear_timer.timeout.disconnect(_delayed_clear)
		_clear_timer = null
func _ready():
	# Wait a frame for everything to be ready
	await get_tree().process_frame
	
	# Find references - try multiple paths
	visual = card.get_node_or_null("vizual")
	
	# Try to find buttons_container through different paths
	if visual:
		# Method 1: Direct child of visual
		buttons_container = visual.get_node_or_null("ButtonsContainer")
		
		# Method 2: Direct child of card (if it's a sibling)
		if not buttons_container:
			buttons_container = card.get_node_or_null("ButtonsContainer")
		
		# Method 3: Look for it anywhere under card
		if not buttons_container:
			buttons_container = card.find_child("ButtonsContainer", true, false)
	

	
	# Configure buttons container
	if buttons_container:
		buttons_container.mouse_filter = Control.MOUSE_FILTER_PASS
		buttons_container.visible = false
		
		# Connect button signals after a short delay
		await get_tree().create_timer(0.1).timeout
		_connect_button_signals()

func _connect_button_signals():
	"""Connect signals for all buttons"""
	if not buttons_container:
		print("no bc")
		return
	
	for button in buttons_container.get_children():
		if button is BaseButton:
			# Disconnect any existing connections
			if button.is_connected("mouse_entered", Callable(self, "_on_button_mouse_entered")):
				button.mouse_entered.disconnect(self._on_button_mouse_entered)
			if button.is_connected("mouse_exited", Callable(self, "_on_button_mouse_exited")):
				button.mouse_exited.disconnect(self._on_button_mouse_exited)
			
			# Connect fresh
			button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
			button.mouse_exited.connect(_on_button_mouse_exited.bind(button))

func _on_card_mouse_entered():
	if _clear_timer:
		_clear_timer.timeout.disconnect(_delayed_clear)
		_clear_timer = null
	
	is_hovered = true
	_update_highlight()

func _on_card_mouse_exited():
	is_hovered = false
	# Delay clear to allow for button hover
	_delayed_clear_check()

func _on_button_mouse_entered(_button: BaseButton):
	if _clear_timer:
		_clear_timer.timeout.disconnect(_delayed_clear)
		_clear_timer = null
	
	has_button_hover = true
	# Keep card highlighted while hovering buttons
	if is_hovered or has_button_hover:
		_update_highlight()

func _on_button_mouse_exited(_button: BaseButton):
	has_button_hover = false
	_delayed_clear_check()

func _delayed_clear_check():
	if _clear_timer:
		_clear_timer.timeout.disconnect(_delayed_clear)
		_clear_timer = null
	if card.state.card_location == GameEnums.CardZone.FIELD:
		_clear_timer =TurnManager.get_tree().create_timer(1.0)
	else:
		_clear_timer =TurnManager.get_tree().create_timer(0.3)
	_clear_timer.timeout.connect(_delayed_clear)

func _delayed_clear():
	_clear_timer = null
	if not is_hovered and not has_button_hover and TurnManager.highlighted != card:
		_clear_highlight()

func _update_highlight():
	if is_highlighted:
		return
	
	is_highlighted = true
	card.parts_highlighted = true
	
	# Cancel any pending clear
	if _clear_timer:
		_clear_timer.timeout.disconnect(_delayed_clear)
		_clear_timer = null
	
	# Animate scale
	if current_scale_tween:
		current_scale_tween.kill()
	current_scale_tween = create_tween()
	current_scale_tween.tween_property(card, "scale", card.hover_scale, 0.2)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Raise z-index
	card.z_index = card.card_index + 10
	
	# Show buttons container
	if buttons_container and card.state.controller.is_human:

		buttons_container.visible = true
		buttons_container.z_index = card.z_index + 1
		
		# Update button states based on game state
		_update_button_visibility()
	
	# Set global highlighted reference
	if card.state and card.state.controller and card.state.controller.is_human:
		TurnManager.highlighted = card

func _clear_highlight():
	if not is_highlighted:
		return
	
	is_highlighted = false
	card.parts_highlighted = false
	
	# Animate scale back
	if current_scale_tween:
		current_scale_tween.kill()
	current_scale_tween = create_tween()
	current_scale_tween.tween_property(card, "scale", card.normal_scale, 0.2)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Restore z-index
	card.z_index = card.card_index
	
	# Hide buttons container
	if buttons_container and buttons_container.visible:
		buttons_container.visible = false
	
	# Clear global reference if this card was highlighted
	if TurnManager.highlighted == card:
		TurnManager.highlighted = null

func _update_button_visibility():
	if not buttons_container:
		print(buttons_container)
		return
	
	# Update attack button
	var attack_button = buttons_container.get_node_or_null("attack")
	if attack_button:
		var can_attack = card.state.can_attack(TurnManager.game_manager.gamestate)
		attack_button.visible = can_attack and TurnManager.current_phase == GameEnums.TurnEnum.MAIN
	
	# Update move button
	var move_button = buttons_container.get_node_or_null("move")
	if move_button:
		var can_move = card.state.can_move(TurnManager.game_manager.gamestate)
		move_button.visible = can_move and TurnManager.current_phase == GameEnums.TurnEnum.MAIN
	
	# Update activate button
	var activate_button = buttons_container.get_node_or_null("activate")
	if activate_button:
		var can_activate = card.state.can_activate_effect(TurnManager.game_manager.gamestate)
		activate_button.visible = not can_activate.is_empty() and TurnManager.current_phase == GameEnums.TurnEnum.MAIN

func force_clear():
	"""Force clear highlight (useful when card is destroyed or moved)"""
	if _clear_timer:
		_clear_timer.timeout.disconnect(_delayed_clear)
		_clear_timer = null
	is_hovered = false
	has_button_hover = false
	_clear_highlight()
