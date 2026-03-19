extends Resource
class_name Effect_class


@export var spec:String
@export var type:String = "instand"
@export var target_spec:String = ""
@export var target_count: int = 1
@export var speed: int = 1
@export var trigger_spec:String = ""
@export var mandatory:bool = false
@export var targets:bool = false
@export var mana_cost:Dictionary = {}
@export var duration:String = "instant"
@export var once_per_turn:String = "soft"
@export var description:String = ""
enum Trigger {
	ON_PLAY,
	ON_ATTACK,
	ON_DAMAGE,
	ON_DEATH,
	ON_TURN_START,
	ON_TURN_END,
	MANUAL  # for activated abilities
}
enum Speed{
	SORCERY,
	INSTANT,
	MANA_ABILITY
}
enum TargetType {
	SELF,
	SINGLE_CREATURE,
	ALL_CREATURES,
	PLAYER,
	OPPONENT,
	BOARD_POSITION
}
