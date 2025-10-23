extends Resource
class_name Effect_class


@export var spec:String
@export var type:String = "instand"
@export var target_spec:String = ""
@export var target_count: int = 1
@export var trigger_spec:String = ""
@export var mandatory:bool = false
@export var targets:bool = false
@export var mana_cost:Dictionary = {}
@export var duration:String = "instant"
@export var once_per_turn:String = "soft"
