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
	elif kw =="damage":
		params["ammount"] = int(parts[2]) if parts.size > 2 else int(parts[1])
	elif kw =="buff":
		var buff_str = parts[2]
		var nums = buff_str.lstrip("+").split("/")
		params["power"] = int(nums[0])
		params["toughtness"] = int(nums[1])
		params["duration"] = parts[-1] if "until" in parts[-1] else "instant"
	return {"action":kw,"params":params}
