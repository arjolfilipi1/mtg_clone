extends Node
class_name Effect_Runner

func apply_effect(effect: Effect_class, ctx: Dictionary):
	var parsed = EffectParser.parse_spec(effect.spec)
	if parsed.is_empty():
		push_error("Cannot parse: %s" % effect.spec)
		return
		 # 1️⃣ Check if the effect needs targeting before activation
	
	var executor = EffectRegistry.executors.get(parsed.action)
	if executor == null:
		push_error("Unknown effect: %s" % parsed.action)
		return
	ctx.params = parsed.params
	print("running effect: ",ctx.params,ctx )
	executor.call(ctx)
