# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# See the LICENSE file for details.

class_name SiCuesEdit extends SiControlPanel
## 


## Enum for display modes
enum DisplayMode {
	Raw,			## Display each parameter as its raw value
	CheckBox,		## Displays each parameter as a 1 or 0 boolen checkbox
	Decibel,		## Displays each parameter as a logarithmic fader from +10dB to -138dB
}


## The SiCuesControl panel
@export var cues_control: SiCuesControl


@export_group("Nodes")

## The main Tree node to display the table
@export var tree: Tree

## The NoCueSelected Label
@export var no_cue_selected_label: Label

## The FollowActive button to set follow active state
@export var follow_active_button: Button

## The SpinBox for setting active cue number
@export var cue_number_spinbox: SpinBox

## The OptionButton for setting the address filter
@export var address_filter_option: OptionButton

## The OptionButton for setting the display mode
@export var display_mode_option: OptionButton

## The Button to add an HiQNet address entry into the CueData
@export var add_address_button: Button

## The Button to add a HiQNet Parameter entry into the CueData
@export var add_parameter_button: Button

## The OptionButton for setting the cell data type
@export var cell_data_type_option: OptionButton

@export_group("Node Groups")

## List of Buttons to disable when there is no active cue
@export var disable_when_no_active_cue: Array[Button]



## True if the table should follow the active cue
var _follow_active: bool = true

## The current selected cue
var _current_cue: CueData

## The current cue number
var _current_cue_number: int

## List of all HiQnetAddress 
var _addresses: Array[Array]

## The current address being filtred
var _current_address_filter: Array

## The current display mode
var _current_display_mode: DisplayMode = DisplayMode.Raw

## RefMap for address: TreeItem
var _address_items: RefMap = RefMap.new()

## RefMap for PID: tree_column
var _pid_columns: RefMap = RefMap.new()


## Ready
func _ready() -> void:
	tree.set_column_title(0, "Address")
	cues_control.cue_selected.connect(_on_cue_selected)
	pass


## Shows a given cue in the table
func show_cue(p_cue_number: int) -> void:
	var cue_data: CueData = cues_control.get_cue_data_from_number(p_cue_number)
	
	_current_cue_number = p_cue_number
	_current_cue = cue_data
	
	if not cue_data:
		return reset()
	
	no_cue_selected_label.hide()
	cue_number_spinbox.set_value_no_signal(p_cue_number)
	
	_reload_tree()


## Resets everything
func reset() -> void:
	_reset_tree()
	_current_address_filter.clear()
	_address_items.clear()
	_pid_columns.clear()
	
	no_cue_selected_label.show()
	cue_number_spinbox.set_value_no_signal(0)
	
	_disable_edit_buttons(true)


## Reloads the tree
func _reload_tree() -> void:
	_reset_tree()
	tree.column_titles_visible = true
	
	var data: Dictionary[Array, Dictionary] = _current_cue.data.duplicate(true)
	
	for address: Array in data:
		var string_address: String = str(address).replace(",", ".")
		_addresses.append(address)
		address_filter_option.add_item(string_address)
		
		if address != _current_address_filter and _current_address_filter:
			continue
		
		var item: TreeItem = tree.create_item()
		item.set_text(0, string_address)
		_address_items.map(address, item)
		
		for pid: int in data[address]:
			var parameter: Parameter = data[address][pid]
			var column: int
			
			if _pid_columns.has_left(pid):
				column = _pid_columns.left(pid)
			else:
				column = tree.columns
				tree.columns = column + 1
				_pid_columns.map(pid, column)
				tree.set_column_title(column, str(pid))
			
			item.set_editable(column, true)
			
			match _current_display_mode:
				DisplayMode.Raw:
					item.set_text(column, str(parameter.value))
				
				DisplayMode.CheckBox:
					item.set_cell_mode(column, TreeItem.CELL_MODE_CHECK)
					item.set_checked(column, bool(int(parameter.value)))
				
				DisplayMode.Decibel:
					item.set_text(column, str(snappedf(SiImpact.db_to_fader(int(parameter.value)), 0.1), "dB"))
	
	_disable_edit_buttons(false)
	print(_addresses.find(_current_address_filter))
	address_filter_option.select(max(0, _addresses.find(_current_address_filter) + 1))


## Resets the tree
func _reset_tree() -> void:
	tree.clear()
	tree.columns = 1
	tree.column_titles_visible = false
	tree.create_item()
	
	address_filter_option.clear()
	address_filter_option.add_item("All", 0)
	
	_addresses.clear()
	_address_items.clear()
	_pid_columns.clear()


## Enables or disabled the edit buttons in disable_when_no_active_cue
func _disable_edit_buttons(p_disable: bool) -> void:
	for button: Button in disable_when_no_active_cue:
		button.disabled = p_disable


## Called when a cue is selected
func _on_cue_selected(p_cue: int) -> void:
	if _follow_active:
		show_cue(p_cue)


## Called when the user changes the cue number
func _on_cue_number_value_changed(p_value: int) -> void:
	show_cue(p_value)
	follow_active_button.button_pressed = false


## Called when the follow active button is toggled
func _on_follow_active_toggled(p_toggled_on: bool) -> void:
	_follow_active = p_toggled_on
	
	if _follow_active:
		var current: int = cues_control.get_current_cue_number()
		show_cue(current)


## Called when an address is selected in the address filter
func _on_address_filter_item_selected(p_index: int) -> void:
	if p_index == 0:
		_current_address_filter = []
	else:
		_current_address_filter = _addresses[p_index - 1]
	
	_reload_tree()


## Called when the display mode option is changed
func _on_display_mode_item_selected(p_index: int) -> void:
	_current_display_mode = p_index
	_reload_tree()
