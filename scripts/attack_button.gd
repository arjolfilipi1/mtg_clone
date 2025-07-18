extends TextureButton
@onready var card:Control = $"../.."
@onready var container = $".."
@onready var image:ColorRect = $ColorRect
func _ready():
	var unique_material := material.duplicate()
	material = unique_material
	_on_visibility_changed()

func _on_visibility_changed():
	# Only process input when visible
	self.get_parent().mouse_filter = MOUSE_FILTER_IGNORE if not visible else MOUSE_FILTER_PASS
	

func _is_hovered() -> bool:
	return get_global_rect().has_point(get_global_mouse_position())

func _on_mouse_entered():
	TurnManager.highlighted = card
	if visible:
		material.set_shader_parameter("hover_ratio", 0.3)
		card.hilight_on()

func _on_mouse_exited():
	
	if visible:
		material.set_shader_parameter("hover_ratio", 0.0)
		pass
		#card.hilight_off()
