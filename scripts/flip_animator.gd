extends Node
@onready var card_front: SubViewportContainer = $"../SubViewportContainer"
@onready var shadow: ColorRect = $"../shadow"
@onready var card_back: Sprite2D = $"../Back/Sprite2D"
@onready var ss: ColorRect = $"../Summoning_sickness"
var hide_node:Node
var show_node:Node
enum CardState { FRONT_VISIBLE, BACK_VISIBLE, FLIPPING }
var current_state: CardState = CardState.BACK_VISIBLE
var tween1:Tween
var tween_shadow:Tween
var flip_duration: float = 0.5
# Called when the node enters the scene tree for the first time.
func _ready():
	# Initialize visibility
	card_front.hide()
	card_back.show()
	# Set initial scale
	card_front.scale = Vector2(1, 1)
	card_back.scale = Vector2(1, 1)
	

func flip_to_back():
	if current_state != CardState.FRONT_VISIBLE:
		return
	
	current_state = CardState.FLIPPING
	card_back.show()
	
	# Animate scale and shader
	animate_flip(card_front, card_back)
	await tween1.finished
	card_front.hide()
	current_state = CardState.BACK_VISIBLE

func flip_to_front():
	
	if current_state != CardState.BACK_VISIBLE or card_back == null:
		return
	
	current_state = CardState.FLIPPING
	hide_node = card_back
	show_node = card_front
	# Animate scale and shader
	animate_flip(card_back, card_front)
	await tween1.finished
	#card_back.hide()
	current_state = CardState.FRONT_VISIBLE

func animate_flip(_hide_node, _show_node):
	if tween1:
		tween1.kill()
	tween1 = create_tween()
	tween1.set_parallel(false)
	if tween_shadow:
		tween_shadow.kill()
	tween_shadow = create_tween()
	
	tween1.tween_property(hide_node, "scale:x", 0.0, flip_duration/2).set_ease(Tween.EASE_IN)
	tween_shadow.tween_property(shadow, "scale:x", 0.0, flip_duration/2).set_ease(Tween.EASE_IN)
	# Step 2: After Node1 scale.x reaches 0, hide Node1 and show Node2
	tween1.tween_callback(hide_and_show_nodes)

	# Step 3: Tween Node2 scale.x from 0 to 1
	tween1.tween_property(_show_node, "scale:x", 1, flip_duration/2).set_ease(Tween.EASE_IN)
	tween_shadow.tween_property(shadow, "scale:x", 1, flip_duration/2).set_ease(Tween.EASE_IN)
	tween_shadow.tween_property(ss, "scale:x", 1, flip_duration/2).set_ease(Tween.EASE_IN)
func hide_and_show_nodes():
	hide_node.hide()
	show_node.show()
	if show_node == card_front:
		ss.show()
	show_node.scale.x = 0

func _update_shader_progress(progress: float, node: Node2D):
	if node.material:
		node.material.set_shader_parameter("flip_progress", progress)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if card_front.material is ShaderMaterial:
		card_front.material.set_shader_parameter("scale_x", card_front.scale.x)
	if card_back.material is ShaderMaterial:
		card_back.material.set_shader_parameter("scale_x", card_back.scale.x)
	pass
