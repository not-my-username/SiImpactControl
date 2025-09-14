# Copyright (c) 2024 Liam Sherwin, All rights reserved.

class_name SiPanelSettingsModule extends PanelContainer
## Class settings module


## Title label
@export var _title: Label

## ExpandHide button
@export var _expand_hide_button: Button

## SettingsContainer VBox
@export var _settings_container: VBoxContainer

## CustomContainer VBox
@export var _custom_container: VBoxContainer


## Contains all the lines of settings
var _lines: Dictionary = {}


## Disables this settings module
func set_disable(state: bool) -> void:
	_on_expand_hide_toggled(state)
	_expand_hide_button.disabled = state


## Sets the title
func set_title(title: String) -> void:
	_title.text = title


## Shows a custom panel
func show_custom(panel: Control) -> void:
	_custom_container.add_child(panel)


## Shows a setting
func show_setting(setter: Callable, getter: Callable, p_signal: Signal, type: int, line_number: int, p_name: String, p_min: Variant = null, p_max: Variant = null) -> void:
	if not _lines.has(line_number):
		var new_line: HBoxContainer = HBoxContainer.new()
		_lines[line_number] = new_line
		
		_settings_container.add_child(new_line)
		_settings_container.move_child(new_line, line_number + 1)
	
	var line: HBoxContainer = _lines[line_number]
	var control: Control = null
	
	match type:
		TYPE_STRING:
			var line_edit: LineEdit = LineEdit.new()
			line_edit.text = getter.call()
			
			line_edit.text_submitted.connect(setter)
			p_signal.connect(line_edit.set_text)
			control = line_edit
			
		TYPE_BOOL:
			var check_button: CheckButton = CheckButton.new()
			check_button.set_pressed_no_signal(getter.call())
			check_button.text = "TRUE" if check_button.button_pressed else "FALSE"
			
			check_button.toggled.connect(setter)
			p_signal.connect(func (state: bool):
				check_button.set_pressed_no_signal(state)
				check_button.text = "TRUE" if state else "FALSE"
			)
			control = check_button
		
		TYPE_INT:
			var spin_box: SpinBox = SpinBox.new()
			spin_box.min_value = p_min if p_min != null else -(1 << 32)
			spin_box.max_value = p_max if p_max != null else 1 << 32
			spin_box.set_value_no_signal(getter.call())
			
			spin_box.value_changed.connect(setter)
			p_signal.connect(spin_box.set_value_no_signal)
			control = spin_box
		
		TYPE_FLOAT:
			var spin_box: SpinBox = SpinBox.new()
			spin_box.min_value = p_min if p_min != null else -(1 << 32)
			spin_box.max_value = p_max if p_max != null else 1 << 32
			spin_box.set_value_no_signal(getter.call())
			spin_box.step = 0.1
			
			spin_box.value_changed.connect(setter)
			p_signal.connect(spin_box.set_value_no_signal)
			control = spin_box
		
		TYPE_NIL:
			if getter.is_null():
				var button: Button = Button.new()
				button.text = p_name
				
				button.pressed.connect(setter)
				control = button
		
		
	if true:
		if not getter.is_null():
			var hbox: HBoxContainer = HBoxContainer.new()
			var label: Label = Label.new()
			
			label.text = p_name
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			hbox.add_child(label)
			hbox.add_child(control)
			line.add_child(hbox)
		
		else:
			control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(control)


## Called when the ExpandHide button is toggled
func _on_expand_hide_toggled(toggled_on: bool) -> void:
	_settings_container.visible = not toggled_on
	_expand_hide_button.icon = preload("res://assets/icons/UnfoldMore.svg") if toggled_on else preload("res://assets/icons/UnfoldLess.svg") 
