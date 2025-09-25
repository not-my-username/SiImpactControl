# Copyright (c) 2024 Liam Sherwin
# All rights reserved.

class_name SiCuesControl extends SiControlPanel
## UI Control panel for managing cues


## Emitted when the QLab control state is changed
signal qlab_control_state_changed(control_enabled: bool)

## Emitted when the QLab controll IP address is changed
signal qlab_control_address_changed(address: String)

## Emitted when the QLab keep alive time changes
signal qlab_keep_alive_time_changed(keep_alive_time: float)

## Emitted when a VD is added
signal vd_added(id: int, vd: Array, pid_from: int, pid_to: int)

## Emitted when a VD is removed
signal vd_removed(id: int)

## Emitted when a VD is changed
signal vd_changed(id: int, vd: Array)

## Emitted when PID from and to is changed
signal vd_pids_changed(id: int, pid_from: int, pid_to: int)

## Emitted when a cue is selected
signal cue_selected(cue: int)


## Default bg colors options
@export var cue_bg_color_options: Array[Color] = [Color.RED, Color.DARK_ORANGE, Color.YELLOW, Color.GREEN, Color.CYAN, Color.DODGER_BLUE, Color.PURPLE, Color.MAGENTA, Color.DIM_GRAY, Color(0.2, 0.2, 0.2), Color.TRANSPARENT]

## The VBoxContainer to store cues
@export var _cue_container: VBoxContainer

## ScrollContainer for the cue_container
@export var _cue_scroll_container: ScrollContainer

## The current cue name label
@export var _current_cue_name: Label

## The Label for the no active cue text
@export var _no_active_cue_label: Label

## The UpdateConfirmationDialog for updating cues
@export var _update_confirmation_dialog: ConfirmationDialog

## The DeleteConfirmationDialog for deleting cues
@export var _delete_confirmation_dialog: ConfirmationDialog

## The CueReOrderConfirmation for re-ordering cues
@export var _reorder_confirmation_dialog: ConfirmationDialog

## The ColorPopupMenu for setting cues colors
@export var _color_popup_menu: PopupMenu

## The StoreModeDialog for store mode
@export var _store_mode_dialog: AcceptDialog

## The AutoCreateCuesDialogComponent for auto creating cues
@export var _auto_create_cues_dialog: SiAutoCreateCuesDialogComponent

## The current (if any) auto scroll timer
@export var _auto_scroll_timer: Timer

## The timer for Qlab keep alive
@export var _qlab_keep_alive_timer: Timer

## List of buttons to disable on cue de-selection
@export var _disable_on_cue_deselection: Array[Button]

## The OSC Server
@export var _osc_server: OSCServer

## The OSC Client
@export var _osc_client: OSCClient


## Time in seconds to wait before auto scrolling
const _auto_scroll_delay: float = 1

## Speed in seconds to for the auto scroll animation
const _auto_scroll_animation_speed: float = 1

## Prompt for the re-order cues dialog when cues need to be re-orded
const _reorder_cues_mandatory_prompt: String = "This cue number already exists. Would you like to re-order all subsequent cues"

## Prompt for the re-order cues dialog when re-ordering is optional
const _reorder_cues_optional_prompt: String = "Would you like to re-order all subsequent cues"



## RefMap for cue_number:SiControlCueComponent
var _cues: RefMap = RefMap.new()

## List of sorted cue numbers
var _sorted_cue_numbers: Array[int]

## The current selected cue
var _selected_cue: SiControlCueComponent

## The active cue
var _active_cue: SiControlCueComponent

## Are we currently waiting on a response from the mixer to store values
var _store_mode: bool = false

## Stores all the pids that we are still waiting on from the mixer
var _wanted_pids: Dictionary[Array, Array]


## QLab control state
var _qlab_control: bool = false

## Ip address for QLab Control
var _qlab_control_address: String = "127.0.0.1"

## Keepalive for QLab
var _qlab_keep_alive_time: float = 50

## Regex used to check if the cue number from QLab is valid
var _qlab_cue_number_regex = RegEx.new()


## Stores all VD to listen to send to the mixer with cue
var _virtual_devices: Dictionary = {}

## RefMap to map the VD to the VD ID
var _vd_ids: RefMap = RefMap.new()


## Setup custom settings
func _ready() -> void:
	register_setting("QLab Control", "qlab_control", set_qlab_control, get_qlab_control, qlab_control_state_changed, TYPE_BOOL, 0, "Sync to QLab OSC")
	register_setting("QLab Control", "qlab_control_address", set_qlab_control_address, get_qlab_control_address, qlab_control_address_changed, TYPE_STRING, 1, "QLab OSC Address")
	register_setting("QLab Control", "qlab_keep_alive", set_qlab_keep_alive_time, get_qlab_keep_alive_time, qlab_keep_alive_time_changed, TYPE_FLOAT, 2, "Keepalive Interval", 0.0, 500)
	
	register_custom_panel("Cue Parameters", "cue_parameters", "set_panel", load("res://components/CueParametersCustomSettings/CueParametersCustomSettings.tscn"))
	register_setting("Tools", "auto_create_cues", show_auto_create_cues, Callable(), Signal(), TYPE_NIL, 0, "Auto Create Cues")

	_qlab_cue_number_regex.compile("^([1-9][0-9]*|0)$")
	
	await get_tree().process_frame


## Sets the QLab control state
func set_qlab_control(enable_control: bool) -> void:
	_qlab_control = enable_control
	qlab_control_state_changed.emit(_qlab_control)
	
	if enable_control:
		_osc_server.listen(_osc_server.port)
		_osc_client.connect_socket(_osc_client.ip_address, _osc_client.port)
		_qlab_listen()
		
		if _qlab_keep_alive_time:
			_qlab_keep_alive_timer.start()
	
	else:
		_osc_client.send_message("/ignore", [])
		_osc_client.close_socket()
		_osc_server.stop()


## Sends a listen message to qlab
func _qlab_listen() -> void:
	_osc_client.send_message("/listen/go", [])
	_osc_client.send_message("/listen/playhead", [])


## Gets the Qlab control state
func get_qlab_control() -> bool:
	return _qlab_control


## Sets the QLab controll IP address
func set_qlab_control_address(address: String) -> void:
	_qlab_control_address = address
	qlab_control_address_changed.emit(address)
	
	_osc_client.ip_address = address
	
	if _osc_client.client.is_bound():
		_osc_client.connect_socket(_osc_client.ip_address, _osc_client.port)
		_osc_client.send_message("/ignore", [])
		_osc_client.send_message("/listen", [])


## Gets the QLab control address
func get_qlab_control_address() -> String:
	return _qlab_control_address


## Sets the QLab keep alive timeout, set to 0 to dissable
func set_qlab_keep_alive_time(keep_alive_time: float) -> void:
	_qlab_keep_alive_time = keep_alive_time
	qlab_keep_alive_time_changed.emit(_qlab_keep_alive_time)
	
	if keep_alive_time:
		_qlab_keep_alive_timer.wait_time = keep_alive_time
		_qlab_keep_alive_timer.start()
		_qlab_listen()
	else:
		_qlab_keep_alive_timer.stop()


## Gets the Qlab keep alive timeout
func get_qlab_keep_alive_time() -> float:
	return _qlab_keep_alive_time


## Adds a VD, and returns an id
func add_vd(vd: Array, pid_from: int, pid_to: int) -> int:
	var id: int = 0
	
	while id in _virtual_devices:
		id += 1
	
	_virtual_devices[id] = {
		"vd": vd,
		"pid_from": clamp(pid_from, 1, 65535),
		"pid_to": clamp(pid_to, 1, 65535)
	}
	
	if vd != [0,0,0,0] and not mixer.device.is_subscribed_to(vd):
		mixer.device.subscribe_to_all_in(vd)
	
	_vd_ids.map(id, vd)
	vd_added.emit(id, vd, pid_from, pid_to)
	
	return id


## Removes a VD by id
func remove_vd(id: int) -> void:
	if id in _virtual_devices:
		_vd_ids.erase_left(id)
		_virtual_devices.erase(id)
		vd_removed.emit(id)


## Changes a VD
func set_vd(vd: Array, id: int) -> void:
	if id in _virtual_devices:
		_vd_ids.erase_left(id)
		_vd_ids.map(id, vd)
		_virtual_devices[id].vd = vd
		
		if not mixer.device.is_subscribed_to(vd):
			mixer.device.subscribe_to_all_in(vd)
		
		vd_changed.emit(id, vd)


## Sets the PID From for a VD
func set_vd_pid_from(pid_from: int, id: int) -> void:
	if id in _virtual_devices:
		_virtual_devices[id].pid_from = clamp(pid_from, 1, 65535)
		vd_pids_changed.emit(id, _virtual_devices[id].pid_from, _virtual_devices[id].pid_to)


## Sets the PID From for a VD
func set_vd_pid_to(pid_to: int, id: int) -> void:
	if id in _virtual_devices:
		_virtual_devices[id].pid_to = clamp(pid_to, 1, 65535)
		vd_pids_changed.emit(id, _virtual_devices[id].pid_from, _virtual_devices[id].pid_to)


## Shows the auto create cues dialog
func show_auto_create_cues() -> void:
	_auto_create_cues_dialog.show()


## Auto created cues with given names
func auto_create_cues(p_cues: Dictionary[int, Dictionary], p_address: Array = [], p_pid_range: Array = []) -> void:
	for cue_number: int in p_cues.keys():
		var cue_name: String = p_cues[cue_number].name
		var addressed_data: Dictionary = {}
		
		for pid: int in range(p_pid_range[0], p_pid_range[1] + 1):
			addressed_data[pid] = Parameter.new(pid, HiQNetHeader.DataType.LONG, 1 if pid in p_cues[cue_number].pids else 0)
		
		if _cues.has_left(cue_number):
			var cue_data: CueData = _cues.left(cue_number).data
			cue_data.data.get_or_add(p_address).merge(addressed_data, true)
		else:
			_create_cue(cue_number, cue_name, Color.TRANSPARENT, false, false, CueData.new({ p_address: addressed_data }))


## Returns the CueData for a given cue number
func get_cue_data_from_number(p_cue_number: int) -> CueData:
	if _cues.has_left(p_cue_number):
		return _cues.left(p_cue_number).data
	else:
		return null


## Gets the current cue number
func get_current_cue_number() -> int:
	return _selected_cue.get_number() if _active_cue else -1


## Sets the store mode state
func _set_store_mode(store_mode: bool) -> void:
	_store_mode = store_mode
	#_store_mode_dialog.visible = store_mode
	
	if _store_mode:
		_compile_wanted_pids()


## Compiles a list of wanted pids from the mixer
func _compile_wanted_pids() -> void:
	_wanted_pids.clear()
	
	for id: int in _virtual_devices:
		var vd: Array = _virtual_devices[id].vd
		var pid_from: int = _virtual_devices[id].pid_from
		var pid_to: int = _virtual_devices[id].pid_to
		
		_wanted_pids.get_or_add(vd, [])
		
		for pid: int in range(pid_from, pid_to + 1):
			if pid not in _wanted_pids[vd]:
				_wanted_pids[vd].append(pid)


## Sends parametes to a device
func _send_parameters_to_device(data: CueData) -> void:
	for address: Array in data.data:
		mixer.device.set_parameters(address, address, data.data[address].values())


## Gets all the parameters from the device
func _get_parameters_from_device() -> void:
	#for id: int in _virtual_devices:
		#var device: Dictionary = _virtual_devices[id]
		#mixer.device.multi_param_get(device.vd, range(device.pid_from, device.pid_to + 1))
	
	for address: Array in _wanted_pids:
		var data: Dictionary[int, Parameter] = mixer.device.get_parameters_from_cache(address, Array(_wanted_pids[address], TYPE_INT, "", null))
		for parameter: Parameter in data.values():
			_active_cue.data.data.get_or_add(address, {})[parameter.id] = parameter
	
	_set_store_mode(false)


## Creates a new cue
func _create_cue(cue_number: int = -1, cue_name: String = "", cue_color: Color = Color.TRANSPARENT, auto_seek: bool = true, should_store_data: bool = true, stored_data: CueData = CueData.new()) -> bool:
	var new_cue: SiControlCueComponent = load("res://components/Cue/SiControlCueComponent.tscn").instantiate()
	
	if cue_number == -1:
		cue_number = _get_next_available_cue_number()
	
	if cue_number in _sorted_cue_numbers:
		return false
	
	if cue_name == "":
		cue_name = "Cue: " + str(cue_number)
	
	new_cue.set_number(cue_number)
	new_cue.set_cue_name(cue_name)
	new_cue.set_color(cue_color)
	new_cue.data = stored_data
	
	new_cue.clicked.connect(_on_cue_clicked.bind(new_cue))
	new_cue.right_clicked.connect(_on_cue_right_clicked.bind(new_cue))
	new_cue.activated.connect(_on_cue_activated.bind(new_cue))
	new_cue.cue_name_changed.connect(_on_cue_name_changed.bind(new_cue))
	new_cue.cue_number_changed.connect(_on_cue_number_changed.bind(new_cue))
	
	_cues.map(cue_number, new_cue)
	_sorted_cue_numbers.append(cue_number)
	_cue_container.add_child(new_cue)
	
	if auto_seek:
		_seek_to_cue(cue_number)
		_ensure_cue_visable(cue_number, 0.1)
	
	if should_store_data:
		_set_store_mode(true)
		_get_parameters_from_device()
	
	return true


## Seeks to a cue
func _seek_to_cue(cue_number: int, send_data: bool = true) -> void:
	if _active_cue:
		_active_cue.set_active(false)
	
	_active_cue = _cues.left(cue_number)
	
	if _active_cue:
		_active_cue.set_active(true)
		_current_cue_name.text = _active_cue.get_cue_name()
		
		_current_cue_name.show()
		_no_active_cue_label.hide()
		
		if send_data:
			_send_parameters_to_device(_active_cue.data)
		
		if _selected_cue == _active_cue:
			_selection_down()
	else:
		_current_cue_name.hide()
		_no_active_cue_label.show()


## Selects a cue
func _select_cue(cue_number: int) -> void:
	if _selected_cue:
		_selected_cue.set_selected(false)
	
	if cue_number != -1:
		var cue: SiControlCueComponent = _cues.left(cue_number)
		_selected_cue = cue
		_selected_cue.set_selected(true)
	
	for button: Button in _disable_on_cue_deselection:
		button.disabled = cue_number == -1
	
	_ensure_cue_visable(cue_number)
	cue_selected.emit(cue_number)


## Updates a cue by getting new data from the mixer
func _update_cue(cue_number: int) -> void:
	_cues.left(cue_number).data.clear()
	_seek_to_cue(cue_number, false)
	_set_store_mode(true)
	_get_parameters_from_device()
 

## Deletes a cue
func _delete_cue(cue_number: int) -> void:
	var cue: SiControlCueComponent = _cues.left(cue_number)
	
	if not cue:
		return
	
	if cue == _selected_cue:
		_select_cue(-1)
	
	if cue == _active_cue:
		_seek_to_cue(-1)
	
	_cues.erase_left(cue_number)
	_sorted_cue_numbers.erase(cue_number)
	cue.queue_free()


## Called when the up button is pressed
func _selection_up() -> void:
	if not _sorted_cue_numbers:
		return
	
	if _selected_cue:
		if _selected_cue.get_number() == _sorted_cue_numbers[0]:
			return
		
		var next_number: int = _sorted_cue_numbers[_sorted_cue_numbers.find(_selected_cue.get_number()) - 1]
		_select_cue(clamp(next_number, _sorted_cue_numbers[0], _sorted_cue_numbers[-1]))
	else:
		_select_cue(_sorted_cue_numbers[-1])


## Called when the down button is pressed
func _selection_down() -> void:
	if not _sorted_cue_numbers:
		return
	
	if _selected_cue:
		if _selected_cue.get_number() == _sorted_cue_numbers[-1]:
			return
		
		var next_number: int = _sorted_cue_numbers[_sorted_cue_numbers.find(_selected_cue.get_number()) + 1]
		_select_cue(clamp(next_number, _sorted_cue_numbers[0], _sorted_cue_numbers[-1]))
	else:
		_select_cue(_sorted_cue_numbers[0])


## Sorts all the cues in the UI, and array
func _update_cue_sorting() -> void:
	_sorted_cue_numbers.sort()
	
	for cue_number: int in _sorted_cue_numbers:
		_cues.left(cue_number).move_to_front()


## Makes sure the gven cue can be seen in the scroll bar
func _ensure_cue_visable(cue_number: int, delay_override: float = _auto_scroll_delay) -> void:
	if _auto_scroll_timer.timeout.is_connected(_auto_scroll_callback):
		_auto_scroll_timer.timeout.disconnect(_auto_scroll_callback)
	
	_auto_scroll_timer.timeout.connect(_auto_scroll_callback.bind(cue_number))
	_auto_scroll_timer.wait_time = delay_override
	_auto_scroll_timer.start()


## Timeout callback for the auto scroll
func _auto_scroll_callback(cue_number: int) -> void:
	var cue: SiControlCueComponent = _cues.left(cue_number)
	
	if not cue:
		return
	
	var to_scroll: int = cue.position.y - (_cue_scroll_container.size.y / 2)
	var tween: Tween = get_tree().create_tween()
	
	tween.tween_property(_cue_scroll_container, "scroll_vertical", to_scroll, _auto_scroll_animation_speed)


## Gets the next available cue number
func _get_next_available_cue_number() -> int:
	if _sorted_cue_numbers:
		return _sorted_cue_numbers[-1] + 1
	else:
		return 1


## Called when the store cue button is pressed
func _on_store_cue_pressed() -> void:
	_create_cue()


## Called when a cue is clicked
func _on_cue_clicked(cue: SiControlCueComponent) -> void:
	_select_cue(_cues.right(cue))


## Called when a cue is right clicked
func _on_cue_right_clicked(cue: SiControlCueComponent) -> void:
	Utils.disconnect_all_signal_connections(_color_popup_menu.id_pressed)
	
	_color_popup_menu.popup()
	_color_popup_menu.position = DisplayServer.mouse_get_position()
	
	_color_popup_menu.id_pressed.connect(func (id: int):
		var color: Color = cue_bg_color_options[id]
		
		if color != Color.TRANSPARENT:
			color.v = color.v * 0.7
		
		cue.set_color(color)
	, CONNECT_ONE_SHOT)


## Called when a cue is clicked
func _on_cue_activated(cue: SiControlCueComponent) -> void:
	_seek_to_cue(_cues.right(cue))


## Called when the user changes a cue's name
func _on_cue_name_changed(new_name: String, cue: SiControlCueComponent) -> void:
	if cue == _active_cue:
		_current_cue_name.text = new_name


## Called when the user changes a cue's number
func _on_cue_number_changed(new_number: int, cue: SiControlCueComponent) -> void:
	if new_number in _sorted_cue_numbers:
		_reorder_confirmation_dialog.dialog_text = _reorder_cues_mandatory_prompt

	else:
		_reorder_confirmation_dialog.dialog_text = _reorder_cues_optional_prompt
		
		_sorted_cue_numbers.erase(cue.get_number())
		_cues.erase_left(cue.get_number())
		
		_sorted_cue_numbers.append(new_number)
		_cues.map(new_number, cue)
		cue.set_number(new_number)
		
		_update_cue_sorting()
	
	Utils.disconnect_all_signal_connections(_reorder_confirmation_dialog.confirmed)
	_reorder_confirmation_dialog.confirmed.connect(_on_cue_re_order_confirmation_confirmed.bind(cue, new_number))
	
	_reorder_confirmation_dialog.popup()


## Called when re-order confirmation dialog is confirmed
func _on_cue_re_order_confirmation_confirmed(cue: SiControlCueComponent, new_number: int) -> void:
	if not cue:
		return
	
	var old_number: int = cue.get_number()
	
	# Collect all cues and sort by their current numbers
	var all_cues: Array[SiControlCueComponent] = []
	for number in _sorted_cue_numbers:
		var existing_cue: SiControlCueComponent = _cues.left(number)
		if existing_cue:
			all_cues.append(existing_cue)
	
	# Remove the cue we are moving from the list
	all_cues.erase(cue)
	
	# Sort remaining cues by their current numbers
	all_cues.sort_custom(func(a, b): return a.get_number() < b.get_number())
	
	# Clear existing mappings
	_cues.clear()
	_sorted_cue_numbers.clear()
	
	var current_number: int = new_number
	
	# First, assign the moving cue its new number
	cue.set_number(current_number)
	_cues.map(current_number, cue)
	_sorted_cue_numbers.append(current_number)
	current_number += 1
	
	# Now reassign numbers to the rest
	for c in all_cues:
		if c.get_number() < new_number:
			_cues.map(c.get_number(), c)
			_sorted_cue_numbers.append(c.get_number())
		else:
			# Cues at or after new_number are shifted up
			c.set_number(current_number)
			_cues.map(current_number, c)
			_sorted_cue_numbers.append(current_number)
			current_number += 1
	
	_sorted_cue_numbers.sort()
	_update_cue_sorting()


## Called when the cuelist background has a GUI event
func _on_cue_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT and _selected_cue:
		_select_cue(-1)
		grab_focus()


## Called when the go button is pressed
func _on_go_pressed() -> void:
	if _selected_cue:
		_seek_to_cue(_cues.right(_selected_cue))


## Called when the update button is pressed
func _on_update_pressed() -> void:
	var selected_cue_number: int = _selected_cue.get_number()
	
	Utils.disconnect_all_signal_connections(_update_confirmation_dialog.confirmed)
	_update_confirmation_dialog.confirmed.connect(func ():
		_update_cue(selected_cue_number)
	, CONNECT_ONE_SHOT)
	
	_update_confirmation_dialog.dialog_text = "Update Cue: " + _selected_cue.get_cue_name() + "?"
	_update_confirmation_dialog.popup()


## Called when the delete cue button is pressed
func _on_delete_pressed() -> void:
	var selected_cue_number: int = _selected_cue.get_number()
	
	Utils.disconnect_all_signal_connections(_delete_confirmation_dialog.confirmed)
	_delete_confirmation_dialog.confirmed.connect(func ():
		_delete_cue(selected_cue_number)
	, CONNECT_ONE_SHOT)
	
	_delete_confirmation_dialog.dialog_text = "Delete Cue: " + _selected_cue.get_cue_name() + "?"
	_delete_confirmation_dialog.popup()


## Called when the cancel button is pressed on the store mode dialog
func _on_store_mode_dialog_confirmed() -> void:
	_set_store_mode(false)


## Called when a message is recieved from QLab
func _on_osc_server_message_received(address: Variant, value: Variant, time: Variant) -> void:
	match address:
		"/qlab/event/workspace/go":
			if not value:
				return
			
			var cue_number_s: String = value[0]
			if _qlab_cue_number_regex.search(cue_number_s) and int(cue_number_s) in _sorted_cue_numbers:
				_seek_to_cue(int(cue_number_s))
			
			else:
				match value[1]:
					"SINextCue":
						_selection_down()
					"SIPreviousCue":
						_selection_up()
					"SIGoSelectedCue":
						_on_go_pressed()
					"SIStoreNewCue":
						_create_cue()
					"SIUpdateSelectedCue":
						_on_update_pressed()
			
		"/qlab/event/workspace/playhead":
			if not value:
				return
			
			var cue_number_s: String = value[0]
			if _qlab_cue_number_regex.search(cue_number_s) and int(cue_number_s) in _sorted_cue_numbers:
				_select_cue(int(cue_number_s))


## Called when the QLab keep alive timer times out
func _on_q_lab_keep_alive_timer_timeout() -> void:
	if _qlab_control:
		_qlab_listen()
		_qlab_keep_alive_timer.wait_time = _qlab_keep_alive_time
		_qlab_keep_alive_timer.start()


## Saves this SiControlPanel into a dictionary
func save() -> Dictionary:
	var saved_data: Dictionary = {
		"qlab_control": _qlab_control,
		"qlab_control_address": _qlab_control_address,
		"qlab_keep_alive_time": _qlab_keep_alive_time,
		"virtual_devices": _virtual_devices,
		"cues": {}
	}
	
	for cue: SiControlCueComponent in _cues.get_right():
		saved_data.cues[cue.get_number()] = cue.serialize()
	
	return saved_data


## Loads this SiControlPanel from dictionary
func load(saved_data: Dictionary):
	set_qlab_control(type_convert(saved_data.get("qlab_control"), TYPE_BOOL))
	set_qlab_control_address(type_convert(saved_data.get("qlab_control_address"), TYPE_STRING))
	set_qlab_keep_alive_time(type_convert(saved_data.get("qlab_keep_alive_time"), TYPE_FLOAT))
	
	for idv: Variant in type_convert(saved_data.get("virtual_devices"), TYPE_DICTIONARY).keys():
		if saved_data.virtual_devices[idv] is Dictionary:
			var device: Dictionary = saved_data.virtual_devices[idv]
			
			var id: int = int(idv)
			var vd: Array = type_convert(device.get("vd"), TYPE_ARRAY)
			var pid_from: int = type_convert(device.get("pid_from"), TYPE_INT)
			var pid_to: int = type_convert(device.get("pid_to"), TYPE_INT)
			
			add_vd(Array(vd, TYPE_INT, "", null), pid_from, pid_to)
	
	for saved_cue: Dictionary in type_convert(saved_data.get("cues"), TYPE_DICTIONARY).values():
		_create_cue(
			type_convert(saved_cue.get("number"), TYPE_INT), 
			type_convert(saved_cue.get("name"), TYPE_STRING), 
			type_convert(saved_cue.get("color"), TYPE_COLOR), 
			false,
			false,
			CueData.load(type_convert(saved_cue.get("data"), TYPE_DICTIONARY))
		)
	
	_update_cue_sorting()


## Resets this SiControlPanel to default settings
func reset() -> void:
	_seek_to_cue(-1)
	_select_cue(-1)
	
	_sorted_cue_numbers.clear()
	_cues.clear()
	
	for id: int in _virtual_devices:
		vd_removed.emit(id)
	
	_virtual_devices.clear()
	_vd_ids.clear()
	
	for cue: SiControlCueComponent in _cue_container.get_children():
		_cue_container.remove_child(cue)
		cue.queue_free()
	
	set_qlab_control(false)
	set_qlab_control_address("127.0.0.1")
	set_qlab_keep_alive_time(50)
	pass
