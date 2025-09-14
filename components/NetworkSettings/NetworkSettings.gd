# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# See the LICENSE file for details.

class_name NetworkSettings extends Control
## Dialog to show a list of network interfaces and addresses


## Emitted when an interface is chosen
signal settings_confirmed(interface: String, address: String, netmask_length: int, device_id: int)


## The Tree to use
@export var tree: Tree

## The Confirm Button
@export var confirm_button: Button

## The SpinBox to set the Network Mask length
@export var netmask_length_spinbox: SpinBox

## The SpinBox to set the device ID
@export var device_id_spinbox: SpinBox


## All network interfaces
var _interfaces: Array[Dictionary]

## RegEx to match valid ipv4 addresses
var _ipv4_regex: RegEx = RegEx.create_from_string("^(?:(?:25[0-5]|2[0-4]\\d|1\\d{2}|[1-9]\\d?|0)\\.){3}(?:25[0-5]|2[0-4]\\d|1\\d{2}|[1-9]\\d?|0)$")


## Ready
func _ready() -> void:
	reload()


## Reloads the tree
func reload():
	confirm_button.set_disabled(true)
	tree.clear()
	_interfaces.clear()
	
	tree.create_item()
	_interfaces = IP.get_local_interfaces()
	
	for interface: Dictionary in _interfaces:
		var interface_name: String = interface.name
		var interface_item: TreeItem = tree.create_item()
		
		interface_item.set_text(0, interface_name)
		interface_item.set_selectable(0, false)
		
		for address: String in interface.addresses:
			if _ipv4_regex.search(address):
				interface_item.create_child().set_text(0, address)


## Called when an item is selected in the tree
func _on_tree_item_selected() -> void:
	confirm_button.set_disabled(false)


## Called when nothing is selected in the tree
func _on_tree_nothing_selected() -> void:
	confirm_button.set_disabled(false)


## Called when the confirm button is pressed
func _on_confirm_pressed() -> void:
	var selected: TreeItem = tree.get_selected()
	
	var address: String = selected.get_text(0)
	var interface: String = selected.get_parent().get_text(0)
	var netmask_length: int = netmask_length_spinbox.value
	var device_id: int = device_id_spinbox.value
	
	settings_confirmed.emit(interface, address, netmask_length, device_id)
