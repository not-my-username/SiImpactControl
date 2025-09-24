class_name Launcher extends Control
## Launcher for SiImapctControl


## Enum for tree columns
enum Columns {NAME, IP_ADDR, DEVICE_ID, NETWORK_STATE}


## The Device Tree
@export var tree: Tree

## The Button to toggle the network state
@export var network_state_toggle: Button

## The button to edit the ip address
@export var ip_edit_button: Button

## The Label to display the bound ip address
@export var ip_addr_label: Label

## The Button to start control with the selected device
@export var start_control_button: Button

## The Button to locate the selected device
@export var locate_button: Button

## The NetworkSettings node
@export var network_settings: NetworkSettings

## The ConnectProgressBar node
@export var connect_progress_bar: ConnectProgressBar


## RefMap for TreeItem: HiQNetDevice
var _devices: RefMap = RefMap.new()

## RefMap for HiQNetDevice: SiImpactControl
var _active_controllers: RefMap = RefMap.new()

## The HiQNetDevice that is being connected to, which will then be opened in a new SiControl window
var _active_connecting_to: HiQNetDevice

## SignalGroup for all HiQNetDevices
var _device_connections: SignalGroup = SignalGroup.new([
	_on_device_network_state_changed
]).set_prefix("_on_device_")


## Ready
func _ready() -> void:
	tree.create_item()
	tree.columns = len(Columns)
	
	for column: int in Columns.values():
		tree.set_column_title(column, Columns.keys()[column].capitalize())
	
	HQ.device_discovered.connect(_add_device)
	HQ.network_state_changed.connect(_set_network_state)


## Adds a device to the tree
func _add_device(p_device: HiQNetDevice) -> void:
	if _devices.has_right(p_device):
		return
	
	var item: TreeItem = tree.create_item()
	_device_connections.connect_object(p_device, true)
	_devices.map(item, p_device)
	
	item.set_text(Columns.IP_ADDR, p_device.get_ip_address_string())
	item.set_text(Columns.DEVICE_ID, str(p_device.get_device_number()))
	item.set_text(Columns.NETWORK_STATE, p_device.get_network_state_human())


## Sets the HQ network state of the launcher
func _set_network_state(p_network_state: HQ.NetworkState) -> void:
	ip_edit_button.set_disabled(p_network_state)
	network_state_toggle.set_pressed_no_signal(p_network_state)


## Sets the Device Buttons disabled
func _set_device_buttons_disabled(p_disabled: bool) -> void:
	start_control_button.set_disabled(p_disabled)
	locate_button.set_disabled(p_disabled)


## Called when an item is selected in the tree
func _on_tree_item_selected() -> void:
	if not _active_connecting_to:
		_set_device_buttons_disabled(false)


## Called when nothing is selected in the tree
func _on_tree_nothing_selected() -> void:
	_set_device_buttons_disabled(true)
	tree.deselect_all()


## Called when the network state changes in a device
func _on_device_network_state_changed(_p_network_state: HiQNetDevice.NetworkState, p_device: HiQNetDevice) -> void:
	_devices.right(p_device).set_text(Columns.NETWORK_STATE, p_device.get_network_state_human())


## Called when network settings are confirmed
func _on_network_settings_settings_confirmed(_p_interface: String, p_address: String, p_netmask_length: int, p_device_id: int) -> void:
	network_settings.hide()
	network_state_toggle.set_disabled(false)
	
	HQ.set_device_number(p_device_id)
	HQ.set_ip_address(p_address)
	HQ.set_broadcast_address(HiQNetHeader.bytes_to_ip(Utils.get_broadcast(HiQNetHeader.ip_to_bytes(p_address), p_netmask_length)))
	
	ip_addr_label.set_text(p_address + "/" + str(p_netmask_length))


## Called when the EditNetworkSettings button is pressed
func _on_edit_network_settings_pressed() -> void:
	network_settings.show()


## Called when the NetworkStateToggle is toggled
func _on_network_state_toggle_toggled(p_toggled_on: bool) -> void:
	if p_toggled_on:
		HQ.go_online()
	else:
		HQ.go_offline()


## Called when the StartControl Button is pressed
func _on_start_control_pressed() -> void:
	var device: HiQNetDevice = _devices.left(tree.get_selected())
	
	if _active_controllers.has_left(device):
		_active_controllers.left(device).get_parent().grab_focus()
		return
	
	_active_connecting_to = device
	connect_progress_bar.set_device(_active_connecting_to)
	
	device.start_session()
	device.set_auto_reconnect(true)
	device.set_allow_disconnect(false)
	
	_set_device_buttons_disabled(true)


## Called when the _active_connecting_to device has connected
func _on_connect_progress_bar_connected_to_device() -> void:
	var mixer: SiImpact = SiImpact.new()
	var controler: SiImpactControl = load("res://panels/SiImpactControl/SiImpactControl.tscn").instantiate()
	var window: Window = Window.new()
	
	mixer.device = _active_connecting_to
	controler._mixer = mixer
	window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_KEYBOARD_FOCUS
	window.size = Vector2(1920, 1080)
	
	window.add_child(controler)
	add_child(window)
	
	_active_controllers.map(_active_connecting_to, controler)
	
	_active_connecting_to = null
	if tree.get_selected():
		_set_device_buttons_disabled(false)


## Called when the Cancel button is pressed on the connection dialog
func _on_connect_progress_bar_cancel_pressed() -> void:
	_active_connecting_to.end_session()
	_active_connecting_to.disconnect_tcp()
	
	_active_connecting_to = null
	if tree.get_selected():
		_set_device_buttons_disabled(false)
