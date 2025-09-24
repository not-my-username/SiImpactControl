class_name ConnectProgressBar extends PanelContainer
## Loading bar for connecting to devices


## Emitted when the cancel button is pressed
signal cancel_pressed()

## Emitted when the devices NetworkState changed to CONNECTEd
signal connected_to_device()


## The Status Label
@export var status_label: Label


## The Current HiQNetDevice shown
var _current_device: HiQNetDevice

## SignalGroup for the HiQNetDevice
var _device_connections: SignalGroup = SignalGroup.new([
	_on_network_state_changed
])


## Sets the device to listen to
func set_device(p_device: HiQNetDevice) -> void:
	if _current_device:
		_device_connections.disconnect_object(_current_device, true)
		set_status_label("")
		hide()
	
	_current_device = p_device
	
	if _current_device:
		_device_connections.connect_object(_current_device, true)
		set_status_label(_current_device.get_network_state_human())
		show()
		
		if _current_device.get_network_state() == HiQNetDevice.NetworkState.CONNECTED:
			_on_network_state_changed.call_deferred(HiQNetDevice.NetworkState.CONNECTED, _current_device)


## Sets the text in the status label
func set_status_label(p_status: String) -> void:
	status_label.text = p_status


## Called when the networkState is changed in the current HiQNetDevice
func _on_network_state_changed(p_network_state: HiQNetDevice.NetworkState, p_device: HiQNetDevice) -> void:
	set_status_label(p_device.get_network_state_human())
	
	if p_network_state == HiQNetDevice.NetworkState.CONNECTED:
		connected_to_device.emit()
		set_device(null)


## Called when the cancel button is pressed
func _on_cancel_pressed() -> void:
	set_device(null)
	cancel_pressed.emit()
