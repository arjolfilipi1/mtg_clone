extends Resource
class_name Effect_class

@export var actions: Array = []          # Array[Dictionary] — the new format
@export var trigger_spec: String = ""    # when it fires
@export var target_count: int = 1        # how many targets player picks
@export var speed: int = 1
@export var mandatory: bool = false
@export var mana_cost: Dictionary = {}
@export var once_per_turn: String = "soft"
@export var description: String = ""
@export var used_this_turn: bool = false  # tracks once_per_turn

# Called at end of turn to reset soft once-per-turn effects
func reset_once_per_turn() -> void:
	if once_per_turn == "soft":
		used_this_turn = false
