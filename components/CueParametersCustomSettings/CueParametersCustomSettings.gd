# Copyright (c) 2024 Liam Sherwin
# All rights reserved.

class_name SiCueParametersCustomSettings extends PanelContainer
## Custom settings panel for SiImpactControl's cue parameters


## The VBoxContainer for VDs
@export var _row_container: VBoxContainer


## The cue control panel
var _panel: SiCuesControl

## RefMap for virtual device id's. And the UI row
var _virtual_devices: RefMap = RefMap.new()


## Sets the Cues panel
func set_panel(panel: SiCuesControl) -> void:
	_panel = panel
	
	_panel.vd_added.connect(_on_vd_added)
	_panel.vd_removed.connect(_on_vd_removed)
	_panel.vd_changed.connect(_on_vd_changed)
	_panel.vd_pids_changed.connect(_on_vd_pids_changed)


## Called when a VD is added
func _on_vd_added(id: int, vd: Array, pid_from: int, pid_to: int) -> void:
	var new_row: SiCueParametersTemplateRow = load("res://components/CueParametersCustomSettings/TemplateRow.tscn").instantiate()
	
	new_row.id = id
	new_row.vd_input.set_vd(vd)
	new_row.pid_from.value = pid_from
	new_row.pid_to.value = pid_to
	
	new_row.vd_input.vd_changed.connect(_panel.set_vd.bind(id))
	new_row.pid_from.value_changed.connect(_panel.set_vd_pid_from.bind(id))
	new_row.pid_to.value_changed.connect(_panel.set_vd_pid_to.bind(id))
	new_row.delete.pressed.connect(_panel.remove_vd.bind(id))
	new_row.show()
	
	_virtual_devices.map(id, new_row)
	_row_container.add_child(new_row)


## Called when a VD is removed
func _on_vd_removed(id: int) -> void:
	var row: SiCueParametersTemplateRow = _virtual_devices.left(id)
	row.queue_free()
	_virtual_devices.erase_left(id)


## Called when a vd is changed
func _on_vd_changed(id: int, vd: Array) -> void:
	_virtual_devices.left(id).vd_input.set_vd(vd)


## Called when VD pids changed
func _on_vd_pids_changed(id: int, pid_from: int, pid_to: int) -> void:
	pass


## Adds a VD to listen to
func _on_add_row_pressed() -> void:
	_panel.add_vd([0,0,0,0], 0, 65535)
