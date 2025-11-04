extends RefCounted
class_name Card_event
enum e {
	ON_ATTACK,
	ON_DEATH,
	ON_DESTRUCTION,
	ON_KILL,
	ON_MANA_CREATE,
	ON_SUMMON,
ON_MOVE,
ON_DRAW,
ON_DEFEND,
ON_DEATH_ON_FIELD,
ON_SHIELD_SET,
ON_EFFECT_DECLARED,
ON_EFFECT_ACTIVATED,

}
const _MANA_COLORS = {
	"generic": Color(0.7, 0.7, 0.7),
	"white": Color(1, 1, 1),
	"black": Color(0.4, 0.4, 0.4),
	"green": Color(0.1, 0.8, 0.1),
	"blue": Color(0.1, 0.6, 1),
	"red": Color(1, 0.2, 0.2),
	"earth": Color(0.6, 0.4, 0.2)}
