extends Control
@onready var prev = $"../CardListViewer"
@onready var label = $"../PlayerMana/Label"
const MANA_COLORS = {
	"generic": Color(0.5, 0.5, 0.5),
	"white": Color(1, 1, 1),
	"black": Color(0.1, 0.1, 0.1),
	"green": Color(0.1, 0.8, 0.1),
	"blue": Color(0.1, 0.6, 1),
	"red": Color(1, 0.2, 0.2),
	"earth": Color(0.6, 0.4, 0.2)
}

var rotation_angle := 0.0
var rotation_speed := 0.5  # Radians per second (adjust as needed)
var orb_list

func pressed(): 
	prev.show_cards(TurnManager.gamestate.player_mana, "Mana")

func spawn_mana_orb(mana_type: String, _position: Vector2,node:Node):
	orb_list =[]
	var orb_scene = preload("res://scenes/ManaOrb.tscn")
	var orb_instance = orb_scene.instantiate()
	orb_instance.position = _position
	orb_instance.add_to_group("mana_orb")
	
	var sprite = orb_instance.get_node("Sprite2D")
	var original_material = sprite.material
	var shader_mat = original_material.duplicate()
	if shader_mat is ShaderMaterial:
		shader_mat.set_shader_parameter("glow_color", MANA_COLORS.get(mana_type, Color(1, 1, 1)))
	sprite.material = shader_mat
	orb_instance.z_index = node.get_child_count()+10
	node.add_child(orb_instance)
	orb_list.append(orb_instance)
	arrange_mana_orbs_in_circle(Vector2(60,75),30)
	return orb_instance
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.visible = false

func arrange_mana_orbs_in_circle(center: Vector2, radius: float = 100.0):
	var orbs = get_children().filter(func(child):return child.is_in_group("mana_orb"))
	if orb_list:
		var count = min(orbs.size(), 15)
		var angle_step = TAU / float(count)

		for i in range(count):
			if orbs[i].is_in_group("mana_orb"):
				var angle = rotation_angle + i * angle_step
				var target_pos = center + Vector2(cos(angle), sin(angle)) * radius
				
				orbs[i].position = target_pos
				
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if orb_list:
		rotation_angle += rotation_speed * _delta
		arrange_mana_orbs_in_circle(Vector2(60,75),30)  # Use your center and radius


func _on_gui_input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		prev.show_cards(Game_Manager.gamestate.player_mana, "Mana")
		print("mana pressed")

func _area_pressed(_node: Node,event: InputEvent,  _shape_idx: int)->void:
	_on_gui_input(event)


func _on_area_2d_mouse_entered() -> void:
	label.visible = true
	print("entered")

func _on_area_2d_mouse_exited() -> void:
	label.visible = false
