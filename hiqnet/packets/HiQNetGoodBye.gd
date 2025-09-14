# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the HiQNet implementation for Godot, licensed under the LGPL v3.0 or later.
# See the LICENSE file for details.

class_name HiQNetGoodbye extends HiQNetHeader
## HiQNet HiQNetGoodbye packet


## The Device number of the device ending the session
var device_number: int = 0


## Sets message type on creation
func _init() -> void:
	message_type = MessageType.GoodBye


## Returns this HiQNetGoodbye object as a network packet
func _get_as_packet() -> PackedByteArray:
	var message: PackedByteArray = PackedByteArray()
	
	message.append_array(ba(device_number, 2))
	
	return message


## Decodes this HiQNetGoodbye
func _phrase_packet(p_packet: PackedByteArray) -> void:
	p_packet = get_packet_body(p_packet)
	
	if len(p_packet) > 2:
		decode_error = DecodeError.LENGTH_INVALID
		return
	
	device_number = (p_packet[0] << 8) | p_packet[1]
