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


## Default DataType
const DefaultDataType: HiQNetHeader.DataType = HiQNetHeader.DataType.LONG

## Default Parameter Value
const DefaultDataValue: Variant = 0


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

## The Button to delete a parameter from the cue
@export var delete_button: Button

## The Button to add a HiQNet Parameter entry into the CueData
@export var add_parameter_button: Button

## The OptionButton for setting the cell data type
@export var cell_data_type_option: OptionButton

## The SiCueAddParameter dialog to add data
@export var add_parameter_window: SiCueAddParameter

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

## All editable columns: { TreeItem: { int(column): True|False } }
var _editable_items: Dictionary[TreeItem, Dictionary]


## Ready
func _ready() -> void:
	tree.set_column_title(0, "Address")
	cues_control.cue_selected.connect(_on_cue_selected)
	
	for data_type: String in HiQNetHeader.DataType:
		cell_data_type_option.add_item(data_type)
	
	cell_data_type_option.select(0)


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
		
		var pids: Array = data[address].keys()
		pids.sort()
		
		for pid: int in pids:
			_add_parameter_columns(item, data[address][pid], pid, _current_display_mode)
	
	_disable_edit_buttons(false)
	address_filter_option.select(max(0, _addresses.find(_current_address_filter) + 1))


## Adds each parameter to the TreeItem
func _add_parameter_columns(p_item: TreeItem, p_parameter: Parameter, p_pid: int, p_display_mode: DisplayMode) -> void:
	var column: int
	
	if _pid_columns.has_left(p_pid):
		column = _pid_columns.left(p_pid)
	else:
		column = tree.columns
		tree.columns = column + 1
		_pid_columns.map(p_pid, column)
		tree.set_column_title(column, str(p_pid))
	
	
	match p_display_mode:
		DisplayMode.Raw:
			p_item.set_text(column, str(p_parameter.value))
			_set_item_editable(p_item, column, true)
			
		DisplayMode.CheckBox:
			match p_parameter.data_type:
				HiQNetHeader.DataType.BLOCK, HiQNetHeader.DataType.STRING:
					p_item.set_text(column, "TypeErr")
				_:
					p_item.set_cell_mode(column, TreeItem.CELL_MODE_CHECK)
					p_item.set_checked(column, bool(type_convert(p_parameter.value, TYPE_INT)))
					_set_item_editable(p_item, column, true)
		
		DisplayMode.Decibel:
			match p_parameter.data_type:
				HiQNetHeader.DataType.LONG, HiQNetHeader.DataType.ULONG:
					p_item.set_text(column, str(snappedf(SiImpact.db_to_fader(type_convert(p_parameter.value, TYPE_INT)), 0.1), "dB"))
					_set_item_editable(p_item, column, true)
				_:
					p_item.set_text(column, "TypeErr")


## Sets the editable state on a tree items column
func _set_item_editable(p_item: TreeItem, p_column: int, p_editable: bool) -> void:
	_editable_items.get_or_add(p_item, {})[p_column] = p_editable


## Checks if the given item is editable
func _is_item_editable(p_item: TreeItem, p_column: int) -> bool:
	return _editable_items.get(p_item, {}).get(p_column, false)


## Resets the tree
func _reset_tree() -> void:
	tree.clear()
	tree.columns = 1
	tree.column_titles_visible = false
	tree.create_item()
	
	delete_button.set_disabled(true)
	cell_data_type_option.set_disabled(true)
	cell_data_type_option.select(0)
	
	address_filter_option.clear()
	address_filter_option.add_item("All", 0)
	
	_addresses.clear()
	_address_items.clear()
	_pid_columns.clear()
	_editable_items.clear()


## Enables or disabled the edit buttons in disable_when_no_active_cue
func _disable_edit_buttons(p_disable: bool) -> void:
	for button: Button in disable_when_no_active_cue:
		button.disabled = p_disable


## Returns the Parameter object for the currently selected tree cell, or null if none
func _get_selected_parameter() -> Parameter:
	var item: TreeItem = tree.get_selected()
	var column: int = tree.get_selected_column()
	
	if not item or column == 0:
		return null
	
	var address: Array = _address_items.right(item)
	var pid: int = _pid_columns.right(column)
	
	return _current_cue.data.get(address, {}).get(pid, null)


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
	_current_display_mode = p_index as DisplayMode
	_reload_tree()


## Called when an item is edited in the tree
func _on_tree_item_edited() -> void:
	var address: Array = _address_items.right(tree.get_edited())
	var pid: int = _pid_columns.right(tree.get_edited_column())
	var value: Variant
	
	match _current_display_mode:
		DisplayMode.Raw:
			value = tree.get_edited().get_text(tree.get_edited_column())
		DisplayMode.CheckBox:
			value = int(tree.get_edited().is_checked(tree.get_edited_column()))
		DisplayMode.Decibel:
			value = SiImpact.fader_to_db(int(tree.get_edited().get_text(tree.get_edited_column())))
	
	tree.get_edited().set_editable(tree.get_edited_column(), false)
	(_current_cue.data[address][pid] as Parameter).value = value


## Called for all GUI input in the tree
func _on_tree_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		var item: TreeItem = tree.get_item_at_position(event.position)
		var column: int = tree.get_column_at_position(event.position)
		
		if _is_item_editable(item, column):
			var address: Array = _address_items.right(item)
			var pid: int = _pid_columns.right(column)
			tree.deselect_all()
			item.select(column)
			
			await get_tree().process_frame
			await get_tree().process_frame
			
			match _current_display_mode:
				DisplayMode.Raw:
					item.set_editable(column, true)
					tree.edit_selected(true)
				
				DisplayMode.CheckBox:
					item.set_checked(column, not item.is_checked(column))
					(_current_cue.data[address][pid] as Parameter).value = int(item.is_checked(column))
				
				DisplayMode.Decibel:
					item.set_editable(column, true)


## Called when nothing is selected in the tree
func _on_tree_nothing_selected() -> void:
	tree.deselect_all()
	delete_button.set_disabled(true)
	cell_data_type_option.set_disabled(true)
	cell_data_type_option.select(0)


## Called when an item is activated in the tree
func _on_tree_item_activated() -> void:
	var item: TreeItem = tree.get_selected()
	var column: int = tree.get_selected_column()
	var address: Array = _address_items.right(item)
	var pid: int = _pid_columns.right(column)
	
	if _current_cue.data.get(address, {}).has(pid):
		return
	
	var parameter: Parameter = Parameter.new(pid, DefaultDataType, DefaultDataValue)
	_current_cue.data.get_or_add(address)[pid] = parameter
	_add_parameter_columns(item, parameter, pid, _current_display_mode)


## Called when an item is selected in the tree
func _on_tree_item_selected() -> void:
	delete_button.set_disabled(false)
	cell_data_type_option.set_disabled(false)
	
	var parameter: Parameter = _get_selected_parameter()
	
	if parameter:
		cell_data_type_option.select(parameter.data_type + 1)
	
	else:
		cell_data_type_option.select(0)
		cell_data_type_option.set_disabled(true)

## Called when the AddParameter button is pressed
func _on_add_parameter_pressed() -> void:
	add_parameter_window.set_cue_data(_current_cue)
	add_parameter_window.show()


## Called when the cue is edited in the SiCueAddParameter dialog
func _on_add_parameter_window_cue_edited() -> void:
	_reload_tree()


## Called when the Delete button is pressed
func _on_delete_pressed() -> void:
	var item: TreeItem = tree.get_selected()
	var column: int = tree.get_selected_column()
	var address: Array = _address_items.right(item)
	
	if column == 0:
		_current_cue.data.erase(address)
		
	else:
		var pid: int = _pid_columns.right(column)
		_current_cue.data.get(address, {}).erase(pid)
	
	_reload_tree()


## Called when a data type option is selected
func _on_cell_data_type_item_selected(p_index: int) -> void:
	var parameter: Parameter = _get_selected_parameter()
	
	parameter.data_type = (p_index - 1) as HiQNetHeader.DataType
