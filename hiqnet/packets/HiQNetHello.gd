# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the HiQNet implementation for Godot, licensed under the LGPL v3.0 or later.
# See the LICENSE file for details.

class_name HiQNetHello extends HiQNetHeader
## HiQNet HiQNetHello packet


## The session number of the device
var device_session_number: int = 0

## Supported Flags
var supported_flags: int = 0x01FF


## Sets message type on creation
func _init() -> void:
	message_type = MessageType.Hello


## Returns this DiscoInfo object as a network packet
func _get_as_packet() -> PackedByteArray:
	var message: PackedByteArray = PackedByteArray()
	
	message.append_array(ba(device_session_number, 2))
	message.append_array(ba(supported_flags, 2))
	
	return message


## Decodes this HiQNetDiscoInfo
func _phrase_packet(p_packet: PackedByteArray) -> void:
	p_packet = get_packet_body(p_packet)
	
	if len(p_packet) > 4:
		decode_error = DecodeError.LENGTH_INVALID
		return
	
	device_session_number = (p_packet[0] << 8) | p_packet[1]
	supported_flags = (p_packet[2] << 8) | p_packet[3]
