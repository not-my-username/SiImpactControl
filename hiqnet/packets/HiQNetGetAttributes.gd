# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the HiQNet implementation for Godot, licensed under the LGPL v3.0 or later.
# See the LICENSE file for details.

class_name HiQNetGetAttributes extends HiQNetHeader
## Gets or Sets device attributes, use the FLAG_INFORMATION to make this a setter, otherwise this will get attributes


## Enum for AttributeID
enum AttributeID {
	ClassName 			= 0,	## Class name of the device
	NameString			= 1,	## Network name of the device
	Flags				= 2,	## Flags of the device
	SerialNumber		= 3,	## Serial Number of the device
	SoftwareVersion		= 4,	## Software version of the device
}


## List of attributes to get from the device
var get_attributes: Dictionary[int, Parameter]

## List of attributes to send to the device
var set_attributes: Dictionary[int, Parameter]


## Sets message type on creation
func _init() -> void:
	message_type = MessageType.GetAttributes


## Returns this HiQNetGetAttributes as a PackedByteArray
func _get_as_packet() -> PackedByteArray: 
	var packet: PackedByteArray = PackedByteArray()
	
	# Setter
	if is_information():
		packet.append_array(encode_parameters(set_attributes))
	
	# Getter
	else:
		packet.append_array(ba(len(get_attributes), 2)) 
		
		for attribute: Parameter in get_attributes.values():
			packet.append_array(ba(attribute.id, 2)) 
	
	return packet


## Decodes this HiQNetGetAttributes
func _phrase_packet(p_packet: PackedByteArray) -> void:
	p_packet = get_packet_body(p_packet)
	
	if len(p_packet) < 2:
		decode_error = DecodeError.LENGTH_INVALID
		printerr("DecodeError.LENGTH_INVALID")
		return
	
	# Setter
	if is_information():
		set_attributes = decode_parameters(p_packet)
	
	# Getter
	else:
		var num_attributes: int = (p_packet[0] << 8) | p_packet[1]
		
		if len(p_packet) < (num_attributes * 2) + 2:
			decode_error = DecodeError.LENGTH_INVALID
			printerr("DecodeError.LENGTH_INVALID")
			return
			
		for index: int in range(2, (num_attributes + 1) * 2, 2):
			var id: int = (p_packet[index] << 8) | p_packet[index+1]
			get_attributes[id] = Parameter.new(id)
