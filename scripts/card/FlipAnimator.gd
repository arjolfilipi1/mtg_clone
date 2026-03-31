extends Node

@onready var card_front: SubViewportContainer = $"../SubViewportContainer"
@onready var shadow: ColorRect = $"../shadow"
@onready var card_back: Sprite2D = $"../Back/Sprite2D"
@onready var ss: ColorRect = $"../Summoning_sickness"
@onready var card: Card = $".."

var hide_node: Node
var show_node: Node
enum CardSide { FRONT_VISIBLE, BACK_VISIBLE, FLIPPING }
var current_state: CardSide = CardSide.BACK_VISIBLE
var tween1: Tween = null
var tween_shadow: Tween = null
var flip_duration: float = 0.5

func _ready():
	card_front.hide()
	card_back.show()
	card_front.scale = Vector2(1, 1)
	card_back.scale = Vector2(1, 1)
	
func _exit_tree():
	"""Clean up all tweens"""
	_kill_tweens()
func _kill_tweens():
	if card.state.controller.is_human == false:
		print("kill")
	if tween1 and tween1.is_valid():
		tween1.kill()
		tween1 = null
	
	if tween_shadow and tween_shadow.is_valid():
		tween_shadow.kill()
		tween_shadow = null
func flip_to_back():
	if card.state.controller.is_human == false:
		print("fb")
	if current_state != CardSide.FRONT_VISIBLE or current_state == CardSide.FLIPPING:
		return
	
	_kill_tweens()
	
	current_state = CardSide.FLIPPING
	card_back.show()
	animate_flip(card_front, card_back)
	await tween1.finished
	card_front.hide()
	current_state = CardSide.BACK_VISIBLE

func flip_to_front():
	if card.state.controller.is_human == false:
		print("ff")
	if current_state != CardSide.BACK_VISIBLE or card_back == null or current_state == CardSide.FLIPPING:
		return
	
	#_kill_tweens()  # Kill existing tweens before starting new
	
	current_state = CardSide.FLIPPING
	hide_node = card_back
	show_node = card_front
	animate_flip(card_back, card_front)
	await tween1.finished
	current_state = CardSide.FRONT_VISIBLE

func animate_flip(_hide_node, _show_node):
	tween1 = create_tween()
	tween1.set_parallel(false)
	tween_shadow = create_tween()
	
	tween1.tween_property(hide_node, "scale:x", 0.0, flip_duration/2).set_ease(Tween.EASE_IN)
	tween_shadow.tween_property(shadow, "scale:x", 0.0, flip_duration/2).set_ease(Tween.EASE_IN)
	tween1.tween_callback(hide_and_show_nodes)
	await tween1.finished
	var tween2 = create_tween()
	var tween_shadow2 = create_tween()
	tween2.tween_property(_show_node, "scale:x", 1, flip_duration/2).set_ease(Tween.EASE_IN)
	tween_shadow2.tween_property(shadow, "scale:x", 1, flip_duration/2).set_ease(Tween.EASE_IN)
	tween_shadow2.tween_property(ss, "scale:x", 1, flip_duration/2).set_ease(Tween.EASE_IN)
	tween2.tween_callback(func():
		if card.state.controller.is_human == false:
			print(show_node.scale.x,"x")
		hide_node.scale.x = 1.0
		show_node.scale.x = 1.0)
func hide_and_show_nodes():
	if card.state.controller.is_human == false:
		print("flip center")
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
