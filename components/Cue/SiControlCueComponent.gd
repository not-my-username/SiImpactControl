# Copyright (c) 2024 Liam Sherwin
# All rights reserved.

class_name SiControlCueComponent extends Control
## UI compinent for cues in the SiImpactControl module


## Emitted when this cue is clicked
signal clicked()

## Emitted when this cue is right clicked
signal right_clicked()

## Emitted when this cue is double clicked
signal activated() 

## Emitted when the user changed the cue name
signal cue_name_changed(new_name: String)

## Emitted when the cue number is changed
signal cue_number_changed(new_number: int)


## The selected border color
@export var selected_border_color: Color = Color.WHITE

## The active background color
@export var active_bg_color: Color = Color.WEB_GREEN


## Stored cue data
var data: SiCuesControl.CueData


## The stylebox for this cue item
var _stylebox: StyleBoxFlat

## The color of this cue
var _color: Color 

## The stylebox for this cue item number
var _number_stylebox: StyleBoxFlat

## The stylebox for this cue item name
var _name_stylebox: StyleBoxFlat

## The default border color
var _default_border_color: Color

## The default background color
var _default_background_color: Color

## Default bg color for the tags
var _default_tag_bg_color: Color

## The cue number
var _number: int = 0

## The cue name
var _cue_name: String = ""


func _ready() -> void:
	_stylebox = get_theme_stylebox("panel").duplicate()
	add_theme_stylebox_override("panel", _stylebox)
	
	_number_stylebox = $HBoxContainer/Number.get_theme_stylebox("panel").duplicate()
	$HBoxContainer/Number.add_theme_stylebox_override("panel", _number_stylebox)
	
	_name_stylebox = $HBoxContainer/Name.get_theme_stylebox("panel").duplicate()
	$HBoxContainer/Name.add_theme_stylebox_override("panel", _name_stylebox)
	
	_default_border_color = _stylebox.border_color
	_default_background_color = _stylebox.bg_color
	_default_tag_bg_color = _name_stylebox.bg_color
	
	set_color(_color)


## Sets the selected state of this cue
func set_selected(selected: bool) -> void:
	_stylebox.border_color = selected_border_color if selected else _default_border_color


## Sets the active state of this cue
func set_active(active: bool) -> void:
	_stylebox.bg_color = active_bg_color if active else _default_background_color


## Sets the cue number
func set_number(number: int) -> void:
	var str_number: String = str(number)
	
	if number < 10:
		str_number = "0" + str_number
	
	$HBoxContainer/Number/CueNumber.text = str_number
	$HBoxContainer/Number/NumberEdit.text = str(number)
	_number = number


## Gets the cue number
func get_number() -> int:
	return _number


## Sets the cue name
func set_cue_name(cue_name: String) -> void:
	$HBoxContainer/Name/CueName.text = cue_name
	$HBoxContainer/Name/NameEdit.text = cue_name
	_cue_name = cue_name


## Sets the color of this cue
func set_color(color: Color) -> void:
	if not is_node_ready():
		_color = color
		return
	
	if color == Color.TRANSPARENT:
		_color = Color.TRANSPARENT
		
		_number_stylebox.bg_color = _default_tag_bg_color
		_name_stylebox.bg_color = _default_tag_bg_color
	else:
		_color = color
		
		_number_stylebox.bg_color = _color
		_name_stylebox.bg_color = _color


## Gets the cue name
func get_cue_name() -> String:
	return _cue_name


## Serializes this cue into a dictionary
func serialize() -> Dictionary:
	return {
		"number": _number,
		"name": _cue_name,
		"color": _color,
		"data": data.data
	}


## Called when GUI input is recieved
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.double_click:
					activated.emit()
				else:
					clicked.emit()
			
			MOUSE_BUTTON_RIGHT:
				right_clicked.emit()


## Called when GUI input is recieved on the CueName label
func _on_cue_name_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		$HBoxContainer/Name/CueName.hide()
		$HBoxContainer/Name/NameEdit.show()
		$HBoxContainer/Name/NameEdit.grab_focus()


## Called when text is submitted on the NameEdit
func _on_name_edit_text_submitted(new_text: String) -> void:
	$HBoxContainer/Name/CueName.show()
	$HBoxContainer/Name/NameEdit.hide()
	
	set_cue_name(new_text)
	cue_name_changed.emit(new_text)


## Called when focus is lost on the NameEdit
func _on_name_edit_focus_exited() -> void:
	$HBoxContainer/Name/CueName.show()
	$HBoxContainer/Name/NameEdit.hide()
	$HBoxContainer/Name/NameEdit.text = _cue_name


## Called when GUI input is recieved on the CueNumber label
func _on_cue_number_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		$HBoxContainer/Number/CueNumber.hide()
		$HBoxContainer/Number/NumberEdit.show()
		$HBoxContainer/Number/NumberEdit.grab_focus()


## Called when text is submitted on the NumberEdit
func _on_number_edit_text_submitted(new_text: String) -> void:
	$HBoxContainer/Number/CueNumber.show()
	$HBoxContainer/Number/NumberEdit.hide()
	
	cue_number_changed.emit(int(new_text))


## Called when focus is lost on the NumberEdit
func _on_number_edit_focus_exited() -> void:
	$HBoxContainer/Number/CueNumber.show()
	$HBoxContainer/Number/NumberEdit.hide()
	$HBoxContainer/Number/NumberEdit.text = str(_number)
