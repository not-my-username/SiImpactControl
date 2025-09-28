# Copyright (c) 2024 Liam Sherwin, All rights reserved.

class_name SiImpact extends RefCounted
## Class to control the Soundcraft Si Impact digital mixer


## Emitted when a channel name is changed
signal channel_name_changed(channel: MixerChannel, type: ChannelType, new_name: String)

## Emitted when a channel is muted or un-muted
signal channel_muted(channel: MixerChannel, type: ChannelType, mute_state: bool)

## Emitted when a fader is moved 
signal channel_fader_moved(channel: MixerChannel, type: ChannelType, db: int)


## Enum for channel types
enum ChannelType {
	MixerChannel,
	MixBus,
	MatrixBus,
	MasterBus,
	VCA
}


## Enum for all mixer channels
enum MixerChannel {
	EMPTY,
	MONO_1,
	MONO_2,
	MONO_3,
	MONO_4,
	MONO_5,
	MONO_6,
	MONO_7,
	MONO_8,
	MONO_9,
	MONO_10,
	MONO_11,
	MONO_12,
	MONO_13,
	MONO_14,
	MONO_15,
	MONO_16,
	MONO_17,
	MONO_18,
	MONO_19,
	MONO_20,
	MONO_21,
	MONO_22,
	MONO_23,
	MONO_24,
	MONO_25,
	MONO_26,
	MONO_27,
	MONO_28,
	MONO_29,
	MONO_30,
	MONO_31,
	MONO_32,
	MONO_33,
	MONO_34,
	MONO_35,
	MONO_36,
	MONO_37,
	MONO_38,
	MONO_39,
	MONO_40,
	MONO_41,
	MONO_42,
	MONO_43,
	MONO_44,
	MONO_45,
	MONO_46,
	MONO_47,
	MONO_48,
	MONO_49,
	MONO_50,
	MONO_51,
	MONO_52,
	MONO_53,
	MONO_54,
	MONO_55,
	MONO_56,
	MONO_57,
	MONO_58,
	MONO_59,
	MONO_60,
	MONO_61,
	MONO_62,
	MONO_63,
	MONO_64,
	ST_1,
	ST_2,
	ST_3,
	ST_4,
	ST_5,
	ST_6,
	ST_7,
	ST_8
}

## Enum for mix buses
enum MixBus {
	EMPTY,
	MIX_1,
	MIX_2,
	MIX_3,
	MIX_4,
	MIX_5,
	MIX_6,
	MIX_7,
	MIX_8,
	MIX_9,
	MIX_10,
	MIX_11,
	MIX_12,
	MIX_13,
	MIX_14
}

## Enum for matrix outputs
enum MatrixBus {
	EMPTY,
	MTX_1,
	MTX_2,
	MTX_3,
	MTX_4
}

## Enum for master buses
enum MasterBus {
	EMPTY,
	LR, ## Main Left/Right bus
	C   ## Center bus
}


## HiQNet address for master sends
const master_sends_address: Array = [1,0,0,21]

## HiQNet address for the master busses
const master_bus_address: Array = [1,0,0,2]

## HiQNet addres for the mix buses
const mix_bus_address: Array = [1,0,0,1]

## HiQNet address for the VCAs
const vca_address: Array = [1,0,0,66]

## HiQNet address for channel names
const channel_name_address: Array = [1,0,0,62]

## The start pid address of faders for ChannelType.MixerChannel
const mixer_channel_fader_start_pid: int = 72

## The start pid address of faders for ChannelType.MixBus
const mix_bus_fader_start_pid: int = 18

## The start pid address of faders for ChannelType.VCA
const vca_fader_start_pid: int = 8

## The start pid address of faders for ChannelType.MasterBus
const master_bus_fader_start_pid: int = 2

## Fader min value
const fader_min: int = -8000

## Fader max value
const fader_max: int = 640


## The HiQNetDevice that repersents the mixer
var device: HiQNetDevice

## UDP peer to recieve metering
var _udp: PacketPeerUDP = PacketPeerUDP.new()

## Signals for meters
var _meter_signals: Dictionary[int, Dictionary] = {
	ChannelType.MixerChannel: {},
	ChannelType.MixBus: {},
	ChannelType.MatrixBus: {},
	ChannelType.MasterBus: {}
}


## Converts fader position (0.0 - ∞) to clamped int dB value
static func fader_to_db(fader: float) -> int:
	## Convert fader (linear) into dB
	var db_val: float = linear_to_db(fader)
	
	## Apply scaling depending on fader region
	if fader < 1.0:
		db_val *= 133.0
	else:
		db_val *= 281.0
	
	## Clamp to range and cast to int
	return int(clamp(db_val, fader_min, fader_max))


## Converts dB value back into fader position
static func db_to_fader(db_val: int) -> float:
	## Clamp input to valid range
	var clamped_db: float = clamp(db_val, fader_min, fader_max)
	
	## First branch: fader < 1
	var lin_fader_133: float = db_to_linear(clamped_db / 133.0)
	
	## Second branch: fader >= 1
	var lin_fader_281: float = db_to_linear(clamped_db / 281.0)
	
	## Decide which one is valid
	if lin_fader_133 < 1.0:
		return lin_fader_133
	else:
		return lin_fader_281


## Connects all subscribes
func subscribe() -> void:
	if not device:
		return
	
	device.subscribe_to_all_in(master_sends_address)
	device.subscribe_to_all_in(master_bus_address)
	device.subscribe_to_all_in(mix_bus_address)
	device.subscribe_to_all_in(vca_address)
	device.subscribe_to_all_in(channel_name_address)
	
	device.parameters_changed.connect(_on_get_parameters_recieved)
	
	_udp.bind(3333)


## Polls the mixer for metering packets
func poll() -> void:
	if not _udp.is_bound():
		return
	
	var packet: PackedByteArray
	while _udp.get_available_packet_count() != 0:
		packet = _udp.get_packet()
	
	if packet:
		_decode_meter_packet(packet)


## Called when the mute button is toggled on any one of the channels
func mute_channel(p_mute_state: bool, p_type: ChannelType, p_channel: MixerChannel) -> void:
	var parameter: Parameter
	var address: Array
	
	match p_type:
		ChannelType.MixerChannel:
			parameter = Parameter.new(p_channel, HiQNetHeader.DataType.LONG, int(p_mute_state))
			address = master_sends_address
		
		ChannelType.MasterBus:
			parameter = Parameter.new(p_channel, HiQNetHeader.DataType.LONG, int(p_mute_state))
			address = master_bus_address
		
		ChannelType.MixBus:
			parameter = Parameter.new(p_channel, HiQNetHeader.DataType.LONG, int(p_mute_state))
			address = mix_bus_address
		
		ChannelType.MatrixBus:
			parameter = Parameter.new(p_channel + MixBus.MIX_14, HiQNetHeader.DataType.LONG, int(p_mute_state))
			address = mix_bus_address
		
		ChannelType.VCA:
			parameter = Parameter.new(p_channel, HiQNetHeader.DataType.LONG, int(p_mute_state))
			address = vca_address
	
	device.set_parameters(address, address, [parameter])


## Called when the mute button is toggled on any one of the channels
func set_channel_fader(p_db: int, p_type: ChannelType, p_channel: MixerChannel) -> void:
	var parameter: Parameter
	var address: Array
	
	match p_type:
		ChannelType.MixerChannel:
			parameter = Parameter.new(p_channel + mixer_channel_fader_start_pid, HiQNetHeader.DataType.LONG, p_db)
			address = master_sends_address
		
		ChannelType.MasterBus:
			parameter = Parameter.new(p_channel + master_bus_fader_start_pid, HiQNetHeader.DataType.LONG, p_db)
			address = master_bus_address
		
		ChannelType.MixBus:
			parameter = Parameter.new(p_channel + mix_bus_fader_start_pid, HiQNetHeader.DataType.LONG, p_db)
			address = mix_bus_address
		
		ChannelType.MatrixBus:
			parameter = Parameter.new(p_channel + mix_bus_fader_start_pid + MixBus.MIX_14, HiQNetHeader.DataType.LONG, p_db)
			address = mix_bus_address
		
		ChannelType.VCA:
			parameter = Parameter.new(p_channel + vca_fader_start_pid, HiQNetHeader.DataType.LONG, p_db)
			address = vca_address
	
	device.set_parameters(address, address, [parameter])


## Decode meter packet
func _decode_meter_packet(packet: PackedByteArray):
	# Split the packet into 4-byte chunks (8 hex characters)
	var channel_index: int = 1
	var meters: Dictionary[ChannelType, Dictionary] = {
		ChannelType.MixerChannel: {},
		ChannelType.MixBus: {},
		ChannelType.MatrixBus: {},
		ChannelType.MasterBus: {},
	}
	
	# Mono 1-32
	for packet_index in range(0, 127, 4):
		var chunk = packet.slice(packet_index, packet_index + 4)
		if len(chunk) == 4:
			meters[ChannelType.MixerChannel][channel_index] = _update_channel_metering(chunk, true)
			
			if _meter_signals[ChannelType.MixerChannel].has(channel_index):
				emit_signal(_meter_signals[ChannelType.MixerChannel][channel_index], meters[ChannelType.MixerChannel][channel_index])
			
			channel_index += 1
		
	channel_index = 65
	
	# ST 1-8
	for packet_index in range(128, 191, 8):
		var chunk = packet.slice(packet_index, packet_index + 8)
		if len(chunk) == 8:
			meters[ChannelType.MixerChannel][channel_index] = _update_channel_metering(chunk, true, true)
			
			if _meter_signals[ChannelType.MixerChannel].has(channel_index):
				emit_signal(_meter_signals[ChannelType.MixerChannel][channel_index], meters[ChannelType.MixerChannel][channel_index])
			
			channel_index += 1
	
	channel_index = 33
	
	# Mono 33-64
	for packet_index in range(192, 320, 4):
		var chunk = packet.slice(packet_index, packet_index + 4)
		if len(chunk) == 4:
			meters[ChannelType.MixerChannel][channel_index] = _update_channel_metering(chunk, true)
			
			if _meter_signals[ChannelType.MixerChannel].has(channel_index):
				emit_signal(_meter_signals[ChannelType.MixerChannel][channel_index], meters[ChannelType.MixerChannel][channel_index])
			
			channel_index += 1
	
	channel_index = 1
	
	# MTX 1-4
	for packet_index in range(584, 616, 8):
		var chunk = packet.slice(packet_index, packet_index + 8)
		if len(chunk) == 8:
			meters[ChannelType.MatrixBus][channel_index] = _update_channel_metering(chunk, false, true)
			
			if _meter_signals[ChannelType.MatrixBus].has(channel_index):
				emit_signal(_meter_signals[ChannelType.MatrixBus][channel_index], meters[ChannelType.MatrixBus][channel_index])
			
			channel_index += 1
	
	channel_index = 1
	
	# Mix 1-8
	for packet_index in range(476, 507, 4):
		var chunk = packet.slice(packet_index, packet_index + 4)
		if len(chunk) == 4:
			meters[ChannelType.MixBus][channel_index] = _update_channel_metering(chunk, false)
			
			if _meter_signals[ChannelType.MixBus].has(channel_index):
				emit_signal(_meter_signals[ChannelType.MixBus][channel_index], meters[ChannelType.MixBus][channel_index])
			
			channel_index += 1
	
	channel_index = 9
	
	# Mix 9-14
	for packet_index in range(508, 552, 8):
		var chunk = packet.slice(packet_index, packet_index + 8)
		if len(chunk) == 8:
			meters[ChannelType.MixBus][channel_index] = _update_channel_metering(chunk, false, true)
			
			if _meter_signals[ChannelType.MixBus].has(channel_index):
				emit_signal(_meter_signals[ChannelType.MixBus][channel_index], meters[ChannelType.MixBus][channel_index])
			
			channel_index += 1
	
	meters[ChannelType.MasterBus][1] = _update_channel_metering(packet.slice(572, 580), false, true)
	if _meter_signals[ChannelType.MasterBus].has(1):
		emit_signal(_meter_signals[ChannelType.MasterBus][1], meters[ChannelType.MasterBus][1])
	
	meters[ChannelType.MasterBus][2] = _update_channel_metering(packet.slice(580, 584), false, false)
	if _meter_signals[ChannelType.MasterBus].has(2):
		emit_signal(_meter_signals[ChannelType.MasterBus][2], meters[ChannelType.MasterBus][2])


## Updates a channels metering
func _update_channel_metering(chunk: PackedByteArray, _gate: bool = true, st: bool = false) -> Dictionary:
	var result: Dictionary[String, Variant]
	result["is_st"] = st
	
	result["vu_l"] = (1 - chunk[0] / 108.0)
	result["rms_l"] = (1 - chunk[1] / 108.0)
	result["vu_ovl_l"] = bool(chunk[3] & 0x10)
	
	if st:
		result["vu_r"] = (1 - chunk[4] / 108.0)
		result["rms_r"] = (1 - chunk[5] / 108.0)
		result["vu_ovl_r"] = bool(chunk[7] & 0x10)
	
	result["comp"] = (chunk[2] / 40.0)
	
	if not chunk[3] & 0x8:
		result["gate_open"] = bool(chunk[3] & 0x4)
		result["gate_hold"] = bool(chunk[3] & 0x2)
		result["gate_shut"] = bool(chunk[3] & 0x1)
	else:
		result["gate_open"] = false
		result["gate_hold"] = false
		result["gate_shut"] = false
	
	return result


## Called when parameters are revieved form the server
func _on_get_parameters_recieved(address: Array, parameters: Array) -> void:
	match address:
		channel_name_address:
			for parameter: Parameter in parameters:
				channel_name_changed.emit(parameter.id, ChannelType.MixerChannel, parameter.value)
	
		master_sends_address:
			for parameter: Parameter in parameters:
				if parameter.id <= mixer_channel_fader_start_pid:
					channel_muted.emit(parameter.id, ChannelType.MixerChannel, bool(parameter.value))
				else:
					channel_fader_moved.emit(min(parameter.id - mixer_channel_fader_start_pid, mixer_channel_fader_start_pid), ChannelType.MixerChannel, parameter.value)
		
		mix_bus_address:
			for parameter: Parameter in parameters:
				if parameter.id <= mix_bus_fader_start_pid:
					if parameter.id > MixBus.MIX_14:
						channel_muted.emit(parameter.id - MixBus.MIX_14, ChannelType.MatrixBus, bool(parameter.value))
					else:
						channel_muted.emit(parameter.id, ChannelType.MixBus, bool(parameter.value))
				else:
					if parameter.id - mix_bus_fader_start_pid > MixBus.MIX_14:
						channel_fader_moved.emit(min(parameter.id - mix_bus_fader_start_pid - MixBus.MIX_14, mix_bus_fader_start_pid - MixBus.MIX_14), ChannelType.MatrixBus, parameter.value)
					else:
						channel_fader_moved.emit(min(parameter.id - mix_bus_fader_start_pid, mix_bus_fader_start_pid), ChannelType.MixBus, parameter.value)
		
		vca_address:
			for parameter: Parameter in parameters:
				if parameter.id <= vca_fader_start_pid:
					channel_muted.emit(parameter.id, ChannelType.VCA, bool(parameter.value))
				else:
					channel_fader_moved.emit(min(parameter.id - vca_fader_start_pid, vca_fader_start_pid), ChannelType.VCA, parameter.value)
		
		master_bus_address:
			for parameter: Parameter in parameters:
				if parameter.id <= master_bus_fader_start_pid:
					channel_muted.emit(parameter.id, ChannelType.MasterBus, bool(parameter.value))
				else:
					channel_fader_moved.emit(min(parameter.id - master_bus_fader_start_pid, master_bus_fader_start_pid), ChannelType.MasterBus, parameter.value)


## Gets the signal for a channels meter
func connect_meter_signal(channel_type: ChannelType, channel: int, callable: Callable) -> void:
	if not _meter_signals[channel_type].has(channel):
		var sig_name: String = str(channel_type) + ".meter." + str(channel)
		_meter_signals[channel_type][channel] = sig_name
		add_user_signal(sig_name, [{ "name": "meter_data", "type": TYPE_DICTIONARY }])
	
	connect( _meter_signals[channel_type][channel], callable)
