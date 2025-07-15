extends TextureButton
@onready var card:Control = $"../.."
@onready var image:ColorRect = $ColorRect
func _ready():
	

	
	# Initialize input state
	_on_visibility_changed()

func _on_visibility_changed():
	# Only process input when visible
	mouse_filter = MOUSE_FILTER_IGNORE if not visible else MOUSE_FILTER_STOP
	
	# Reset hover state when visibility changes
	if not visible and _is_hovered():
		_on_mouse_exited()

func _is_hovered() -> bool:
	return get_global_rect().has_point(get_global_mouse_position())

func _on_mouse_entered():
	print(self.name," in")
	if visible:
		print(self.name," on")
		card.hilight_on()

func _on_mouse_exited():
	print(self.name," off")
	if visible:
		pass
		#card.hilight_off()
