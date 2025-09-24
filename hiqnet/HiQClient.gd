# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the HiQNet implementation for Godot, licensed under the LGPL v3.0 or later.
# See the LICENSE file for details.

class_name HiQNetClient extends Node
## Global class for HiQNet device discovery


## Emitted when the network state is changed
signal network_state_changed(new_state: NetworkState)

## Emitted when the discovery state is changed
signal discovery_state_changed(new_state)

## Emitted when a device is discovered on the network
signal device_discovered(device: HiQNetDevice)


## The TCP/UDP port for HiQNet
const HIQNET_PORT: int = 3804

## Device number to use when sending a message to broadcast
const DEVICE_NUMBER_BROADCAST: int = 65535


## Enum for the NetworkState
enum NetworkState {
	OFFLINE,			## Node is offline
	ONLINE				## Node is online
}

## Enum for the DiscoveryState
enum DiscoveryState {
	DISABLE,			## Don't send any discovery
	ONLY_REPLY,			## Only reply to discovery
	ENABLED,			## Send discovery at a set interval
}

## Copy of HiQNetHeader.Flags
const Flags: Dictionary[String, int] = HiQNetHeader.Flags


## HiQNetConfig object
class HiQNetConfig extends Object:
	## Automatically takes this device online at launch
	static var auto_start: bool = false
	
	## Default IP addres
	static var ip_address: String = "127.0.0.1"
	
	## Default network broadcast address
	static var network_broadcast: String = "192.168.1.255"
	
	## HiQNet Device Number
	static var device_number: int = randi_range(1, 2**16 - 1-1)
	
	## Gets all remote device names as soon as they are found on the network
	static var fetch_name_on_disco: bool = false
	
	## Loads config from a file
	static func load_config(p_path: String) -> bool:
		var script: Variant = load(p_path)
		
		if script is not GDScript or script.get("config") is not Dictionary:
			return false
		
		var config: Dictionary = script.get("config")
		
		auto_start = type_convert(config.get("auto_start", auto_start), TYPE_BOOL)
		ip_address = type_convert(config.get("ip_address", ip_address), TYPE_STRING)
		network_broadcast = type_convert(config.get("network_broadcast", network_broadcast), TYPE_STRING)
		device_number = type_convert(config.get("device_number", device_number), TYPE_INT)
		fetch_name_on_disco = type_convert(config.get("fetch_name_on_disco", fetch_name_on_disco), TYPE_BOOL)
		
		return true


## -------------------
## Network Connections
## -------------------

## Current network state
var _network_state: NetworkState = NetworkState.OFFLINE

## The PacketPeerUDP for TX/RX broadcast
var _udp_broadcast: PacketPeerUDP = PacketPeerUDP.new()

## The TCPServer for incomming connections
var _tcp_server: TCPServer = TCPServer.new()

## Stores all current TCP streams
var _stream_peers: Array[StreamPeerTCP]

## IP Address of this device
var _ip_address: PackedByteArray = [0,0,0,0]

## Network Broacast address
var _broadcast_address: PackedByteArray = [0,0,0,0]

## Mac Address of this device
#var _mac_address: PackedByteArray = [0x00, 0x17, 0x24, 0x82, 0x62, 0x63]
var _mac_address: PackedByteArray = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

## Subnet Mask of this device
var _subnet_mask: PackedByteArray = [0xff, 0xff, 0xff, 0x00]


## ----------------
## Discovery Config
## ----------------

## Discovery state
var _discovery_state: DiscoveryState = DiscoveryState.ENABLED

## Discovery time interval in seconds
var _discovery_interval: int = 5

## The Timer node used for discovery 
var _discovery_timer: Timer = Timer.new()


## -------------
## Device Config
## -------------

## HiQNet device number of this device
var _device_number: int = 12345

## Serial Number of this device
#var _serial_number: PackedByteArray = [0x53, 0x69, 0x43, 0x6f, 0x6d, 0x70, 0x61, 0x63, 0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
var _serial_number: PackedByteArray = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

## Dictionary containing all the HiQNetDevices that have been discovred but not yet connected
var _discovered_devices: Dictionary[int, HiQNetDevice]

## Dictionary containing all the HiQNetDevices that have been connected to
var _connected_devices: Dictionary[int, HiQNetDevice]


## Init
func _init() -> void:
	HiQNetConfig.load_config("res://HiQNetConfig.gd")
	
	_device_number = HiQNetConfig.device_number
	_ip_address = HiQNetHeader.ip_to_bytes(HiQNetConfig.ip_address)
	_broadcast_address = HiQNetHeader.ip_to_bytes(HiQNetConfig.network_broadcast)
	
	_udp_broadcast.set_broadcast_enabled(true)


## Ready
func _ready() -> void:
	_discovery_timer.wait_time = _discovery_interval
	_discovery_timer.autostart = true
	_discovery_timer.timeout.connect(func ():
		if _discovery_state == DiscoveryState.ENABLED and _network_state == NetworkState.ONLINE:
			send_discovery_broadcast()
	)
	
	add_child(_discovery_timer)
	
	if HiQNetConfig.auto_start:
		go_online()


## Process
func _process(_delta: float) -> void:
	while _udp_broadcast.get_available_packet_count() > 0:
		var packet: PackedByteArray = _udp_broadcast.get_packet()
		var message: HiQNetHeader = HiQNetHeader.phrase_packet(packet)
		
		handle_message(message)
	
	if _tcp_server.is_connection_available():
		var stream: StreamPeerTCP = _tcp_server.take_connection()
		_stream_peers.append(stream)
	
	for stream: StreamPeerTCP in _stream_peers.duplicate():
		stream.poll()
		
		if stream.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			while stream.get_available_bytes() > 0:
				var packet: PackedByteArray = stream.get_data(stream.get_available_bytes())[1]
				while HiQNetHeader.is_packet_valid(packet):
					var length: int = (packet[2] << 32) | (packet[3] << 16) | (packet[4] << 8) | packet[5]
					var sliced_packet: PackedByteArray = packet.slice(0, length)
					
					handle_message(HiQNetHeader.phrase_packet(sliced_packet), stream)
					packet = packet.slice(length)


## Handles an incomming message
func handle_message(p_message: HiQNetHeader, p_stream_peer: StreamPeerTCP = null) -> void:
	if not is_instance_valid(p_message) or p_message.source_device == _device_number or p_message.dest_device not in [_device_number, DEVICE_NUMBER_BROADCAST]:
		return
	
	match p_message.message_type:
		HiQNetHeader.MessageType.DiscoInfo:
			if not has_seen_device(p_message.source_device):
				var new_device: HiQNetDevice = HiQNetDevice.create_from_discovery(p_message)
				add_child(new_device)
				
				if HiQNetConfig.fetch_name_on_disco:
					new_device.send_get_attributes([HiQNetGetAttributes.AttributeID.NameString], HiQNetDevice.TransportType.UDP)
				
				_discovered_devices[p_message.source_device] = new_device
				device_discovered.emit(new_device)
	
	var device: HiQNetDevice = get_device_from_number(p_message.source_device)
	
	if is_instance_valid(device):
		if p_stream_peer:
			device.use_stream(p_stream_peer)
		
		device.handle_message(p_message)


## Takes this HiQNetClient online
func go_online() -> bool:
	if _network_state == NetworkState.ONLINE:
		return false
	
	_udp_broadcast.set_dest_address(HiQNetHeader.bytes_to_ip(_broadcast_address), HIQNET_PORT)
	_udp_broadcast.bind(HIQNET_PORT)
	
	_tcp_server.listen(HIQNET_PORT, HiQNetHeader.bytes_to_ip(_ip_address))
	
	if _discovery_state == DiscoveryState.ENABLED:
		send_discovery_broadcast()
	
	_set_network_state(NetworkState.ONLINE)
	return true


## Takes this HiQNetClient offline
func go_offline() -> bool:
	if _network_state == NetworkState.OFFLINE:
		return false
	
	_udp_broadcast.close()
	_tcp_server.stop()
	
	_set_network_state(NetworkState.OFFLINE)
	return true


## Auto fill the infomation in a HiQNetHeadder for sending to broadcast
func auto_full_headder_broadcast(p_headder: HiQNetHeader, p_flags: HiQNetHeader.Flags = HiQNetHeader.Flags.NONE) -> HiQNetHeader:
	p_headder.source_device = _device_number
	p_headder.source_address = [0, 0, 0, 0]
	p_headder.dest_device = 65535
	p_headder.dest_address = [0, 0, 0, 0]
	p_headder.flags = p_flags
	
	return p_headder


## Sends a discovery packet to broadcast
func send_discovery_broadcast() -> Error:
	var disco: HiQNetDiscoInfo = auto_full_headder_broadcast(HiQNetDiscoInfo.new())
	
	disco.serial_number = _serial_number
	disco.mac_address = _mac_address
	disco.ip_address = _ip_address
	disco.subnet_mask = _subnet_mask
	
	return _udp_broadcast.put_packet(disco.get_as_packet())


## Returns the IP Address of this device
func get_ip_address() -> PackedByteArray:
	return _ip_address


## Returns the network broadcast address
func get_broadcast_address() -> PackedByteArray:
	return _broadcast_address


## Returns the MAC Address of this device
func get_mac_address() -> PackedByteArray:
	return _mac_address


## Returns the Subnet Mask of this device
func get_subnet_mask() -> PackedByteArray:
	return _subnet_mask


## Returns the Serial Number of this device
func get_serial_number() -> PackedByteArray:
	return _serial_number


## Gets the device number for this device
func get_device_number() -> int:
	return _device_number


## Returns a device from the given device number, or null
func get_device_from_number(p_device_number: int) -> HiQNetDevice:
	return _connected_devices.get(p_device_number, _discovered_devices.get(p_device_number, null))


## Sets the discovery state
func set_discovery_state(p_discovery_state: DiscoveryState) -> bool:
	if p_discovery_state == _discovery_state:
		return false
	
	_discovery_state = p_discovery_state
	discovery_state_changed.emit(_discovery_state)
	
	return true


## Sets the Ip Address
func set_ip_address(p_ip_address: String) -> void:
	if _network_state != NetworkState.OFFLINE:
		return
	
	_ip_address = HiQNetHeader.ip_to_bytes(p_ip_address)


## Sets the Ip Address
func set_broadcast_address(p_broadcast_address: String) -> void:
	if _network_state != NetworkState.OFFLINE:
		return
	
	_broadcast_address = HiQNetHeader.ip_to_bytes(p_broadcast_address)


## Sets the device number
func set_device_number(p_device_number: int) -> void:
	if _network_state != NetworkState.OFFLINE:
		return
	
	_device_number = p_device_number


## Returns true if the given device number has been seen on the network
func has_seen_device(p_device_number: int) -> bool:
	return p_device_number in _discovered_devices or p_device_number in _connected_devices


## Sets the current NetworkState
func _set_network_state(p_network_state: NetworkState) -> bool:
	if p_network_state == _network_state:
		return false
	
	_network_state = p_network_state
	network_state_changed.emit(_network_state)
	
	return true
