extends Control
class_name Card
#z_index when highlighted
var card_index = 10
signal pressed(Node)
#data of the card
#store data from card database
var card_data = {}
var state:CardState
#location hand,mana,field etc
var board_pos:Area2D = null
#if fase up for visual
#if is dragging
var dragging = false
#stores offset during movement
var offset: Vector2 = Vector2.ZERO 
	
var hover_scale = Vector2(1.2, 1.2)  # scale when hovered
var normal_scale = Vector2(1.0, 1.0)
var duration:float = 0.2  # seconds for the highlight tween

#if any of the cildren is highlighted
var parts_highlighted:= false


#nodes to handle visual and movement(also clicking
@onready var visual : Node = $vizual
@onready var movement: Node =  $movement
@onready var highlight_manager: CardHighlightManager = $HighlightManager
func _exit_tree():
	"""Clean up when card is destroyed"""
	# Clean up tweens from movement
	if movement and movement.has_method("_cleanup_tweens"):
		movement._cleanup_tweens()
	
	# Clean up highlight manager tweens
	if highlight_manager:
		if highlight_manager.current_scale_tween and highlight_manager.current_scale_tween.is_valid():
			highlight_manager.current_scale_tween.kill()

#initial setup of the card, called by the game_manager script
func setup(data,_controller):
	state= CardState.new()
	visual = $vizual
	visual.card = self
	state.controller = _controller
	state.card_node = self
	state.player_controled = true if state.controller.is_human else false
	card_data = data
	state.setup(data)
	visual.set_background_color()
	var new_texture = load("res://assets/art/" + data['image'])
	visual.set_card_art(new_texture)
	
#destroy card in game
func send_to_grave():
	# Clear highlight before removal
	if highlight_manager:
		highlight_manager.force_clear()
	TurnManager.waiting_for_input = false
	if get_parent():
		get_parent().remove_child(self)
	if board_pos:
		board_pos.card_list.erase(self)
	if TurnManager.highlighted == self:
		TurnManager.highlighted = null
	queue_free()


	

func _ready():
	# Add highlight manager if not present
	if not has_node("HighlightManager"):
		var hm = CardHighlightManager.new()
		hm.name = "HighlightManager"
		add_child(hm)
		highlight_manager = hm
	


	
	await get_tree().process_frame
	visual.add_mana_symbols()
	visual.set_range()
	scale = normal_scale
	state.deleted.connect(visual.burnCard)
	state.attack_signal.connect(visual.attack.start_slam_attack)
	state.activated_effect.connect(visual.show_effect)
	
	# Setup proper mouse filtering
	mouse_filter = Control.MOUSE_FILTER_PASS
	

#send data to movement for drag etc and signals if the card is selected
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Don't start dragging if clicking on a button
				
				pressed.emit()
	
	movement.on_click(event)

func _on_mouse_entered():
	TurnManager.game_manager.select_card(self)
	if highlight_manager:
		highlight_manager._on_card_mouse_entered()

func _on_mouse_exited():
	if highlight_manager:
		highlight_manager._on_card_mouse_exited()



		
func _process(_delta: float) -> void:

	# Original process logic
	if TurnManager.highlighted != self:
		#movement.animate_scale(normal_scale)
		pass
	if state.summoned_on_turn == TurnManager.turn:
		pass
	else:
		state.has_summoning_sickness = false
	

func _connect_button_signals():
	"""Connect signals for all buttons in the container"""
	if not visual or not visual.buttons_container:
		return
	
	for button in visual.buttons_container.get_children():
		if button is BaseButton:
			# Disconnect existing to avoid duplicates
			if button.is_connected("mouse_entered", Callable(highlight_manager, "_on_button_mouse_entered")):
				button.mouse_entered.disconnect(highlight_manager._on_button_mouse_entered)
			if button.is_connected("mouse_exited", Callable(highlight_manager, "_on_button_mouse_exited")):
				button.mouse_exited.disconnect(highlight_manager._on_button_mouse_exited)
			
			# Connect fresh
			button.mouse_entered.connect(highlight_manager._on_button_mouse_entered.bind(button))
			button.mouse_exited.connect(highlight_manager._on_button_mouse_exited.bind(button))
