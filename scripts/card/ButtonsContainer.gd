extends HBoxContainer

@onready var card: Card = get_parent()

func _ready():
	visible = false
	
	# Set proper mouse filtering
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Ensure buttons don't steal focus from card
	for button in get_children():
		if button is BaseButton:
			button.mouse_filter = Control.MOUSE_FILTER_PASS
			# IMPORTANT: Connect button signals to prevent event propagation
			button.pressed.connect(_on_button_pressed.bind(button))
			button.button_down.connect(_on_button_down.bind(button))
			button.button_up.connect(_on_button_up.bind(button))

func _on_button_pressed(button: BaseButton):
	# Don't let the card receive this click
	get_viewport().set_input_as_handled()

func _on_button_down(button: BaseButton):
	# Don't let the card receive this click
	get_viewport().set_input_as_handled()

func _on_button_up(button: BaseButton):
	# Don't let the card receive this click
	get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not visible:
		return
	
	# Position buttons relative to card
	if card.highlight_manager and card.highlight_manager.is_highlighted:
		# Scale buttons with card
		var scale_factor = card.hover_scale / card.scale
		scale = scale_factor
		position.y = -100 * scale_factor.y
