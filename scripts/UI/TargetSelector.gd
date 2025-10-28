extends Node
class_name TargetSelector

signal completed(selected_targets: Array)

var valid_targets: Array = []
var max_count: int = 1
var selected_targets: Array = []
var c:int =0

func _on_target_clicked(card):
	var tip = "card" if card is Card else "state"
	c+=1

	
	if card in selected_targets:
		selected_targets.erase(card)
		_highlight(card)
	elif card in valid_targets:
		selected_targets.append(card)
		_selhighlight(card)

	if selected_targets.size() >= max_count:
		_finalize_selection()
func _finalize_selection():
	for t:CardState in valid_targets:
		_unhighlight(t)
		if t.card_node and t.card_node.is_connected("pressed", Callable(self, "_on_target_clicked")):
			t.card_node.pressed.disconnect(_on_target_clicked)
	
	completed.emit(selected_targets)
	print("selection complete")
	queue_free()
	
func _highlight(cs:CardState):
	if cs.card_node:
		cs.card_node.visual.tar.visible = true
		cs.card_node.visual.sel.visible = false
		cs.card_node.visual.valid_target = true
		cs.card_node.visual.target_overlay.show()
		cs.card_node.visual.target_overlay.material.set_shader_parameter('Enable_Effects', true)
		cs.card_node.visual.target_overlay.material.set_shader_parameter('Border_Color', Vector4(0.1,1,0.1,1))
func _unhighlight(cs:CardState):
	cs.card_node.visual.tar.visible = false
	cs.card_node.visual.sel.visible = false
	if cs.card_node:
		cs.card_node.visual.valid_target = false
func _selhighlight(cs:CardState):
	cs.card_node.visual.sel.visible = true
func is_empty():
	return len(selected_targets) > 0
func start_selection(_valid_targets:Array, _max_count:int = 1):
	self.valid_targets = _valid_targets
	print("selection started")
	self.max_count = _max_count
	
	# Highlight all valid targets visually
	for t in valid_targets:
		_highlight(t)

	# Connect clicks
	for t in valid_targets:
		if t.card_node and not t.card_node.is_connected("pressed", Callable(self, "_on_target_clicked")):
			t.card_node.pressed.connect(_on_target_clicked.bind(t))
