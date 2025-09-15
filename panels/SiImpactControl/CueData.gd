
class_name CueData extends Object
## Class to represent stored data in a Cue


## Stores all data { [address...]: { PID: HiQNetHeadder.Parameter} }
var data: Dictionary[Array, Dictionary]

## Init
func _init(p_data: Dictionary[Array, Dictionary] = {}) -> void:
	data = p_data


## Returns a seralized version of this CueData
func save() -> Dictionary:
	var result: Dictionary = {}
	
	for address: Array in data:
		result[address] = {}
		
		var parameters: Dictionary = data[address]
		for parameter: Parameter in parameters.values():
			result[address][parameter.id] = parameter.save()
	
	return result


## Loads a seralized version of a CueData
static func load(p_saved_data: Dictionary) -> CueData:
	var new_cue_data: CueData = CueData.new()
	
	for address: Variant in p_saved_data:
		if address is Array and len(address) == 4:
			new_cue_data.data[address] = {}
			
			for parameter: Variant in p_saved_data[address].values():
				if parameter is Dictionary:
					var new_parameter: Parameter = Parameter.new()
					new_parameter.load(parameter)
					new_cue_data.data[address][new_parameter.id] = new_parameter
	
	return new_cue_data


## Clears the data
func clear() -> void:
		data.clear()
