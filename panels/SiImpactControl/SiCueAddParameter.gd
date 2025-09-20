class_name SiCueAddParameter extends Window
## Dialog window to add a parameter to a cue


## Emitted when the cue is edited
signal cue_edited()


## The OptionButton for selecting an already used address
@export var address_option_button: OptionButton

## The LineEdit for setting a manual address
@export var manual_address_input: VDInput

## The OptionButton for selecting the PID DataType
@export var data_type_option: OptionButton

## The SpinBox for selecting the PID
@export var pid_spin_box: SpinBox

## The Add Button
@export var add_button: Button


## Current CueData
var _cue_data: CueData

## Current HiQNet Address
var _address: Array

## Current HiQNetHeader.DataType
var _data_type: HiQNetHeader.DataType

## Current PID
var _pid: int


## Ready
func _ready() -> void:
	for data_type: String in HiQNetHeader.DataType:
		data_type_option.add_item(data_type)


## Sets the CueData
func set_cue_data(p_cue_data: CueData) -> void:
	_cue_data = p_cue_data
	reset()
	
	for address: Array in _cue_data.data:
		address_option_button.add_item(HiQNetDevice.address_to_string(address))
	
	address_option_button.select(0)
	add_button.set_disabled(not is_valid())


## Returns true if all parameters are valid
func is_valid() -> bool:
	if len(_address) != 4 and _address.all(func (p_i): return p_i is int):
		return false
	elif _data_type == HiQNetHeader.DataType.NULL:
		return false
	elif _pid == 0:
		return false
	else:
		return true


## Resets all inputs
func reset() -> void:
	add_button.set_disabled(true)
	
	address_option_button.clear()
	address_option_button.add_separator("Address")


## Called when an item is selected in the address box
func _on_address_option_item_selected(p_index: int) -> void:
	_address = _cue_data.data.keys()[p_index - 1]
	manual_address_input.set_text(HiQNetDevice.address_to_string(_address))
	
	add_button.set_disabled(not is_valid())


## Called when the VD is changed in the manual address input
func _on_manual_address_input_text_changed(new_text: String) -> void:
	_address = manual_address_input.get_vd()
	address_option_button.select(0)
	
	add_button.set_disabled(not is_valid())


## Called when an item is selected in the DataTypeOption
func _on_data_type_option_item_selected(p_index: int) -> void:
	_data_type = p_index - 1
	
	add_button.set_disabled(not is_valid())


## Called when the PID value is changed
func _on_pid_value_changed(p_value: float) -> void:
	_pid = int(p_value)
	
	add_button.set_disabled(not is_valid())


## Called when the add button is pressed
func _on_add_pressed() -> void:
	var value: Variant 
	
	if _data_type == HiQNetHeader.DataType.STRING:
		value = ""
	else:
		value = 0
	
	_cue_data.data.get_or_add(_address, {})[_pid] = Parameter.new(_pid, _data_type, value)
	cue_edited.emit()
	hide()


## Called when the cancel button is pressed
func _on_cancel_pressed() -> void:
	hide()


## Called when a Window Manager close button is pressed
func _on_close_requested() -> void:
	hide()
