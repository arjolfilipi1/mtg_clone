extends Control
class_name Card
#z_index when highlighted
var card_index = 10
signal pressed(Node)
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
	
var hover_scale = Vector2(1.2, 1.2)  # scale when hovered
var normal_scale = Vector2(1.0, 1.0)
var duration:float = 0.2  # seconds for the highlight tween

#if any of the cildren is highlighted
var parts_highlighted:= false


#nodes to handle visual and movement(also clicking
@onready var visual : Node = $vizual
@onready var movement: Node =  $movement

func _exit_tree():
	"""Clean up when card is destroyed"""
	# Clean up tweens from movement
	if movement and movement.has_method("_cleanup_tweens"):
		movement._cleanup_tweens()
	
	

#initial setup of the card, called by the game_manager script
func setup(data,_controller):
	state= CardState.new()
	visual = $vizual
	visual.card = self
	state.controller = _controller
	state.card_node = self
	state.player_controled = true if state.controller.is_human else false
	state.setup(data)
	
	
	
#destroy card in game
func send_to_grave():
	# Clear highlight before removal
	TurnManager.waiting_for_input = false
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
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Don't start dragging if clicking on a button
				
				pressed.emit()
	
	movement.on_click(event)

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
	
	
