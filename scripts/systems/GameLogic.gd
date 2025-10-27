extends RefCounted
class_name GameLogic

static func on_card_event(event_name: int, source: CardState, target: CardState, game: GameState):
	for c in game.all_cards():
		for eff:Effect_class in c.effects:
			match eff.trigger_spec:
				"on_attack":
					if event_name == Card_event.e.ON_ATTACK and c == source:
						_push_trigger(eff, source, target, game)
				"on_death":
					if event_name == Card_event.e.ON_DEATH and c == source:
						_push_trigger(eff, source, target, game)
				"on_destruction":
					if event_name == Card_event.e.ON_DESTRUCTION and c == source:
						_push_trigger(eff, source, target, game)
				"on_kill":
					if event_name == Card_event.e.ON_KILL and c == source:
						_push_trigger(eff, source, target, game)
						
static func _push_trigger(effect: Effect_class, source: CardState, target: CardState, game: GameState):
	var ctx = {
	"game": game,
	"controller": source.controller,
	"source": source,
	"targets": [target]
	}
	game.stack.append({
	"effect": effect,
	"source": source,
	"controller": source.controller,
	"context": ctx
 })
