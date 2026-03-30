extends Control
class_name Card
#z_index when highlighted
var card_index = 10
signal pressed(card: Card)
#data of the card
#store data from card database

var state:CardState
#location hand,mana,field etc
var board_pos:Area2D = null
#if fase up for visual
#if is dragging
var dragging = false
#stores offset during movement
var offset: Vector2 = Vector2.ZERO 
#if any of the cildren is highlighted
var parts_highlighted:= false


#nodes to handle visual and movement(also clicking
@onready var visual : Node = $vizual
#@onready var movement: Node =  $movement
@onready var normal_scale: Vector2 = Vector2.ONE
@onready var hover_scale: Vector2 = Vector2(1.2, 1.2)


#initial setup of the card, called by the game_manager script
func setup(data,_controller):
	state= CardState.new()
	visual = $vizual
	visual.card = self
	state.controller = _controller
	state.card_node = self
	state.player_controled =  state.controller.is_human 
	state.setup(data)

#destroy card in game
func send_to_grave():
	# Clear highlight before removal
	TurnManager.waiting_for_input = false
	MovementManager.move_card_to_grave(self, global_position, _on_grave_movement_complete)

func _on_grave_movement_complete(card: Card):
	if get_parent():
		get_parent().remove_child(self)
	if board_pos:
		board_pos.card_list.erase(self)
	if UI_Manager.highlighted == self:
		UI_Manager.highlighted = null
	queue_free()

	

func _ready():

	
	await get_tree().process_frame
	visual.add_mana_symbols()
	visual.set_range()
	scale = normal_scale
	state.deleted.connect(visual.burnCard)
	state.attack_signal.connect(visual.attack.start_slam_attack)
	state.activated_effect.connect(func(_eff):UI_Manager.queue_effect(self))
	visual.set_background_color()
	# Setup proper mouse filtering
	mouse_filter = Control.MOUSE_FILTER_PASS
	var new_texture = load("res://assets/art/" + state.image)
	visual.set_card_art(new_texture)

#send data to movement for drag etc and signals if the card is selected
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and dragging:
		MovementManager.animate_card_drag(self, get_global_mouse_position(), offset)
func _handle_mouse_button(event: InputEventMouseButton):
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	if event.pressed:
		pressed.emit(self)
		_on_press()
	else:
		_on_release()
func _on_press():
	if state.player_controled:
		if TurnManager.is_selecting_mana and not state.controller.mana_selected:
			MovementManager.move_card_to_mana(self, state.player_controled, 
				UI_Manager.player_mana_card_nr + 1)
		elif TurnManager.current_phase == GameEnums.TurnEnum.MAIN and not TurnManager.waiting_for_input:
			if state.card_location == GameEnums.CardZone.HAND:
				_start_drag()

func _on_release():
	if dragging:
		MovementManager.end_card_drag(self, get_global_mouse_position())
		dragging = false
func _start_drag():
	dragging = true
	offset = get_global_mouse_position() - global_position
	TurnManager.dragging = self
	visual.set_drag_visuals(true,0.7)

func _on_mouse_entered():
	Game_Manager.select_card(self)
	UI_Manager.on_card_hovered(self)


func _on_mouse_exited():
	UI_Manager.on_card_unhovered(self)


func _process(_delta: float) -> void:

	if state.summoned_on_turn == TurnManager.turn:
		pass
	else:
		state.has_summoning_sickness = false
	

func _connect_button_signals():
	"""Connect signals for all buttons in the container"""
	if not visual or not visual.buttons_container:
		return
	
	
