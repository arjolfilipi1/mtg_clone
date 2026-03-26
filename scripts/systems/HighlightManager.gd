extends Node
class_name CardHighlightManager

@onready var card: Card = get_parent()
@onready var visual: Node = null

var is_hovered: bool = false

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
	

	# Keep card highlighted while hovering buttons
	if is_hovered :
		_update_highlight()

func _on_button_mouse_exited(_button: BaseButton):
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
	if not is_hovered  and UI_Manager.highlighted != card:
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
	
	
	# Set global highlighted reference
	if card.state and card.state.controller and card.state.controller.is_human:
		UI_Manager.highlighted = card

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
	

	
	# Clear global reference if this card was highlighted
	if UI_Manager.highlighted == card:
		UI_Manager.highlighted = null


func force_clear():
	"""Force clear highlight (useful when card is destroyed or moved)"""
	if _clear_timer:
		_clear_timer.timeout.disconnect(_delayed_clear)
		_clear_timer = null
	is_hovered = false
	_clear_highlight()
