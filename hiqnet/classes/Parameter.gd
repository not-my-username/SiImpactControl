class_name Parameter extends Object
## Class to repersent a parameter on a device


## Parameter ID
var id: int = 0

## DataType of the value
var data_type: HiQNetHeader.DataType = HiQNetHeader.DataType.BYTE

## The value
var value: Variant = 0


## Init
func _init(p_id: int = id, p_data_type: HiQNetHeader.DataType = data_type, p_value: Variant = value) -> void:
	id = p_id
	data_type = p_data_type
	value = p_value


## Converts this Parameter into a string for printing
func _to_string() -> String:
	return str("Parameter(", id, ", ",  HiQNetHeader.DataType.keys()[data_type], ", ", value, ")")


## Returns a new copy of this Parameter
func duplicate() -> Parameter:
	return Parameter.new(id, data_type, value)


## Returns a seralized version of this Parameter
func save() -> Dictionary:
	return {
		"id": id,
		"data_type": data_type,
		"value": value
	}


## Loads a seralized version of a Parameter
func load(p_saved_data: Dictionary) -> void:
	id = type_convert(p_saved_data.get("id", id), TYPE_INT)
	data_type = type_convert(p_saved_data.get("data_type", id), TYPE_INT)
	value = p_saved_data.get("value", value)
