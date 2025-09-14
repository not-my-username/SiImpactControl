# Copyright (c) 2024 Liam Sherwin
# All rights reserved.

class_name SiControlPanel extends Control
## Base class for all UI panels in the SiImpactControl module


## The mixer object
var mixer: SiImpact

## This panels settings
var _settings: Dictionary = {}


## Registers a setting
func register_setting(p_classname: String, p_key: String, p_setter: Callable, p_getter: Callable, p_signal: Signal, p_type: int, p_visual_line: int, p_visual_name: String, p_min: Variant = null, p_max: Variant = null) -> void:
	_settings.get_or_add(p_classname, {})[p_key] = {
			"setter": p_setter,
			"getter": p_getter,
			"signal": p_signal,
			"data_type": p_type,
			"visual_line": p_visual_line,
			"visual_name": p_visual_name,
			"min": p_min,
			"max": p_max
	}


## Registers a custom setting panel
func register_custom_panel(p_classname: String, p_key: String, p_entry_point: String, p_custom_panel: PackedScene) -> void:
	_settings.get_or_add(p_classname, {})[p_key] = {
			"data_type": TYPE_OBJECT,
			"entry_point": p_entry_point,
			"custom_panel": p_custom_panel
	}


## Gets the settings for the given class
func get_settings() -> Dictionary:
	return _settings.duplicate()


## Saves this SiControlPanel into a dictionary
func save() -> Dictionary:
	return {}


## Loads this SiControlPanel from dictionary
func load(saved_data: Dictionary):
	pass


## Resets this SiControlPanel to default settings
func reset() -> void:
	pass
