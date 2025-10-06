extends Area2D
var pos_dict = {
	'4-1':Vector2(-332,-144),'4-2':Vector2(-165,-141),'4-3':Vector2(0,-141),'4-4':Vector2(165,-141),'4-5':Vector2(332,-141),'5-1':Vector2(-341,-2),'5-2':Vector2(-171,-1),'5-3':Vector2(0,0),'5-4':Vector2(171,-1),'5-5':Vector2(341,-2),'6-1':Vector2(-349,140),'6-2':Vector2(-175,140),'6-3':Vector2(0,141),'6-4':Vector2(175,140),'6-5':Vector2(349,140),
'1-1':Vector2(-310,  -122),'1-2':Vector2(-158,-120),'1-3':Vector2(00 , -118),'1-4':Vector2(158, -120),'1-5':Vector2(310, -122),'2-1':Vector2(-318,1),'2-2':Vector2(-160, 00),'2-3':Vector2(00,00),'2-4':Vector2(160,0),'2-5':Vector2(318, 1),'3-1':Vector2(-325,119),'3-2':Vector2(-164,120.5),'3-3':Vector2(0,120),'3-4':Vector2(164,120.5),'3-5':Vector2(325,119),

}
var og_color: Vector4
var all_nodes : Array[Node] = []
var overlay: Sprite2D
var scew_dict = {
	'4-1':-3,'4-2':-1.5,'4-3':0,'4-4':1.5,'4-5':3,'5-1':-3,'5-2':-1.5,'5-3':0,'5-4':1.5,'5-5':3,'6-1':-3,'6-2':-1.5,'6-3':0,'6-4':1.5,'6-5':3,
'1-1':-3,'1-2':-1.5,'1-3':0,'1-4':1.5,'1-5':3,'2-1':-3,'2-2':-1.5,'2-3':0,'2-4':1.5,'2-5':3,'3-1':-3,'3-2':-1.5,'3-3':0,'3-4':1.5,'3-5':3,
}
@onready var sp: Sprite2D = $"../sprite"
var pos : Vector2
var is_hovered = false
var card_list = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pos = pos_dict[self.name] + sp.position + Vector2(-100,-127)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	
func _on_Field_mouse_entered():
	is_hovered = true
	if  not overlay: overlay = $overlay
	if overlay:
		if overlay.material is ShaderMaterial:
			overlay.material.set_shader_parameter("Enable_Effects",  true)
			overlay.material.set_shader_parameter("Border_Color",  Vector4(0,0,1,1))

func _on_Field_mouse_exited():
	is_hovered = false
func check_mouse():
	var mouse_pos = get_global_mouse_position()
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	
	parameters.position= mouse_pos
	parameters.collide_with_areas = true
	parameters.collide_with_bodies = false
	parameters.collision_mask = 0xFFFFFFFF
	var result = space_state.intersect_point(parameters)
	
	for hit in result:
		var collider = hit.collider
		if collider == self:
			return true

func accepts_card(_card: Control) -> bool:
	# Add logic for rules, e.g., mana cost, etc.
	#return is_hovered
	if _card.controller.board != self.get_parent() or _card.can_be_payed() == false:
		return false
	if not card_list:
		return true
	else:
		return false
		
func color_range(dragging = true):
	all_nodes = get_tree().get_nodes_in_group("slots")
	var ranges :Array
	var coloring_type: String = ""
	if dragging:
		coloring_type = "to_play"
		ranges  = (TurnManager.dragging.card_data['range'])
	elif TurnManager.targeting:
		if TurnManager.targeting.card_location == 'field':
			ranges = (TurnManager.targeting.card_data['range'])
	var aplied : Array[String] = []
	var altered: Array[Area2D] = []
	for node in all_nodes:
		var origin = name.split("-")
		for r in ranges :
			var parts = r.split(".")
			if node.name == str( int(origin[0]) - int(parts[0])) + "-" +str(int(origin[1]) - int(parts[1]) ):
				node.set_color(Vector4(0.8,0,0,0.75))
				node.og_color = Vector4(0.8,0,0,0.75)
				aplied.append(node.name)
				altered.append(node)
			elif node.name not in aplied:
				node.og_color = (Vector4(0,0,0,0))
	TurnManager.highlighted_slots = altered
# Called every frame. 'delta' is the elapsed time since the previous frame.
func highlight_range() -> void:
	if TurnManager.dragging:
			if TurnManager.dragging.can_be_payed():
				color_range()
func _process(_delta: float) -> void:
	if og_color:
		set_color(og_color)
	elif og_color == null or og_color == Vector4(0,0,0,0):
		reset_higlight()
	if check_mouse():
		is_hovered = true
		highlight_range()
	else:
		if TurnManager.dragging:
			if accepts_card(TurnManager.dragging):
				set_color(Vector4(0,1,0,0.75))
		is_hovered = false
	if is_hovered and card_list:
		card_list[0].movement.highlighted = true
		TurnManager.highlighted = card_list[0]
		card_list[0].movement.animate_scale(card_list[0].hover_scale)
	elif is_hovered == false and card_list:
		card_list[0].movement.highlighted = false
		card_list[0].movement.animate_scale(card_list[0].normal_scale)
	pass
func reset_higlight():
	if  not overlay:overlay = $overlay
	if overlay:
		if overlay.material is ShaderMaterial:
			overlay.material.set_shader_parameter("Enable_Effects",  false)
			overlay.material.set_shader_parameter("Border_Color",  Vector4(0,0,0,0))

func set_color(color:Vector4):
	if  not overlay:overlay = $overlay
	overlay.material.set_shader_parameter("Enable_Effects",  true)
	overlay.material.set_shader_parameter("Border_Color",  color)
func _on_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	pass # Replace with function body.


func _on_mouse_entered() -> void:
	is_hovered = true
	if  not overlay: overlay = $overlay
	if overlay:
		if overlay.material is ShaderMaterial:
			overlay.material.set_shader_parameter("Enable_Effects",  true)
			overlay.material.set_shader_parameter("Border_Color",  Vector4(0,0,1,1))
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	is_hovered = false
	if  not overlay: overlay = $overlay
	if overlay:
		if overlay.material is ShaderMaterial:
			overlay.material.set_shader_parameter("Enable_Effects",  false)
			overlay.material.set_shader_parameter("Border_Color",  Vector4(0,0,1,0))
	pass # Replace with function body.
