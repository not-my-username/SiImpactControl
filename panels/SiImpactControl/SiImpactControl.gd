# Copyright (c) 2024 Liam Sherwin
# All rights reserved.

class_name SiImpactControl extends Control
## Module to display metering from the Si Impact mixer


## HBox container for mono channels
@export var mono_channels: HBoxContainer

## HBox container for mono channels
@export var st_channels: HBoxContainer

## HBox container for mono channels
@export var mix_channels: HBoxContainer

## HBox container for mono channels
@export var mtx_channels: HBoxContainer

## HBox container for mono channels
@export var vca_channels: HBoxContainer

## HBox container for mono channels
@export var user1_channels: HBoxContainer

## HBox container for mono channels
@export var user2_channels: HBoxContainer

## HBox container for mono channels
@export var user3_channels: HBoxContainer

## HBox container for mono channels
@export var user4_channels: HBoxContainer

## Main LR channel
@export var main_lr: Channel

## Main C channel
@export var main_c: Channel

## All Panels in this SiImpactControl
@export var panels: Array[SiControlPanel]


## Stores all mono and st channels
var _mixer_channels: Dictionary[int, Channel] = {}

## Stores all st channels
var _mix_channels: Dictionary[int, Channel] = {}

## Stores all st channels
var _mtx_channels: Dictionary[int, Channel] = {}

## Stores all st channels
var _vca_channels: Dictionary[int, Channel] = {}

## Stores all st channels
var _user1_channels: Dictionary[int, Channel] = {}

## Stores all st channels
var _user2_channels: Dictionary[int, Channel] = {}

## Stores all st channels
var _user3_channels: Dictionary[int, Channel] = {}

## Stores all st channels
var _user4_channels: Dictionary[int, Channel] = {}

## The mixer object
var _mixer: SiImpact = SiImpact.new()


## Config for channels
@onready var _channel_config: Array = [
	{
		"type": SiImpact.ChannelType.MixerChannel,
		"container": mono_channels,
		"refernce": _mixer_channels,
		"count": 64,
		"meter_start_at": 1,
		"st": false,
		"name": "CH &",
		"mute_toggled": _mixer.mute_channel,
		"fader_moved": _mixer.set_channel_fader,
	},
	{
		"type": SiImpact.ChannelType.MixerChannel,
		"container": st_channels,
		"refernce": _mixer_channels,
		"count": 8,
		"meter_start_at": 65,
		"st": true,
		"name": "ST &",
		"mute_toggled": _mixer.mute_channel,
		"fader_moved": _mixer.set_channel_fader,
	},
	{
		"type": SiImpact.ChannelType.MixBus,
		"container": mix_channels,
		"refernce": _mix_channels,
		"count": 8,
		"meter_start_at": 1,
		"st": false,
		"name": "MIX &",
		"mute_toggled": _mixer.mute_channel,
		"fader_moved": _mixer.set_channel_fader,
	},
	{
		"type": SiImpact.ChannelType.MixBus,
		"container": mix_channels,
		"refernce": _mix_channels,
		"count": 6,
		"meter_start_at": 1,
		"st": true,
		"name": "MIX &",
		"mute_toggled": _mixer.mute_channel,
		"fader_moved": _mixer.set_channel_fader,
	},
	{
		"type": SiImpact.ChannelType.MatrixBus,
		"container": mtx_channels,
		"refernce": _mtx_channels,
		"count": 4,
		"meter_start_at": 1,
		"st": true,
		"name": "MTX &",
		"mute_toggled": _mixer.mute_channel,
		"fader_moved": _mixer.set_channel_fader,
	},
	{
		"type": SiImpact.ChannelType.VCA,
		"container": vca_channels,
		"refernce": _vca_channels,
		"count": 8,
		"st": false,
		"name": "VCA &",
		"mute_toggled": _mixer.mute_channel,
		"fader_moved": _mixer.set_channel_fader,
	}
]


## Sub to sensor values
func _ready() -> void:
	_load_channels()
	_mixer.subscribe()
	
	_mixer.channel_muted.connect(_on_channel_muted)
	_mixer.channel_fader_moved.connect(_on_channel_fader_moved)
	_mixer.channel_name_changed.connect(_on_channel_name_changed)
	
	for panel: SiControlPanel in panels:
		panel.mixer = _mixer


## Poll the mixer
func _process(delta: float) -> void:
	_mixer.poll()


## Loads all the channels from the channel config
func _load_channels() -> void:
	for channel_config: Dictionary in _channel_config:
		for i in range(len(channel_config.refernce) + 1, len(channel_config.refernce) + 1 + channel_config.count):
			var channel: Channel = load("res://components/Channel/Channel.tscn").instantiate()
			channel.set_channel_name(channel_config.name.replace("&", str(i)))
			channel.set_st(channel_config.st)
			
			channel_config.refernce[i] = channel
			channel_config.container.add_child.call_deferred(channel)
			
			channel.mute_toggled.connect(channel_config.mute_toggled.bind(channel_config.type, i))
			channel.fader_moved.connect(channel_config.fader_moved.bind(channel_config.type, i))
			
			if channel_config.has("meter_start_at"):
				_mixer.connect_meter_signal(channel_config.type, channel_config.meter_start_at + i - 1, channel.set_metering)
			else:
				channel.show_meters = false
	
	main_lr.mute_toggled.connect(_mixer.mute_channel.bind(SiImpact.ChannelType.MasterBus, SiImpact.MasterBus.LR))
	main_c.mute_toggled.connect(_mixer.mute_channel.bind(SiImpact.ChannelType.MasterBus, SiImpact.MasterBus.C))
	
	main_lr.fader_moved.connect(_mixer.set_channel_fader.bind(SiImpact.ChannelType.MasterBus, SiImpact.MasterBus.LR))
	main_c.fader_moved.connect(_mixer.set_channel_fader.bind(SiImpact.ChannelType.MasterBus, SiImpact.MasterBus.C))
	
	_mixer.connect_meter_signal(SiImpact.ChannelType.MasterBus, SiImpact.MasterBus.LR, main_lr.set_metering)
	_mixer.connect_meter_signal(SiImpact.ChannelType.MasterBus, SiImpact.MasterBus.C, main_c.set_metering)


## Updates a channels metering
func _update_channel_metering(channel: Channel, chunk: PackedByteArray, gate: bool = true, st: bool = false) -> void:
	channel.set_vu_value(1 - chunk[0] / 108.0, 0)
	channel.set_rms_value(1- chunk[1] / 108.0, 0)
	channel.set_vu_ovl(chunk[3] & 0x10, 0)
	
	if st:
		channel.set_vu_value(1 - chunk[4] / 108.0, 1)
		channel.set_rms_value(1- chunk[5] / 108.0, 1)
		channel.set_vu_ovl(chunk[7] & 0x10, 1)
	
	channel.set_comp_value(chunk[2] / 40.0)
	
	if not chunk[3] & 0x8:
		channel.set_gate_open(chunk[3] & 0x4)
		channel.set_gate_hold(chunk[3] & 0x2)
		channel.set_gate_shut(chunk[3] & 0x1)
	else:
		channel.set_gate_open(false)
		channel.set_gate_hold(false)
		channel.set_gate_shut(false)


## Gets the corrisponding Channel
func _get_channel(p_channel: int, p_type: SiImpact.ChannelType) -> Channel:
	match p_type:
		SiImpact.ChannelType.MixerChannel:
			return _mixer_channels[p_channel]
		
		SiImpact.ChannelType.MixBus:
			return _mix_channels[p_channel]
		
		SiImpact.ChannelType.MatrixBus:
			return _mtx_channels[p_channel]
		
		SiImpact.ChannelType.VCA:
			return _vca_channels[p_channel]
		
		SiImpact.ChannelType.MasterBus:
			match p_channel:
				SiImpact.MasterBus.LR:
					return main_lr
				SiImpact.MasterBus.C:
					return main_c
				_:
					return null
		_:
			return null


## Called when a mixer channel is muted
func _on_channel_muted(p_channel: int, p_type: SiImpact.ChannelType, p_mute_state: bool) -> void:
	_get_channel(p_channel, p_type).set_mute_state(p_mute_state)


## Called when a mixer channel is muted
func _on_channel_fader_moved(p_channel: int, p_type: SiImpact.ChannelType, p_db: int) -> void:
	_get_channel(p_channel, p_type).set_fader(p_db)


## Called when a mixer channel is muted
func _on_channel_name_changed(p_channel: int, p_type: SiImpact.ChannelType, p_channel_name: String) -> void:
	_get_channel(p_channel, p_type).set_channel_name(p_channel_name)
