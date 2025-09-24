# Copyright (c) 2024 Liam Sherwin, All rights reserved.

class_name Channel extends PanelContainer
## Channel fader


## Emitted when the mute button is pressed
signal mute_toggled(pressed: bool)

## Emitted when the fader is moved
signal fader_moved(db: int)


## Shows or hides the gate
@export var show_gate: bool = true

## Shows or hides the metering
@export var show_meters: bool = true

## The channel name
@export var channel_name: String = "Channel Name"

## ST state 
@export var st: bool = false


@export_category("Nodes")

## The Fader
@export var fader: VSlider

## The Label to show fader DB
@export var fader_db_label: Label

## The ProgressBar for the left VU meter
@export var vu_meter_left: ProgressBar

## The ProgressBar for the right VU meter
@export var vu_meter_right: ProgressBar

## The ProgressBar for the left RMS meter
@export var rms_meter_left: ProgressBar

## The ProgressBar for the right RMS meter
@export var rms_meter_right: ProgressBar

## The ProgressBar for the Comp meter
@export var comp_meter: ProgressBar

## The PanelContainer that contains the status icons
@export var status_container: PanelContainer

## The MeteringContainer that contains all meters
@export var metering_container: VBoxContainer

## ColorRect for gate open
@export var gate_open: ColorRect

## ColorRect for gate hold
@export var gate_hold: ColorRect

## ColorRect for gate shut
@export var gate_shut: ColorRect

## The Button for the name
@export var name_button: Button

## The Mute Button
@export var mute_button: Button


## Colors for gate status
var _gate_open_color: Color = Color.GREEN
var _gate_hold_color: Color = Color.ORANGE
var _gate_shut_color: Color = Color.RED

## Default color for gate status
var _gate_status_default: Color = Color(0.096, 0.096, 0.096)

## Color for dB OVL
var _vu_ovl_color: Color = Color.RED

## Color for dB OVL
var _vu_normal_color: Color = Color(0.3, 1.0, 0.3)

## StyleBoxFlat for the VU meter
var _vu_stylebox_left: StyleBoxFlat

## StyleBoxFlat for the VU meter
var _vu_stylebox_right: StyleBoxFlat


## Ready
func _ready() -> void:
	_vu_stylebox_left = vu_meter_left.get_theme_stylebox("fill").duplicate()
	vu_meter_left.add_theme_stylebox_override("fill", _vu_stylebox_left)
	
	_vu_stylebox_right = vu_meter_right.get_theme_stylebox("fill").duplicate()
	vu_meter_right.add_theme_stylebox_override("fill", _vu_stylebox_right)
	
	status_container.visible = show_gate
	metering_container.visible = show_meters
	
	set_channel_name(channel_name)
	set_st(st)


## Makes this a ST channel
func set_st(state: bool) -> void:
	st = state
	vu_meter_right.visible = state


## Sets the VU meters value
func set_vu_value(vu: float, channel: int = 0) -> void:
	if channel:
		vu_meter_right.value = vu
	else:
		vu_meter_left.value = vu


## Sets the VU overload state
func set_vu_ovl(state: bool, channel: int = 0):
	var color: Color = _vu_ovl_color if state else _vu_normal_color
	
	if channel:
		_vu_stylebox_right.bg_color = color
	else:
		_vu_stylebox_left.bg_color = color


## Sets the RMS meters value
func set_rms_value(rms: float, channel: int = 0) -> void:
	if channel:
		rms_meter_right.value = rms
	else:
		rms_meter_left.value = rms


## Sets the Comp meters value
func set_comp_value(comp: float) -> void:
	comp_meter.value = comp


## Sets the gate hols status
func set_gate_open(state: bool) -> void:
	gate_open.color = _gate_open_color if state else _gate_status_default


## Sets the gate hols status
func set_gate_hold(state: bool) -> void:
	gate_hold.color = _gate_hold_color if state else _gate_status_default


## Sets the gate hols status
func set_gate_shut(state: bool) -> void:
	gate_shut.color = _gate_shut_color if state else _gate_status_default


## Sets the channel name
func set_channel_name(p_chanel_name: String) -> void:
	channel_name = p_chanel_name
	name_button.text = p_chanel_name


## Sets the mute state
func set_mute_state(state: bool) -> void:
	mute_button.set_pressed_no_signal(state)


## Sets the fader position
func set_fader(db: int) -> void:
	set_fader_db_label(db)
	
	fader.set_value_no_signal(SiImpact.db_to_fader(db))


## Sets the DB level on the fader DB label
func set_fader_db_label(db: int) -> void:
	@warning_ignore("integer_division")
	fader_db_label.text = str(db / 64) + "dB"


## Sets the metering from a dictionary
func set_metering(metering: Dictionary) -> void:
	set_vu_value(metering["vu_l"], 0)
	set_rms_value(metering["rms_l"], 0)
	set_vu_ovl(metering["vu_ovl_l"], 0)
	
	if metering.is_st:
		set_vu_value(metering["vu_r"], 1)
		set_rms_value(metering["rms_r"], 1)
		set_vu_ovl(metering["vu_ovl_r"], 1)
	
	set_comp_value(metering["comp"])
	set_gate_open(metering["gate_open"])
	set_gate_hold(metering["gate_hold"])
	set_gate_shut(metering["gate_shut"])


## Emitted when the mute button is toggled
func _on_mute_toggled(toggled_on: bool) -> void:
	mute_toggled.emit(toggled_on)


## Called when the fader is moved
func _on_fader_value_changed(value: float) -> void:
	var db: int = SiImpact.fader_to_db(value)
	set_fader_db_label(db)
	fader_moved.emit(db)
