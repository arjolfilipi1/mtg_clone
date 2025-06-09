extends ColorRect

var viewport_size : Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	viewport_size= get_viewport().get_visible_rect().size
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if material is ShaderMaterial:
		material.set_shader_parameter("screen_center", Vector2(viewport_size.x * 0.5, viewport_size.y * 0.5))
