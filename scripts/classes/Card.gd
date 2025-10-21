extends Control
class_name Card
#z_index when highlighted
var card_index = 10
#data of the card
#store data from card database
var card_data = {}
var state:CardState
#location hand,mana,field etc
var board_pos:Area2D = null
#if fase up for visual
#if is dragging
var dragging = false
var position_before_drag: Vector2
var rotation_before_drag
#stores offset during movement
var offset: Vector2 = Vector2.ZERO 
	
var hover_scale = Vector2(1.2, 1.2)  # scale when hovered
var normal_scale = Vector2(1.0, 1.0)
var duration:float = 0.2  # seconds for the highlight tween
var highlightTween: Tween

#if any of the cildren is highlighted
var parts_highlighted:= false
var is_card = true
var mana_tween: Tween
#nodes to handle visual and movement(also clicking
@onready var visual : Node = $vizual
@onready var movement: Node =  $movement



#initial setup of the card, called by the game_manager script
func setup(data,players_card,_controller):
	state= CardState.new()
	visual = $vizual
	visual.card = self
	state.controller = _controller
	state.player_controled = true if state.controller.is_human else false
	card_data = data
	state.setup(data)
	visual.set_background_color()
	var new_texture = load("res://assets/art/" + data['image'])
	visual.set_card_art(new_texture)

#destroy card in game
func send_to_grave():
	TurnManager.waiting_for_input = false
	if get_parent():
		get_parent().remove_child(self)
	if board_pos:
		board_pos.card_list.erase(self)
	if TurnManager.highlighted == self:
		TurnManager.highlighted = null
	queue_free()
#highlight card
func hilight_on():
	movement.highlighted = true
	self._on_mouse_entered()
	
func hilight_off():
	self._on_mouse_exited()

func _ready():
	await get_tree().process_frame
	visual.add_mana_symbols()
	visual.set_range()
	scale = normal_scale
	state.deleted.connect(visual.burnCard)
#sends signal to the visual node
func _on_mouse_entered():
	visual._on_mouse_entered()

func _on_mouse_exited():
	if not parts_highlighted:
		movement.highlighted = false
	
	self.z_index = card_index
	



func _on_gui_input(event: InputEvent) -> void:
	movement.on_click(event)





		
func _process(_delta: float) -> void:
	if TurnManager.highlighted != self:
		movement.animate_scale(normal_scale)
	if  state.summoned_on_turn == TurnManager.turn:
		pass
		#right now i am checking attack script, will uncomment later
		#has_summoning_sickness = true
	else:
		state.has_summoning_sickness = false
	if (movement.highlighted and  state.card_location == state.le.hand) or (movement.highlighted and  state.card_location == state.le.field) :
		z_index = card_index + 10
	elif TurnManager.highlighted != self:
		self.z_index = card_index
		
