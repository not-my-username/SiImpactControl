# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the HiQNet implementation for Godot, licensed under the LGPL v3.0 or later.
# See the LICENSE file for details.

class_name HiQNetMultiParamSet extends HiQNetHeader
## Sets parameters on a Virtual Device or Object


## List of parameters to send to the device
var set_parameters: Dictionary[int, Parameter]


## Sets message type on creation
func _init() -> void:
	message_type = MessageType.MultiParamSet


## Returns this HiQNetGetAttributes as a PackedByteArray
func _get_as_packet() -> PackedByteArray: 
	var packet: PackedByteArray = PackedByteArray()
	
	packet.append_array(encode_parameters(set_parameters))
	
	return packet


## Decodes this HiQNetGetAttributes
func _phrase_packet(p_packet: PackedByteArray) -> void:
	p_packet = get_packet_body(p_packet)
	
	if not p_packet:
		return
	
	set_parameters = decode_parameters(p_packet)
