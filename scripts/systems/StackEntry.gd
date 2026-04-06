class_name StackEntry
extends RefCounted
 
# The effect data object (your existing Effect_class)
var effect: Effect_class
 
# The CardState that generated this entry
var source: CardState
 
# The player who controls this entry
var controller  # Player
 
# Pre-resolved targets (Array of CardState or Player)
# These are locked in when the entry is pushed, not at resolution time.
var targets: Array = []
 
# Whether an opponent can counter or respond to this entry.
# Spells and activated abilities are counterable.
# Some triggered abilities are not (e.g. replacement effects never reach the stack).
var is_counterable: bool = true
 
# "spell", "activated", "triggered"
var entry_type: String = "triggered"
 
# Human-readable label shown in the stack UI
var label: String = ""
 
func _init(
	_effect: Effect_class,
	_source: CardState,
	_controller,
	_targets: Array = [],
	_type: String = "triggered",
	_counterable: bool = true
) -> void:
	effect     = _effect
	source     = _source
	controller = _controller
	targets    = _targets
	entry_type = _type
	is_counterable = _counterable
	label = _source.card_name + ": " + _effect.description
