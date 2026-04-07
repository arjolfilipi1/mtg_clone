extends Node
 
# ── Signals ────────────────────────────────────────────────────────────────────
signal entry_pushed(entry: StackEntry)       # UI: add entry to stack display
signal entry_resolved(entry: StackEntry)     # UI: remove entry from stack display
signal priority_changed(player_index: int)   # UI: show whose priority it is
signal stack_empty                           # TurnManager: may advance phase
 
# ── State ──────────────────────────────────────────────────────────────────────
var stack: Array[StackEntry] = []
 
# 0 = active player (human), 1 = opponent (AI)
var priority_holder: int = 0
 
# Tracks whether each side passed consecutively.
# Reset to [false, false] whenever anything is pushed.
var _passed: Array[bool] = [false, false]
 
# Prevents re-entrant resolution
var _resolving: bool = false
 
# Reference set by GameManager after setup
var _active_player   # Player
var _opponent        # Player  (AI)
 
# ── Public API ─────────────────────────────────────────────────────────────────
 
func setup(active: Player, opponent:Player) -> void:
	_active_player = active
	_opponent      = opponent
 
# Push a new entry onto the stack from anywhere in the codebase.
func push(entry: StackEntry) -> void:
	stack.append(entry)
	_passed = [false, false]          # reset pass state — both get to respond
	entry_pushed.emit(entry)
	_give_priority(priority_holder)   # active player gets priority again
 
# Either player calls this when they want to do nothing.
func pass_priority() -> void:
	_passed[priority_holder] = true

	# Both passed consecutively → resolve or clear
	if _passed[0] and _passed[1]:
		if stack.is_empty():
			stack_empty.emit()
		else:
			await _resolve_top()
	else:
		# Flip priority to the other player
		_give_priority(1 - priority_holder)

# Counter the top-most counterable entry (used by counterspell actions).
func counter_top() -> void:
	if stack.is_empty():
		return
	var top: StackEntry = stack.back()
	if not top.is_counterable:
		push_warning("PriorityManager: tried to counter an uncounterable effect")
		return
	stack.pop_back()
	entry_resolved.emit(top)          # UI removes it
	_passed = [false, false]
	_give_priority(priority_holder)

# Convenience: push a triggered ability straight from game event code.
# Returns immediately; the stack handles timing.
func push_triggered(
	effect: Effect_class,
	source: CardState,
	controller,
	targets: Array = []
) -> void:
	var entry := StackEntry.new(effect, source, controller, targets, "triggered", false)
	push(entry)

# Convenience: push a spell or activated ability (counterable).
func push_spell(
	effect: Effect_class,
	source: CardState,
	controller,
	targets: Array = []
) -> void:
	var entry := StackEntry.new(effect, source, controller, targets, "spell", true)
	push(entry)

# ── Internal ───────────────────────────────────────────────────────────────────
 
func _give_priority(player_index: int) -> void:
	priority_holder = player_index
	priority_changed.emit(player_index)

	# If it's the AI's turn with priority, let it decide asynchronously
	if player_index == 1:
		await _ai_priority_decision()
 
func _resolve_top() -> void:
	if _resolving or stack.is_empty():
		return
	_resolving = true

	var entry: StackEntry = stack.pop_back()
	entry_resolved.emit(entry)

	# Build the base context your existing EffectRunner expects
	var ctx := {
		"game":       Game_Manager.gamestate,
		"source":     entry.source,
		"controller": entry.controller,
	}

	# If targets were pre-locked at push time, inject them directly.
	# EffectRunner will still do per-action target resolution for "self", "all", etc.
	if not entry.targets.is_empty():
		ctx["locked_targets"] = entry.targets

	await EffectRunner.apply_effect(entry.effect, ctx)

	_resolving = false
	_passed = [false, false]

	# After resolution, active player gets priority again
	_give_priority(0)

	# If stack is now empty and both pass immediately after, emit stack_empty
	# (TurnManager listens to this signal to advance phases)

# ── AI Priority Decision ───────────────────────────────────────────────────────
# Keep this simple for now: the AI passes unless it has an instant/fast effect
# it wants to play. Expand this as you build the AI brain.
 
func _ai_priority_decision() -> void:
	# Small delay so it doesn't feel instant
	await get_tree().create_timer(0.6).timeout

	var response = _find_ai_response()
	if response != null:
		push(response)
	else:
		pass_priority()

func _find_ai_response() -> StackEntry:
	# Stub: iterate AI hand looking for instants / fast effects
	# Return a StackEntry if the AI wants to respond, otherwise null.
	#
	# Example skeleton — replace with real AI logic:
	#
	# for card_state in Game_Manager.gamestate.enemy_hand:
	#     for eff in card_state.effects:
	#         if eff.trigger_spec.get("speed", 0) >= 2:   # speed 2 = instant
	#             if _ai_should_respond(eff, stack):
	#                 var entry = StackEntry.new(eff, card_state, _opponent, [], "spell", true)
	#                 return entry
	return null
