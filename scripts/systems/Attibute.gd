extends Resource
class_name Attribute_class

@export var name:String
@export var active:bool = true
@export var inactive_until_end_of_turn:bool = false
@export var reliant_on:CardState 