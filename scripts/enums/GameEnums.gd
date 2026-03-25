extends Resource
class_name GameEnums

# ============ CARD ENUMS ============
enum CardZone {
	DECK,
	HAND,
	FIELD,
	GRAVEYARD,
	MANA,
	EXILE,
	STACK
}

enum CardType {
	CREATURE,
	SPELL,
	ENCHANTMENT,
	ARTIFACT,
	PLANESWALKER,
	LAND
}

enum CardColor {
	GENERIC,
	WHITE,
	BLUE,
	BLACK,
	RED,
	GREEN,
	EARTH
}

# ============ GAME PHASE ENUMS ============
enum TurnPhase {
	UNTAP,
	UPKEEP,
	DRAW,
	MAIN1,
	BATTLE,
	END,
	CLEANUP
}

# For your current system
enum TurnEnum {
	DRAW,
	MANA_SELECT,
	MANA_CREATE,
	MAIN,
	ATTACK,
	WAITING_FOR_INPUT,
	END
}

# ============ COMBAT ENUMS ============
enum CombatStep {
	BEGIN_COMBAT,
	DECLARE_ATTACKERS,
	COMBAT_DAMAGE,
	END_COMBAT
}

enum AttackType {
	NORMAL,
	DOUBLE_STRIKE,
	FIRST_STRIKE,
	TRAMPLE
}

# ============ EFFECT ENUMS ============
enum EffectSpeed {
	INSTANT = 1,
	SORCERY = 2,
	ACTIVATED = 3,
	TRIGGERED = 4
}

enum EffectDuration {
	INSTANT,
	UNTIL_END_OF_TURN,
	UNTIL_YOUR_NEXT_TURN,
	PERMANENT,
	UNTIL_LEAVES_BATTLEFIELD
}

enum EffectTrigger {
	ON_PLAY,
	ON_ATTACK,
	ON_BLOCK,
	ON_DAMAGE,
	ON_DEATH,
	ON_TURN_START,
	ON_TURN_END,
	ON_UPKEEP,
	ON_DRAW,
	ON_CAST,
	ON_ENTER_BATTLEFIELD,
	ON_LEAVE_BATTLEFIELD,
	TRUE,  # Always active/activatable
	SELECTED_ON_HAND,
	SELECTED_ON_MANA,
	ON_STACK_BUFF
}
const _MANA_COLORS = {
	"generic": Color(0.7, 0.7, 0.7),
	"white": Color(1, 1, 1),
	"black": Color(0.4, 0.4, 0.4),
	"green": Color(0.1, 0.8, 0.1),
	"blue": Color(0.1, 0.6, 1),
	"red": Color(1, 0.2, 0.2),
	"earth": Color(0.6, 0.4, 0.2)}
enum EffectTarget {
	SELF,
	PLAYER,
	CREATURE,
	ALL_CREATURES,
	CARD,
	SPELL,
	ENEMY_CREATURE,
	PLAYER_CREATURE,
	ANY,
	ZONE
}

# ============ EVENT ENUMS ============
enum GameEvent {
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
	ON_CARD_PLAYED,
	ON_DAMAGE_DEALT,
	ON_LIFE_CHANGE,
	ON_CARD_DRAWN,
	ON_CARD_DISCARDED
}

# ============ PLAYER ENUMS ============
enum PlayerType {
	HUMAN,
	AI_EASY,
	AI_MEDIUM,
	AI_HARD
}

# ============ TARGET ENUMS ============
enum TargetKind {
	ATTACK,
	EFFECT,
	MOVE
}

# ============ ZONE ENUMS ============
enum Zone {
	SLOT_1_1, SLOT_1_2, SLOT_1_3, SLOT_1_4, SLOT_1_5,
	SLOT_2_1, SLOT_2_2, SLOT_2_3, SLOT_2_4, SLOT_2_5,
	SLOT_3_1, SLOT_3_2, SLOT_3_3, SLOT_3_4, SLOT_3_5,
	SLOT_4_1, SLOT_4_2, SLOT_4_3, SLOT_4_4, SLOT_4_5,
	SLOT_5_1, SLOT_5_2, SLOT_5_3, SLOT_5_4, SLOT_5_5,
	SLOT_6_1, SLOT_6_2, SLOT_6_3, SLOT_6_4, SLOT_6_5
}

# ============ VISUAL ENUMS ============
enum VisualState {
	NORMAL,
	HOVERED,
	DRAGGING,
	TARGETING,
	SELECTED,
	DISABLED,
	DESTROYED
}

enum CardSide {
	FRONT,
	BACK,
	FLIPPING
}

# ============ HELPER FUNCTIONS ============
static func get_zone_name(zone: CardZone) -> String:
	match zone:
		CardZone.DECK: return "Deck"
		CardZone.HAND: return "Hand"
		CardZone.FIELD: return "Field"
		CardZone.GRAVEYARD: return "Graveyard"
		CardZone.MANA: return "Mana Pool"
		CardZone.EXILE: return "Exile"
		CardZone.STACK: return "Stack"
	return "Unknown"

static func get_phase_name(phase: TurnPhase) -> String:
	match phase:
		TurnPhase.UNTAP: return "Untap"
		TurnPhase.UPKEEP: return "Upkeep"
		TurnPhase.DRAW: return "Draw"
		TurnPhase.MAIN1: return "Main Phase 1"
		TurnPhase.BATTLE: return "Battle Phase"
		TurnPhase.END: return "End Phase"
		TurnPhase.CLEANUP: return "Cleanup"
	return "Unknown"

static func get_color_name(color: CardColor) -> String:
	match color:
		CardColor.GENERIC: return "generic"
		CardColor.WHITE: return "white"
		CardColor.BLUE: return "blue"
		CardColor.BLACK: return "black"
		CardColor.RED: return "red"
		CardColor.GREEN: return "green"
		CardColor.EARTH: return "earth"
	return "unknown"

static func get_color_enum(color_str: String) -> CardColor:
	match color_str.to_lower():
		"generic": return CardColor.GENERIC
		"white": return CardColor.WHITE
		"blue": return CardColor.BLUE
		"black": return CardColor.BLACK
		"red": return CardColor.RED
		"green": return CardColor.GREEN
		"earth": return CardColor.EARTH
	return CardColor.GENERIC
