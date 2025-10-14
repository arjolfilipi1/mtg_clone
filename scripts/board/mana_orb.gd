extends Node2D
var is_card = false
var scale_factor = 1.0
var mana_type = ""
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
func shrink_and_delete(target_node: Node2D):
	var tween := get_tree().create_tween()
	tween.tween_property(target_node, "scale", Vector2(0, 0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(Callable(target_node, "queue_free"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if TurnManager.current_phase == TurnManager.TurnEnum.DRAW:
		#shrink_and_delete(self)
		pass
	var parent = get_parent()
	var index = 20

	for c in parent.get_children():
		if c is Node2D:
			index += 1
			if self == c:
				break
		self.z_index = index

	pass
