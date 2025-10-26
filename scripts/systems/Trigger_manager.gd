# Trigger_Manager.gd
extends Node
class_name TriggerManager

func on_card_event(event_name: String, card: CardState, game: GameState):
	for c in game.all_cards():
		for eff in c.effect:
			if eff.trigger == event_name:
				var ctx = {
					"game": game,
					"controller": c.controller,
					"source": c,
					"targets": eff.get_potential_targets(game)
				}
				game.push_to_stack({
					"effect": eff,
					"source": c,
					"controller": c.controller,
					"context": ctx
				})
