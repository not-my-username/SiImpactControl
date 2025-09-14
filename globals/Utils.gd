# Copyright (c) 2024 Liam Sherwin, All rights reserved.

class_name Utils extends Object
## Usefull function that would be annoying to write out each time


## Contains all the bound signal connections from connect_signals_with_bind()
##	{
##		Object: {
##			Signal: {
##				"CallableName + Callable.get_object_id()": Callable
##			}
##		}
##	}
static var _signal_connections: Dictionary


## Custom Types:
const TYPE_STRING := "STRING"
const TYPE_IP := "IP"
const TYPE_BOOL := "BOOL"
const TYPE_INT := "INT"
const TYPE_NULL := "NULL"
const TYPE_CUSTOM := "CUSTOM"


## Saves a JSON valid dictonary to a file, creates the file and folder if it does not exist
static func save_json_to_file(file_path: String, file_name: String, json: Dictionary, use_var_to_str: bool = false) -> Error:
	
	if not DirAccess.dir_exists_absolute(file_path):
		print("The folder \"" + file_path + "\" does not exist, creating one now, errcode: ", DirAccess.make_dir_absolute(file_path))

	var file_access: FileAccess = FileAccess.open(file_path+"/"+file_name, FileAccess.WRITE)
	
	if FileAccess.get_open_error():
		return FileAccess.get_open_error()
	
	if use_var_to_str:
		file_access.store_string(var_to_str(json))
	else:
		file_access.store_string(JSON.stringify(json, "\t"))
	
	file_access.close()
	
	return file_access.get_error()


## Calculates the HTP value of two colors
static func get_htp_color(color_1: Color, color_2: Color) -> Color:
	# Calculate the intensity of each channel for color1
	var intensity_1_r = color_1.r
	var intensity_1_g = color_1.g
	var intensity_1_b = color_1.b

	# Calculate the intensity of each channel for color2
	var intensity_2_r = color_2.r
	var intensity_2_g = color_2.g
	var intensity_2_b = color_2.b

	# Compare the intensities for each channel and return the color with the higher intensity for each channel
	var result_color = Color()
	result_color.r = intensity_1_r if intensity_1_r > intensity_2_r else intensity_2_r
	result_color.g = intensity_1_g if intensity_1_g > intensity_2_g else intensity_2_g
	result_color.b = intensity_1_b if intensity_1_b > intensity_2_b else intensity_2_b
	
	return result_color


## Gets the most common variant in an array
static func get_most_common_value(arr: Array) -> Variant:
	var count_dict := {}
	
	# Count the occurrences of each value
	for value in arr:
		if value in count_dict:
			count_dict[value] += 1
		else:
			count_dict[value] = 1
	
	# Find the most common value
	var most_common_value = null
	var max_count = 0
	
	for key in count_dict:
		if count_dict[key] > max_count:
			max_count = count_dict[key]
			most_common_value = key
	
	return most_common_value


## Sums all items in an array
static func sum_array(array: Array) -> Variant:
	var sum: Variant = 0
	
	for element: Variant in array:
		sum += element
	
	return sum


## Sorts all the text in an array
static func sort_text(arr: Array) -> Array:
	arr.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
	return arr


## Sorts all the text in an array, with numbers
static func sort_text_and_numbers(arr: Array) -> Array:
	arr.sort_custom(func(a, b): return _split_sort_key(a) < _split_sort_key(b))
	return arr


## Helper function for sort_text_and_numbers
static func _split_sort_key(s: String) -> Array:
	var regex = RegEx.new()
	regex.compile(r"\d+|\D+")
	
	var parts = []
	for match in regex.search_all(s):
		var sub = match.get_string()
		parts.append(int(sub) if sub.is_valid_int() else sub)
	
	return parts


## Moves an item to the start of an array
static func array_move_to_start(arr: Array, item) -> Array:
	var i = arr.find(item)
	if i > 0:  # Ensures "root" is found and isn't already at index 0
		arr.remove_at(i)
		arr.insert(0, item)
	return arr


## Connects all the callables to the signals in the dictionary. Stored as {"SignalName": Callable}
static func connect_signals(signals: Dictionary, object: Object) -> void:
	if is_instance_valid(object):
		for signal_name: String in signals:
			if object.has_signal(signal_name) and not (object.get(signal_name) as Signal).is_connected(signals[signal_name]):
				(object.get(signal_name) as Signal).connect(signals[signal_name])


## Disconnects all the callables from the signals in the dictionary. Stored as {"SignalName": Callable}
static func disconnect_signals(signals: Dictionary, object: Object) -> void:
	if is_instance_valid(object):
		for signal_name: String in signals:
			if object.has_signal(signal_name) and (object.get(signal_name) as Signal).is_connected(signals[signal_name]):
				(object.get(signal_name) as Signal).disconnect(signals[signal_name])


## Connects all the callables to the signals in the dictionary. Also binds the object to the callable. Stored as {"SignalName": Callable}
static func connect_signals_with_bind(signals: Dictionary, object: Object) -> void:
	_signal_connections.get_or_add(object, {})
	
	for signal_name: String in signals:
		if object.has_signal(signal_name):
			var _signal: Signal = object.get(signal_name)
			var connections: Dictionary = _signal_connections[object].get_or_add(_signal, {})
			var bound_callable: Callable = signals[signal_name].bind(object)
			var callable_name: String = bound_callable.get_method() + str(bound_callable.get_object_id())
			
			_signal.connect(bound_callable)
			connections[callable_name] = bound_callable


## Disconnects all the bound callables from the signals in the dictionary. Stored as {"SignalName": Callable}
static func disconnect_signals_with_bind(signals: Dictionary, object: Object) -> void:
	if not _signal_connections.has(object):
		return
	
	for signal_name: String in signals:
		if object.has_signal(signal_name):
			var _signal: Signal = object.get(signal_name)
			var connections: Dictionary = _signal_connections[object].get_or_add(_signal, {})
			var orignal_callable: Callable = signals[signal_name]
			var callable_name: String = orignal_callable.get_method() + str(orignal_callable.get_object_id())
			var bound_callable: Callable = connections[callable_name]
			
			_signal.disconnect(bound_callable)
			connections.erase(callable_name)


## Disconnects all connections from a given signal
static func disconnect_all_signal_connections(p_signal: Signal) -> void:
	for connection: Dictionary in p_signal.get_connections():
		p_signal.disconnect(connection.callable)


## Define a function to create a TCP packet
static func create_packet(data_array: Array) -> PackedByteArray:
  
	var packet: PackedByteArray = PackedByteArray()
	
	# Convert each number in the array to bytes and add to the packet
	for number in data_array:
		packet.append_array(convert_to_bytes(number))

	return packet


## Convert an integer to bytes (you can adjust for different formats)
static func convert_to_bytes(value: int, byte_order: String = "big", size: int = 1) -> PackedByteArray:
  
	var byte_array: PackedByteArray = PackedByteArray()
	
	# Handle different integer sizes
	match size:
		1:
			byte_array.append(value & 0xFF)
		2:
			byte_array.append((value >> 8) & 0xFF)
			byte_array.append(value & 0xFF)
		4:
			byte_array.append((value >> 24) & 0xFF)
			byte_array.append((value >> 16) & 0xFF)
			byte_array.append((value >> 8) & 0xFF)
			byte_array.append(value & 0xFF)
		_:
			push_error("Unsupported size: %d" % size)
	
	# Reverse byte array if little-endian is specified
	if byte_order == "little":
		byte_array.reverse()
	
	return byte_array


## Returns the broadcast address as a PackedByteArray
static func get_broadcast(ip: PackedByteArray, prefix_len: int) -> PackedByteArray:
	## Step 1: convert to 32-bit int
	var ip_u32 := (ip[0] << 24) | (ip[1] << 16) | (ip[2] << 8) | ip[3]
	
	## Step 2: build netmask from prefix
	var netmask: int = 0
	if prefix_len > 0:
		netmask = (0xFFFFFFFF << (32 - prefix_len)) & 0xFFFFFFFF
	
	## Step 3: broadcast = ip | (~netmask)
	var broadcast_u32 := ip_u32 | (~netmask & 0xFFFFFFFF)
	
	## Step 4: convert back to bytes
	var broadcast := PackedByteArray([
		(broadcast_u32 >> 24) & 0xFF,
		(broadcast_u32 >> 16) & 0xFF,
		(broadcast_u32 >> 8) & 0xFF,
		broadcast_u32 & 0xFF
	])
	
	return broadcast
