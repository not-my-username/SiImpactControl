# Copyright (c) 2024 Liam Sherwin
# All rights reserved.

class_name SiAutoCreateCuesDialogComponent extends Window
## Component for auto adding cues


## Called when the create button is pressed
signal confirmed(cues: Dictionary[int, Dictionary])


## The TextEdit
@export var _text_edit: TextEdit

## The Tree
@export var _tree: Tree

## The CreateButton
@export var _create_button: Button

## The LoadTimer
@export var _load_timer: Timer

## The VD input
@export var _address_input: VDInput

## The PidFrom SpinBox
@export var _pid_from_input: SpinBox

## The PidFrom SpinBox
@export var _pid_to_input: SpinBox


## Current cues
var _cues: Dictionary[int, Dictionary]

## PID range
var _pid_range: Array[int] = [0, 0]


## Sets the cue name column
func _ready() -> void:
	_tree.set_column_title(0, "Index")
	_tree.set_column_title(1, "Cue Name")


## Loads the inputted data into the tree
func _load_to_tree() -> void:
	_cues = _convert_to_cues(_text_edit.text)
	
	_tree.clear()
	_tree.create_item()
	
	var pid_range: Array = range(_pid_range[0], _pid_range[1] + 1)
	_tree.columns = len(pid_range) + 2
	
	for cue_number: int in _cues.keys():
		var cue_item: TreeItem = _tree.create_item()
		cue_item.set_text(0, str(cue_number))
		cue_item.set_text(1, _cues[cue_number].name)
		
		for pid: int in pid_range:
			var column: int = pid_range.find(pid) + 2
			
			cue_item.set_cell_mode(column, TreeItem.CELL_MODE_CHECK)
			cue_item.set_checked(column, true if pid in _cues[cue_number].pids else false)
			
			_tree.set_column_title(column, str(pid))
			_tree.set_column_expand(column, false)


## Converts text from a spreadsheet into cues
func _convert_to_cues(text: String) -> Dictionary[int, Dictionary]:
	var lines: PackedStringArray = text.split("\n", false)
	var cues: Dictionary[int, Dictionary]
	
	for line: String in lines:
		var split: Array = line.split("\t", false)
		var pids: Array[int] = []
		
		if len(split) >= 2:
			
			cues[int(split[0])] = {
				"name": str(split[1]),
				"pids": pids
			}
		
		if len(split) >= 3:
			for pid: String in split[2].split(",", false):
				pids.append(int(pid))
	
	return cues


## Called when text is changed in the TextEdit
func _on_text_edit_text_changed() -> void:
	_create_button.disabled = _text_edit.text == ""
	_load_timer.wait_time = 1
	_load_timer.start()


## Called when the cancel button is pressed
func _on_cancel_button_pressed() -> void:
	_text_edit.clear()
	hide()


## Called when the create button is pressed
func _on_create_button_pressed() -> void:
	confirmed.emit(_cues, _address_input.get_vd(), [_pid_from_input.value, _pid_to_input.value])
	_text_edit.clear()
	hide()


## Called when the window close button is pressed
func _on_close_requested() -> void:
	hide()


## Timer for loading the data
func _on_load_timer_timeout() -> void:
	_load_to_tree()


## Called when the value is changed in the PIDFrom SpinBox
func _on_pid_range_from_value_changed(value: float) -> void:
	_pid_range = [int(value), int(_pid_to_input.value)]
	_load_to_tree()


## Called when the value is changed in the PIDTo SpinBox
func _on_pid_range_to_value_changed(value: float) -> void:
	_pid_range = [int(_pid_from_input.value), int(value)]
	_load_to_tree()
