extends Control

@export var fan_radius := 300.0
@export var fan_angle_range := 30.0
@export var card_scale := Vector2(1, 1)
@export var animation_time := 0.4

var tweens: Array[Tween] = []
var fantweens: Array[Tween] = []
func _ready():
	# Example: automatically fan on start
	# fan_cards()

	pass
func _exit_tree():
	"""Clean up all tweens"""
	_kill_all_tweens()

func _kill_all_tweens():
	for tween in tweens + fantweens:
		if tween and tween.is_valid():
			tween.kill()
	tweens.clear()
	fantweens.clear()
func reset():
	_kill_all_tweens()
	
	var cards = get_children().filter(func(child): return child.is_in_group("card"))
	var card_count = cards.size()
	if card_count == 0:
		return

	var angle_step = fan_angle_range / max(card_count - 1, 1)
	var start_angle = -fan_angle_range / 2.0
	var center = Vector2(100, 250)

	for i in range(card_count):
		var card = cards[i]
		var angle_deg = start_angle + angle_step * i
		var angle_rad = deg_to_rad(angle_deg)
		card.z_index = (i + 1)
		
		var offset = Vector2(
			sin(angle_rad) * fan_radius,
			-cos(angle_rad) * fan_radius
		)
		var target_pos = center + offset
		var target_rot = angle_rad

		card.call_deferred("set_pivot_offset", card.get_rect().size / 2)

		var fan_tween = get_tree().create_tween()
		fan_tween.tween_property(card, "position", target_pos, animation_time / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		fan_tween.tween_property(card, "rotation", target_rot, animation_time / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		fan_tween.tween_property(card, "scale", card_scale, animation_time / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		fantweens.append(fan_tween)
func initial_draw(_initialPosition):
	_kill_all_tweens()

	var cards = get_children()
	var card_count = cards.size()
	if card_count == 0:
		return

	var angle_step = fan_angle_range / max(card_count - 1, 1)
	var start_angle = -fan_angle_range / 2.0

	for i in range(card_count):
		var card = cards[i]
		var angle_deg = start_angle + angle_step * i
		var angle_rad = deg_to_rad(angle_deg)
		card.z_index = (i + 1)
		var target_pos = Vector2(100, 250) + Vector2(
			sin(angle_rad) * fan_radius,
			-cos(angle_rad) * fan_radius
		)
		var target_rot = angle_rad

		var fan_tween = get_tree().create_tween()
		fan_tween.tween_property(card, "position", target_pos, animation_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		fan_tween.tween_property(card, "rotation", target_rot, animation_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		fan_tween.tween_property(card, "scale", card_scale, animation_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		tweens.append(fan_tween)
