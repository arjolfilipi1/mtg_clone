extends Node
class_name Effect_Runner
 
# ── Public entry points ─────────────────────────────────────────────────────────
 
# Called by CardState.apply_effect for triggered abilities (on_death, on_attack, etc.)
# These go ON the stack — both players get priority before they resolve.
func trigger_effect(effect: Effect_class, base_ctx: Dictionary) -> void:
	if effect.actions.is_empty():
		push_error("EffectRunner: effect '%s' has no actions" % effect.description)
		return
	if effect.once_per_turn != "" and effect.used_this_turn:
		return
	effect.used_this_turn = true
 
	var entry := StackEntry.new(
		effect,
		base_ctx.source,
		base_ctx.controller,
		[],           # targets resolved at resolution time, not now
		"triggered",
		false         # triggered abilities are not counterable by default
	)
	PriorityManager.push(entry)
 
# Called for activated abilities and spells played from hand.
# These ARE counterable.
func activate_effect(effect: Effect_class, base_ctx: Dictionary) -> void:
	if effect.actions.is_empty():
		push_error("EffectRunner: effect '%s' has no actions" % effect.description)
		return
	if effect.once_per_turn != "" and effect.used_this_turn:
		return
	effect.used_this_turn = true
 
	var entry := StackEntry.new(
		effect,
		base_ctx.source,
		base_ctx.controller,
		[],
		"activated",
		true          # activated abilities ARE counterable
	)
	PriorityManager.push(entry)
 
# ── Resolution (called by PriorityManager._resolve_top only) ───────────────────
# This is the same execution logic you already have — unchanged.
func apply_effect(effect: Effect_class, base_ctx: Dictionary) -> void:
	print(base_ctx)
	if effect.actions.is_empty():
		push_error("EffectRunner: effect '%s' has no actions" % effect.description)
		return
 
	for action in effect.actions:
		var action_type: String = action.get("type", "")
		var executor = EffectRegistry.executors.get(action_type)
		if executor == null:
			push_error("EffectRunner: unknown action type '%s'" % action_type)
			continue
 
		var target_str: String = action.get("target", "none")
		var ctx := base_ctx.duplicate()
		ctx["filter"] = action.get("filter", {})
 
		# If PriorityManager pre-locked targets (from targeting during cast), use them
		if base_ctx.has("locked_targets") and not base_ctx.locked_targets.is_empty():
			ctx["targets"] = base_ctx.locked_targets
		else:
			# Resolve candidates the same way you already do
			var candidates: Array = EffectRegistry.resolve_targets(target_str, ctx)
 
			var needs_selection: bool = (
				target_str != "self"
				and target_str != "none"
				and not target_str.begins_with("target_all")
				and target_str != "player"
				and target_str != "enemy"
				and target_str != "target_in_range"
			)
			if needs_selection and candidates.size() > 1:
				var count: int = effect.target_count
				var chosen = await base_ctx.controller.request_target_selection(candidates, count)
				if chosen == null or chosen.is_empty():
					push_warning("EffectRunner: no targets chosen for '%s', skipping" % action_type)
					continue
				ctx["targets"] = chosen
			else:
				ctx["targets"] = candidates
 
		# Run replacement layer before executing damage/draw actions
		ctx = _apply_replacements(action_type, ctx)
		if ctx.get("cancelled", false):
			continue
 
		await executor.call(action, ctx)
 
# ── Replacement layer ──────────────────────────────────────────────────────────
 
func _apply_replacements(action_type: String, ctx: Dictionary) -> Dictionary:
	# Map action types to replacement event names
	var event_map := {
		"damage": "damage",
		"draw":   "draw",
	}
	var event = event_map.get(action_type, "")
	if event == "":
		return ctx   # no replacement layer for this action type
 
	# Build a flat event_data dict for ReplacementRegistry
	var event_data := ctx.duplicate(true)
	event_data["event"] = event
 
	var result = ReplacementRegistry.apply(event, event_data)
	return result
