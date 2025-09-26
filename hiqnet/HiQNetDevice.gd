# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the HiQNet implementation for Godot, licensed under the LGPL v3.0 or later.
# See the LICENSE file for details.

class_name HiQNetDevice extends Node
## Class to represent a device on the HiQNet network


## Emitted when the network state is changed
signal network_state_changed(new_state: NetworkState)

## Emitted when the last seen time was changed
signal last_seen_time_changed(time: float)

## Emitted when the device name is changed
signal name_changed(new_name: String)

## Emitted when a MultiParamSet message is recieved, or when parameters are changed on the remote device
signal parameters_changed(p_address: Array, p_parameters: Array)


## The TCP/UDP port for HiQNet
const HIQNET_PORT: int = HQ.HIQNET_PORT

## Device number to use when sending a message to broadcast
const DEVICE_NUMBER_BROADCAST: int = HQ.DEVICE_NUMBER_BROADCAST

## Copy of HiQNetGetAttributes.AttributeID
const AttributeID: Dictionary[String, int] = HiQNetGetAttributes.AttributeID

## Copy of HiQNetHeader.DataType
const DataType: Dictionary[String, int] = HiQNetHeader.DataType

## Copy of HiQNetHeader.MessageType
const MessageType: Dictionary[String, int] = HiQNetHeader.MessageType


## Represents the state of the HiQNet network connection
enum NetworkState {
	OFFLINE,						## No connection is active
	DISCOVERED,						## Device had been found on the network
	CONNECTING,						## Waiting on TCP connection to establish before starting session
	AWAITING_SESSION_RESPONSE,		## Waiting for a reply to a session request
	CONNECTED,						## Successfully connected to a session
	USING_SESSIONLESS_COMMS,		## Communicating without a session via UDP
	RECONNECTING_TCP,				## The TCP stream was broken and a reconnect is in progress
	AWAITING_SESSION_CONFIRMATION,	## Waiting for a reply to confirm that the session is still active after a TCP disconnect
}

## Transport type options for network communication
enum TransportType {
	AUTO,
	TCP,
	UDP,
}


## -------------------
## Network Connections
## -------------------

## Current NetworkState
var _network_state: NetworkState = NetworkState.OFFLINE

## The UDP connection bound to the device
var _udp_peer: PacketPeerUDP = PacketPeerUDP.new()

## StreamPeer for TX to the device
var _tcp_peer: StreamPeerTCP = StreamPeerTCP.new()

## Current status of the TCP StreamPeer
var _tcp_status: StreamPeerTCP.Status = StreamPeerTCP.STATUS_NONE

## Message Queue for TCP
var _tcp_message_queue: Array[HiQNetHeader]

## True if this device should establish a session with the remote device once TCP connects
var _establish_session_once_connected: bool = false

## True if this device will auto re-create a session if the remote device attepts to end the session
var _allow_disonnect: bool = true

## If true this device will auto re-connect to the remote device if it is re-discovred on then network after going offline
var _auto_reconnect: bool = false

## -----------
## Device Info
## -----------

## HiQNet Device Number of the remote device
var _device_number: int = 00000

## Serial number of the remote device
var _serial_number: PackedByteArray = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

## Max message size of the remote device
var _max_message_size: int = 0x00100000

## Keep alive time in ms
var _keep_alive_time: int = 10000

## MAC Address of the remote device
var _mac_address: PackedByteArray = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

## DHCP state of the remote device
var _dhcp: bool = false

## IP Address of the remote device
var _ip_address: PackedByteArray = [192, 168, 1, 1]

## Subnet mask of the remote device
var _subnet_mask: PackedByteArray = [0xff, 0xff, 0xff, 0x00]

## Network gateway of the remote device
var _gateway: PackedByteArray = [0x00, 0x00, 0x00, 0x00] 

## UNIX timestamp of when this device last send a discovery message to the local device
var _last_seen: float = 0

## Local session number for this device
var _local_session_number: int = 0

## Session number for the remote device
var _remote_session_number: int = 0

## All active parameter subscriptions
var _active_subscriptions: Array[Array]

@warning_ignore("int_as_enum_without_cast")
## All the attributes in the "Device Manager Virtual Device" of this device
var _local_device_manager_attributes: Dictionary[int, Parameter] = {
	AttributeID.ClassName: 			Parameter.new(AttributeID.ClassName, DataType.STRING, "Si Impact 2.0"),
	AttributeID.NameString: 		Parameter.new(AttributeID.NameString, DataType.STRING, "Si Impact 2.0"),
	AttributeID.SoftwareVersion: 	Parameter.new(AttributeID.SoftwareVersion, DataType.STRING, "V2.0")
}

## All the attributes in the "Device Manager Virtual Device" of the remote device
var _remote_device_manager_attributes: Dictionary[int, Parameter] = {
	
}

## A cache of all parameters of the remote device that have been sent to this device
var _remote_parameter_cache: Dictionary[Array, Dictionary] = {
	
}


## Creates a new HiQNetDevice from a HiQNetDiscoInfo message
static func create_from_discovery(p_discovery: HiQNetDiscoInfo) -> HiQNetDevice:
	var device: HiQNetDevice = HiQNetDevice.new()
	
	device._device_number = p_discovery.source_device
	device._serial_number = p_discovery.serial_number
	device._max_message_size = p_discovery.max_size
	device._keep_alive_time = p_discovery.keep_alive
	device._mac_address = p_discovery.mac_address
	device._dhcp = p_discovery.dhcp
	device._ip_address = p_discovery.ip_address
	device._subnet_mask = p_discovery.subnet_mask
	device._gateway = p_discovery.gateway
	device._last_seen = Time.get_unix_time_from_system()
	device.connect_udp()
	
	return device


## Converts and Array address to a String
static func address_to_string(p_address: Array) -> String:
	return ".".join(PackedStringArray(p_address))


## Converts a String address to an Array
static func string_to_address(p_string: String) -> Array[int]:
	if not len(p_string.split(".")) >= 4:
		return []
	
	var address: Array[int] = []
	
	for byte: String in p_string.split("."):
		if not byte or not byte.is_valid_int():
			return []
		
		address.append(clamp(int(byte), 0, 255))
	
	return address


## Ready
func _ready() -> void:
	#get_attributes([AttributeID.ClassName, AttributeID.NameString])
	pass


## Process
func _process(_delta: float) -> void:
	_tcp_peer.poll()
	
	var status: StreamPeerTCP.Status = _tcp_peer.get_status()
	
	if status != _tcp_status:
		handle_tcp_status_change(status)
	
	if _tcp_status == StreamPeerTCP.STATUS_CONNECTED:
		while _tcp_status == StreamPeerTCP.STATUS_CONNECTED and _tcp_peer.get_available_bytes() > 0:
			var packet: PackedByteArray = _tcp_peer.get_data(_tcp_peer.get_available_bytes())[1]
			while HiQNetHeader.is_packet_valid(packet):
				var length: int = (packet[2] << 32) | (packet[3] << 16) | (packet[4] << 8) | packet[5]
				var sliced_packet: PackedByteArray = packet.slice(0, length)
				
				handle_message(HiQNetHeader.phrase_packet(sliced_packet))
				packet = packet.slice(length)


## Handles a change in the TCP Stream status
func handle_tcp_status_change(p_status: StreamPeerTCP.Status) -> void:
	_tcp_status = p_status
	_log("TCP Status changed to: ", _tcp_status)
	
	match _tcp_status:
		StreamPeerTCP.STATUS_CONNECTED:
			match _network_state:
				NetworkState.RECONNECTING_TCP:
					_set_network_state(NetworkState.AWAITING_SESSION_CONFIRMATION)
					send_discovery(false, TransportType.TCP)
				
				NetworkState.CONNECTING:
					if _establish_session_once_connected:
						_establish_session_once_connected = false
						
						_local_session_number = randi_range(1, 65535)
						_log("Is auto establishing a session, with SID: ", _local_session_number)
						
						send_discovery(TransportType.TCP)
						send_hello_req(_local_session_number)
						send_get_attributes([AttributeID.ClassName, AttributeID.NameString])
						
						_set_network_state(NetworkState.AWAITING_SESSION_RESPONSE)
			
			for message: HiQNetHeader in _tcp_message_queue:
				send_message_tcp(message)
		
		StreamPeerTCP.STATUS_NONE, StreamPeerTCP.STATUS_ERROR:
			match _network_state:
				NetworkState.CONNECTED:
					reconnect_tcp()
				
				NetworkState.RECONNECTING_TCP, NetworkState.AWAITING_SESSION_CONFIRMATION:
					_set_network_state(NetworkState.OFFLINE)


## Starts a session with the device
func start_session() -> bool:
	if _network_state != NetworkState.DISCOVERED:
		return false
	
	_establish_session_once_connected = true
	_set_network_state(NetworkState.CONNECTING)
	
	return connect_tcp()


## Ends a session with the device
func end_session() -> void:
	var message: HiQNetGoodbye = auto_full_headder(HiQNetGoodbye.new())
	
	message.device_number = HQ.get_device_number()
	
	send_message_tcp(message)
	_set_network_state(NetworkState.OFFLINE)
	
	_local_session_number = 0
	_remote_session_number = 0
	_establish_session_once_connected = false
	_tcp_message_queue.clear()
	_tcp_status = StreamPeerTCP.STATUS_NONE
	
	disconnect_tcp()


## Connects the UDP peer, returning ERR_ALREADY_EXISTS if it is already connected
func connect_udp() -> Error:
	if _udp_peer.is_socket_connected():
		return ERR_ALREADY_EXISTS
	
	return _udp_peer.connect_to_host(HiQNetHeader.bytes_to_ip(_ip_address), HIQNET_PORT)


## Disconnects the UDP peer
func disconnect_udp() -> bool:
	if not _udp_peer.is_socket_connected():
		return false
	
	_udp_peer.close()
	return true


## Connects the TCP peer, returning ERR_ALREADY_EXISTS if it is already connected
func connect_tcp() -> Error:
	if _tcp_peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		_log("Unable to connect TCP: Alreay Connected")
		return ERR_ALREADY_EXISTS
	
	_log("Connecting TCP")
	return _tcp_peer.connect_to_host(HiQNetHeader.bytes_to_ip(_ip_address), HIQNET_PORT)


## Disconnects the UDP peer
func disconnect_tcp() -> void:
	_tcp_peer.disconnect_from_host()


func reconnect_tcp():
	_set_network_state(NetworkState.RECONNECTING_TCP)
	disconnect_tcp()
	connect_tcp()


## Sets the StreamPeerTCP to use
func use_stream(p_tcp_stream: StreamPeerTCP) -> bool:
	if p_tcp_stream == _tcp_peer:
		return false
	
	_tcp_peer = p_tcp_stream
	_tcp_peer.poll()
	handle_tcp_status_change(_tcp_peer.get_status())
	
	_log("Changing TCP stream")
	
	return true


## Sends a message to the remote device using either UDP or TCP depending on the connection state
func send_message(p_message: HiQNetHeader, p_transport_type: TransportType = TransportType.AUTO) -> Error:
	match p_transport_type:
		TransportType.AUTO:
			if _tcp_status == StreamPeerTCP.STATUS_CONNECTED:
				return send_message_tcp(p_message)
			
			else:
				return send_message_udp(p_message)
		
		TransportType.TCP:
			return send_message_tcp(p_message)
		
		TransportType.UDP:
			return send_message_udp(p_message)
		
		_:
			return ERR_PARAMETER_RANGE_ERROR


## Sends a message to the remote device via UDP
func send_message_udp(p_message: HiQNetHeader) -> Error:
	if not _udp_peer.is_socket_connected():
		return ERR_CONNECTION_ERROR
	
	p_message.set_guaranteed(false)
	return _udp_peer.put_packet(p_message.get_as_packet())


## Sends a message to the remote device via TCP
func send_message_tcp(p_message: HiQNetHeader) -> Error:
	if has_active_session():
		p_message.set_session_number(true)
		p_message.session_number = _remote_session_number
	
	p_message.set_guaranteed(true)
	
	if not _tcp_peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		_log("Can't send message, TCP not connected, added to queue")
		_tcp_message_queue.append(p_message)
		return ERR_CONNECTION_ERROR
	
	return _tcp_peer.put_data(p_message.get_as_packet())


## Handles a HiQNet message that came from the remote device
func handle_message(p_message: HiQNetHeader) -> void:
	if not is_instance_valid(p_message) or p_message.source_device != _device_number:
		return
	
	match p_message.message_type:
		MessageType.DiscoInfo:
			p_message = p_message as HiQNetDiscoInfo
			_last_seen = Time.get_unix_time_from_system()
			last_seen_time_changed.emit(_last_seen)
			
			_log("Got Discovery: NetworkState: ", NetworkState.keys()[_network_state])
			
			match _network_state:
				NetworkState.OFFLINE:
					_set_network_state(NetworkState.DISCOVERED)
					
					if _auto_reconnect:
						start_session()
				
				NetworkState.CONNECTED:
					if has_active_session() and p_message.dest_device == HQ.get_device_number() and p_message.is_information():
						send_discovery(true, TransportType.TCP)
				
				NetworkState.AWAITING_SESSION_CONFIRMATION:
					if p_message.dest_device == HQ.get_device_number() and p_message.is_guaranteed():
						_set_network_state(NetworkState.CONNECTED)
						send_discovery(true, TransportType.TCP)
		
		MessageType.Hello:
			p_message = p_message as HiQNetHello
			if p_message.is_information():
				if _network_state == NetworkState.AWAITING_SESSION_RESPONSE:
					_remote_session_number = p_message.device_session_number
					
					for address: Array in _active_subscriptions:
						subscribe_to_all_in(address)
					
					_set_network_state(NetworkState.CONNECTED)
			
			elif p_message.is_guaranteed():
				_log("Has asked to start a session, SID=", p_message.device_session_number)
				_remote_session_number = p_message.device_session_number
				_local_session_number = randi_range(1, 65535)
				_log("Is responding to a session request, with SID: ", _local_session_number)
				
				send_hello_res(_local_session_number, _remote_session_number)
				
				for address: Array in _active_subscriptions:
						subscribe_to_all_in(address)
				
				_set_network_state(NetworkState.CONNECTED)
			
		
		MessageType.GoodBye:
			p_message = p_message as HiQNetGoodbye
			_set_network_state(NetworkState.OFFLINE)
			disconnect_tcp()
			
			if not _allow_disonnect:
				start_session()
		
		MessageType.GetAttributes:
			p_message = p_message as HiQNetGetAttributes
			if p_message.is_information():
				for attribute: Parameter in p_message.set_attributes.values():
					_remote_device_manager_attributes[attribute.id] = attribute.duplicate()
					
					match attribute.id:
						AttributeID.NameString:
							name_changed.emit(type_convert(attribute.value, TYPE_STRING))
			
			else:
				send_set_attributes(p_message.get_attributes.keys(), TransportType.TCP)
		
		MessageType.MultiParamSet:
			p_message = p_message as HiQNetMultiParamSet
			
			var cache: Dictionary = _remote_parameter_cache.get_or_add(p_message.dest_address, {})
			for parameter: Parameter in p_message.set_parameters.values():
				cache[parameter.id] = parameter
			
			parameters_changed.emit(p_message.dest_address, p_message.set_parameters.values())


## Auto fill the infomation in a HiQNetHeadder for sending to the remote device
func auto_full_headder(p_headder: HiQNetHeader, p_flags: HiQNetHeader.Flags = HiQNetHeader.Flags.NONE, p_dest_address: Array[int] = [0, 0, 0, 0], p_source_address: Array[int] = [0, 0, 0, 0]) -> HiQNetHeader:
	p_headder.source_device = HQ.get_device_number()
	p_headder.source_address = p_source_address
	p_headder.dest_device = _device_number
	p_headder.dest_address = p_dest_address
	p_headder.flags = p_flags
	
	return p_headder


## Sends a discovery message to the remote device, if guaranteed == true this message will be sent via TCP
func send_discovery(p_infomation: bool = false,  p_transport_type: TransportType = TransportType.AUTO) -> Error:
	var message: HiQNetDiscoInfo = auto_full_headder(HiQNetDiscoInfo.new(), HiQNetHeader.Flags.INFORMATION if p_infomation else 0)
	
	message.serial_number = HQ.get_serial_number()
	message.mac_address = HQ.get_mac_address()
	message.ip_address = HQ.get_ip_address()
	message.subnet_mask = HQ.get_subnet_mask()
	
	_log("Sending Discovery: ", "RES" if p_infomation else "REQ")
	
	return send_message(message, p_transport_type)


## Gets attributes from the remote device
func send_get_attributes(p_attributes: Array[int], p_transport_type: TransportType = TransportType.AUTO) -> Error:
	var message: HiQNetGetAttributes = auto_full_headder(HiQNetGetAttributes.new())
	
	for id: int in p_attributes:
		message.get_attributes[id] = Parameter.new(id)
	
	return send_message(message, p_transport_type)


## Sends local attributes to the remote device
func send_set_attributes(p_attributes: Array[int], p_transport_type: TransportType = TransportType.AUTO) -> Error:
	var message: HiQNetGetAttributes = auto_full_headder(HiQNetGetAttributes.new())
	
	message.set_information(true)
	for id: int in p_attributes:
		if _local_device_manager_attributes.has(id):
			message.set_attributes[id] = _local_device_manager_attributes[id].duplicate()
	
	if not message.set_attributes:
		_log("send_set_attributes() returning ERR_INVALID_PARAMETER. Wont sent attributes as no valid attributes were requested")
		return ERR_INVALID_PARAMETER
	
	return send_message(message, p_transport_type)


## Sends a Hello Request message to start a session
func send_hello_req(p_local_session_number: int) -> Error:
	var message: HiQNetHello = auto_full_headder(HiQNetHello.new())
	
	message.device_session_number = p_local_session_number
	
	return send_message_tcp(message)


## Sends a Hello Responce message to confirm a session
func send_hello_res(p_local_session_number: int, p_remote_session_number: int) -> Error:
	var message: HiQNetHello = auto_full_headder(HiQNetHello.new(), HiQNetHeader.Flags.INFORMATION)
	
	message.set_session_number(true)
	message.session_number = p_remote_session_number
	message.device_session_number = p_local_session_number
	
	return send_message_tcp(message)



## Subscribe to all parameters in the given VD or object address
func subscribe_to_all_in(p_address: Array, p_transport_type: TransportType = TransportType.AUTO) -> Error:
	var message: HiQNetParameterSubscribeAll = auto_full_headder(HiQNetParameterSubscribeAll.new(), HiQNetHeader.Flags.NONE, Array(p_address, TYPE_INT, "", null))
	
	if not is_subscribed_to(p_address):
		_active_subscriptions.append(p_address)
	
	return send_message(message, p_transport_type)


## Sets one or more parameters in a Virtual Device or Object
func set_parameters(p_source_address: Array, p_dest_address: Array, p_parameters: Array, p_transport_type: TransportType = TransportType.AUTO) -> Error:
	var message: HiQNetMultiParamSet = auto_full_headder(HiQNetMultiParamSet.new(), HiQNetHeader.Flags.NONE, Array(p_dest_address, TYPE_INT, "", null), Array(p_source_address, TYPE_INT, "", null))
	var cache: Dictionary = _remote_parameter_cache.get_or_add(p_dest_address, {})
	
	for parameter: Variant in p_parameters:
		if parameter is Parameter:
			message.set_parameters[parameter.id] = parameter
			cache[parameter.id] = parameter
	
	parameters_changed.emit(p_dest_address, p_parameters)
	return send_message(message, p_transport_type)


## Gets one or more parameters from the remote device
func get_parameters() -> void:
	pass ## TODO


## Gets remote device parameters from the local cache
func get_parameters_from_cache(p_address: Array, p_pids: Array[int]) -> Dictionary[int, Parameter]:
	var result: Dictionary[int, Parameter] = {}
	
	if p_address not in _remote_parameter_cache:
		return result
	
	for pid: int in p_pids:
		if _remote_parameter_cache[p_address].has(pid):
			result[pid] = _remote_parameter_cache[p_address][pid]
	
	return result


## Gets the current NetworkState
func get_network_state() -> NetworkState:
	return _network_state


## Gets the current NetworkState, human readable
func get_network_state_human() -> String:
	return NetworkState.keys()[_network_state].capitalize()


## Returns the HiQNet Device Number of the remote device
func get_device_number() -> int:
	return _device_number


## Returns the serial number of the remote device
func get_serial_number() -> PackedByteArray:
	return _serial_number


## Returns the max message size of the remote device
func get_max_message_size() -> int:
	return _max_message_size


## Returns the keep alive time in ms
func get_keep_alive_time() -> int:
	return _keep_alive_time


## Returns the MAC Address of the remote device
func get_mac_address() -> PackedByteArray:
	return _mac_address


## Returns the DHCP state of the remote device
func get_dhcp() -> bool:
	return _dhcp


## Returns the IP Address of the remote device
func get_ip_address() -> PackedByteArray:
	return _ip_address


## Returns the IP Address of the remote device as a string
func get_ip_address_string() -> String:
	return HiQNetHeader.bytes_to_ip(_ip_address)


## Returns the subnet mask of the remote device
func get_subnet_mask() -> PackedByteArray:
	return _subnet_mask


## Returns the subnet mask of the remote device as a string
func get_subnet_mask_string() -> String:
	return HiQNetHeader.bytes_to_ip(_subnet_mask)


## Returns the network gateway of the remote device
func get_gateway() -> PackedByteArray:
	return _gateway


## Returns the network gateway of the remote device as a string
func get_gateway_string() -> String:
	return HiQNetHeader.bytes_to_ip(_gateway)


## Returns the UNIX timestamp of when this device last sent a discovery message
func get_last_seen() -> float:
	return _last_seen


## Gets the device name
func get_device_name() -> String:
	if _remote_device_manager_attributes.has(AttributeID.NameString):
		return type_convert(_remote_device_manager_attributes[AttributeID.NameString].value, TYPE_STRING)
	else:
		return ""


## Gets the disconnect allow state
func get_allow_disconnect() -> bool:
	return _allow_disonnect


## Gets the auto reconnect state
func get_auto_reconnect() -> bool:
	return _auto_reconnect


## Sets the disconnect allow state
func set_allow_disconnect(p_allow_disconnect: bool) -> void:
	_allow_disonnect = p_allow_disconnect


## Sets the auto reconnect state
func set_auto_reconnect(p_auto_reconnect: bool) -> void:
	_auto_reconnect = p_auto_reconnect


## Returns True if there is an active session to the remote device
func has_active_session() -> bool:
	return _remote_session_number != 0


## Checks if there is an active parameter subscriptions to the remote device
func is_subscribed_to(p_address: Array) -> bool:
	return p_address in _active_subscriptions


## Sets the current NetworkState
func _set_network_state(p_network_state: NetworkState) -> bool:
	if p_network_state == _network_state:
		return false
	
	_network_state = p_network_state
	network_state_changed.emit(_network_state)
	
	_log("Setting NetworkState to: ", NetworkState.keys()[_network_state])
	
	return true


## Logs a message to the console, with a prefix
func _log(a="", b="", c="", d="", e="", f="", g="") -> void:
	print("Device: ",  _device_number, " | ", a, b, c, d, e, f, g)
