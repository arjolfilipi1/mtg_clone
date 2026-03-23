extends Resource
class_name TweenHelper

static var active_tweens: Dictionary = {}

static func create_tween(node: Node, key: String = "") -> Tween:
	"""Create a tween and track it"""
	var tween = node.create_tween()
	
	# Generate a key if not provided
	if key.is_empty():
		key = str(node.get_instance_id()) + "_" + str(Time.get_ticks_msec())
	
	# Store in active tweens
	if not active_tweens.has(node):
		active_tweens[node] = []
	
	active_tweens[node].append({"key": key, "tween": tween})
	
	# Auto-cleanup when tween finishes
	tween.finished.connect(_on_tween_finished.bind(node, key))
	tween.killed.connect(_on_tween_finished.bind(node, key))
	
	return tween

static func kill_all_tweens(node: Node):
	"""Kill all tweens for a node"""
	if active_tweens.has(node):
		for tween_data in active_tweens[node]:
			if tween_data.tween and tween_data.tween.is_valid():
				tween_data.tween.kill()
		active_tweens.erase(node)

static func _on_tween_finished(node: Node, key: String):
	"""Remove tween from tracking when finished"""
	if active_tweens.has(node):
		active_tweens[node].erase(
			active_tweens[node].find_custom(func(t): return t.key == key)
		)
		if active_tweens[node].is_empty():
			active_tweens.erase(node)
