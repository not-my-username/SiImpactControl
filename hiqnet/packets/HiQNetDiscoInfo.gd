# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the HiQNet implementation for Godot, licensed under the LGPL v3.0 or later.
# See the LICENSE file for details.

class_name HiQNetDiscoInfo extends HiQNetHeader
## HiQNet Discovery Info packet


## The cost of this network packet
var cost: int = 1

## The serial number of this device
var serial_number: PackedByteArray = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

## Mac address of sourse deivce
var mac_address: PackedByteArray = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

## The max message size this device can handle
var max_size: int = 0x00100000

## Keep alive time for this device
var keep_alive: int = 0x2710

## DHCP state
var dhcp: bool = true

## Ip_address of source device
var ip_address: PackedByteArray = [192, 168, 1, 1]

## Network subnet mask
var subnet_mask: PackedByteArray = [0xff, 0xff, 0xff, 0x00]

## Network gateway
var gateway: PackedByteArray = [0x00, 0x00, 0x00, 0x00] 


## Sets message type on creation
func _init() -> void:
	message_type = MessageType.DiscoInfo


## Returns this DiscoInfo object as a network packet
func _get_as_packet() -> PackedByteArray:
	var message: PackedByteArray = PackedByteArray()
	
	message.append_array(ba(source_device, 2))		## Source Device ID
	message.append(cost) 							## Cost
	
	message.append_array([0x00, 0x10]) 				## Serial Number Length
	message.append_array(serial_number)				## Serial Number
	
	message.append_array(ba(max_size, 4)) 			## Max Size
	message.append_array(ba(keep_alive, 2)) 		## Keep Alive
	message.append(1) 								## Network ID: TCP/IP
	
	message.append_array(mac_address)				## MAC Address
	message.append(int(dhcp))						## DHCP = true
	message.append_array(ip_address)				## IP Address
	
	message.append_array(subnet_mask)				## Subnet Mask
	message.append_array(gateway)					## Gateway
	
	return message


## Decodes this HiQNetDiscoInfo
func _phrase_packet(p_packet: PackedByteArray) -> void:
	p_packet = get_packet_body(p_packet)
	
	if len(p_packet) < 46:
		decode_error = DecodeError.LENGTH_INVALID
		printerr("DecodeError.LENGTH_INVALID")
		return
	
	cost = p_packet[2]
	
	var serial_length: int = (p_packet[3] << 8) | p_packet[4]
	serial_number = p_packet.slice(5, serial_length + 2)
	
	max_size = (p_packet[21] << 32) | (p_packet[22] << 16) | (p_packet[23] << 8) | p_packet[24]
	keep_alive = (p_packet[25] << 8) | p_packet[26]
	#packet[27] Network ID, discard
	
	mac_address = PackedByteArray([p_packet[28], p_packet[29], p_packet[30], p_packet[31], p_packet[32], p_packet[33]])
	dhcp = p_packet[34] == 1
	
	ip_address = PackedByteArray([p_packet[35], p_packet[36], p_packet[37], p_packet[38]])
	subnet_mask = PackedByteArray([p_packet[39], p_packet[40], p_packet[41], p_packet[42]])
	gateway = PackedByteArray([p_packet[43], p_packet[44], p_packet[45], p_packet[46]])
