# Copyright (c) 2024 Liam Sherwin, All rights reserved.
# This file is part of the Spectrum Lighting Engine, licensed under the GPL v3.

class_name RefMap extends RefCounted
## A bidirectional mapping class for two-way key-value relationships.


## Dictonary repsenting the normal mapping
var _left: Dictionary = {}

## Dictionary representing the flipped mapping
var _right: Dictionary = {}


## Maps 2 items, returning false if the map failed
func map(p_left: Variant, p_right: Variant) -> void:
	_left[p_left] = p_right
	_right[p_right] = p_left


## Creates a new RefMap from a Dictionary
static func from(p_dictionary: Dictionary) -> RefMap:
	var ref_map: RefMap = RefMap.new()

	for key: Variant in p_dictionary:
		ref_map.map(key, p_dictionary[key])

	return ref_map


## Gets an item from the map using the left key
func left(p_key: Variant) -> Variant:
	return _left.get(p_key, null)


## Gets an item from the map using the right key
func right(p_key: Variant) -> Variant:
	return _right.get(p_key, null)


## Erases an item from the map using the left key
func erase_left(p_key: Variant) -> void:
	var p_right: Variant = left(p_key)
	_right.erase(p_right)
	_left.erase(p_key)


## Erases an item from the map using the right key
func erase_right(p_key: Variant) -> void:
	var p_left: Variant = right(p_key)
	_left.erase(p_left)
	_right.erase(p_key)


## Returns all left keys
func get_left() -> Array:
	return _left.keys()


## Returns all the right keys
func get_right() -> Array:
	return _right.keys()


## Checks if the left side has a variant
func has_left(p_variant: Variant) -> bool:
	return _left.has(p_variant)


## Checks if the left side has a variant
func has_right(p_variant: Variant) -> bool:
	return _right.has(p_variant)


## Gets this RefMap as a dictonary
func get_as_dict() -> Dictionary:
	return _left.duplicate()


## Clears the RefMap
func clear() -> void:
	_left.clear()
	_right.clear()


func _to_string() -> String:
	return str(_left)
