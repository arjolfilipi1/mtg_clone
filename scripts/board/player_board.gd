extends Control
@onready var overlay := $sprite/OverlayEffect
var fade = 0.0
var board_slots : Array[Area2D] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	overlay = $sprite/OverlayEffect
	var shader_mat = overlay.material
	if shader_mat is ShaderMaterial:
		shader_mat.set_shader_parameter("screen_size", get_viewport_rect().size)
	await get_tree().process_frame
	for c in get_children():
		if c is Area2D:
			board_slots.append(c)
		for cc:Node in c.get_children():
			if cc.name == "overlay":
				var mat = cc.material
				if cc.material is ShaderMaterial:
					cc.material = mat.duplicate()
	pass # Replace with function body.
func reset_higlight():
	for slot in board_slots:
		slot.reset_higlight()
func check_card(card,game:GameState):
	for slot in board_slots:
		if slot.accepts_card(card,game):
			slot.set_color(Vector4(0,1,0,0.75))
			#slot.og_color(Vector4(0,1,0,0.75))
		else:
			slot.set_color(Vector4(1,0,0,0.75))
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if TurnManager.priority:
		fade += delta 
		fade = min(fade,1.0)
		if overlay.material is ShaderMaterial:
			
			overlay.material.set_shader_parameter("is_glowing", true)
			overlay.material.set_shader_parameter("fade_strength", fade)
	else:
		fade -= delta if fade >= 0.0 else 0.0
		if overlay.material is ShaderMaterial:
			#overlay.material.set_shader_parameter("is_glowing", false)
			overlay.material.set_shader_parameter("fade_strength", fade)
