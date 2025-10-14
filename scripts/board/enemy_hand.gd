extends Control

const SPACING = 100.0  # space between cards
const ROTATION_SPREAD = -0.4  # radians
const fan_angle_range := 30.0 
const HEIGHT_ARC = 30.0  # how much they curve
const fan_radius := 300.0
var tweens: Array[Tween] = []
const animation_time := 0.4
func _process_hand(_initialPosition):
	pass
func reset():
	var card_count = get_child_count()
	var center_index = (card_count - 1) / 2.0

	for i in range(card_count):
		var card = get_child(i)
		var offset = i - center_index
		var x = offset * SPACING
		var y = -abs(offset) * HEIGHT_ARC  # makes a U shape
		var rot = offset * ROTATION_SPREAD / card_count

		var fan_tween = get_tree().create_tween()
		fan_tween.tween_property(card, "position", Vector2(x, y), animation_time / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		fan_tween.tween_property(card, "rotation", rot, animation_time / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		tweens.append(fan_tween)
func initial_draw(_initialPosition):
	var card_count = get_child_count()
	var center_index = (card_count - 1) / 2.0
	
	for i in range(card_count):
		var card = get_child(i)
		var offset = i - center_index
		var x = offset * SPACING
		var y = -abs(offset) * HEIGHT_ARC  # makes a U shape
		var rot = offset * ROTATION_SPREAD / card_count
		
		card.position = Vector2(x, y)
		card.rotation = rot
		card.z_index = i  # ensure proper overlap
