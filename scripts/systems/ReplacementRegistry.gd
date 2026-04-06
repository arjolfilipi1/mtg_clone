extends Node
 
# Each entry: { "event": String, "handler": Callable, "source": CardState }
var _replacements: Array = []
 
# ---------- Registration ----------
 
func register(event_type: String, source: CardState, handler: Callable) -> void:
	_replacements.append({
		"event":   event_type,
		"source":  source,
		"handler": handler,
	})
 
func unregister_source(source: CardState) -> void:
	_replacements = _replacements.filter(func(r): return r.source != source)
 
# ---------- Application ----------
 
# Passes `event_data` through every active replacement for `event_type` in order.
# Each handler receives the dict and returns a (possibly modified) dict.
# Return value is the final, post-replacement event data.
func apply(event_type: String, event_data: Dictionary) -> Dictionary:
	var data = event_data.duplicate(true)
	for r in _replacements:
		if r.event == event_type:
			# Handler signature: func(data: Dictionary) -> Dictionary
			data = r.handler.call(data)
			# If a replacement sets "cancelled" = true, stop the chain
			if data.get("cancelled", false):
				break
	return data
 
# ---------- Convenience helpers ----------
 
