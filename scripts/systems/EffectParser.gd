extends Node
class_name EffectParser

func parse_spec(spec:String)->Dictionary:
	spec = spec.strip_edges()
	if spec.begins_with("{"):
		var result = JSON.parse_string(spec)
		return result if typeof(result) == TYPE_DICTIONARY else {}
	var parts = spec.split(" ")
	if parts.size() == 0:
		return {}
	var kw = parts[0]
	var params = {}
	if kw =="draw":
		params["n"] = int(parts[1]) if parts.size > 1 else 1
	return {"action":kw,"params":params}
