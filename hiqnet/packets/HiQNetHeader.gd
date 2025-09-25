# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the HiQNet implementation for Godot, licensed under the LGPL v3.0 or later.
# See the LICENSE file for details.

class_name HiQNetHeader extends RefCounted
## Represents a HiQNet packet header and provides encoding/decoding utilities.


## HiQNet version
const HIQNET_VERSION: int = 2 

## The length of DataType.LONG
const LONG_LENGTH: int = 4


## Message type enum
enum MessageType {
	NONE						=-0x0001,	## No Mesage specified
	DiscoInfo					= 0x0000,	## Discovery information
	GoodBye						= 0x0007,	## Goodbye message
	Hello						= 0x0008,	## Hello message
	Locate						= 0x0129,	## Locate message
	MultiParamSet				= 0x0100,	## Multi parameter set
	MultiParamGet				= 0x0103,	## Multi parameter get
	GetAttributes				= 0x010D,	## Get attributes
	GetVDList					= 0x011A,	## Get VD list
	ParameterSubscribeAll		= 0x0113,	## Subscribe all parameters
	ParameterUnSubscribeAll		= 0x0114,	## Unsubscribe all parameters
	Store						= 0x0124,	## Store command
	Recall						= 0x0125	## Recall command
}


## Data type enum
enum DataType {
	BYTE,						## Signed byte
	UBYTE,						## Unsigned byte
	WORD,						## Signed 16-bit
	UWORD,						## Unsigned 16-bit
	LONG,						## Signed 32-bit
	ULONG,						## Unsigned 32-bit
	FLOAT32,					## 32-bit float
	FLOAT64,					## 64-bit float
	BLOCK,						## Block of bytes
	STRING,						## String
	LONG64,						## Signed 64-bit
	ULONG64,					## Unsigned 64-bit
	NULL,						## Null DataType
}


## Flags enum (bit positions)
enum Flags {
	NONE						= 0,		 ## No Flags
	REQUEST_ACK					= (1 << 0),  ## Request acknowledgment
	ACKNOWLEDGEMENT				= (1 << 1),  ## Acknowledgement flag
	INFORMATION					= (1 << 2),  ## Information flag
	ERROR						= (1 << 3),  ## Error flag
	GUARANTEED					= (1 << 5),  ## Guaranteed delivery
	MULTIPART					= (1 << 6),  ## Multipart message
	SESSION_NUMBER				= (1 << 8)## Session number included
}


## Enum for DecodeError
enum DecodeError {
	NONE,						## No Error
	LENGTH_INVALID,				## The length of the message was not long enough to decode the required data
}


## Matches the MessageType enum to a class
static var ClassTypes: Dictionary[int, Script] = {
	MessageType.DiscoInfo: 				HiQNetDiscoInfo,
	MessageType.Hello: 					HiQNetHello,
	MessageType.GetAttributes:		 	HiQNetGetAttributes,
	MessageType.GoodBye: 				HiQNetGoodbye,
	MessageType.ParameterSubscribeAll: 	HiQNetParameterSubscribeAll,
	MessageType.MultiParamSet: 			HiQNetMultiParamSet
}


## HiQNet ID of this device
var source_device: int = 00000

## Source address of this device
var source_address: Array = [0, 0, 0, 0]  

## HiQNet ID of the destination device
var dest_device: int = 65535 

## Address of the destination device
var dest_address: Array = [0, 0, 0, 0] 

## Message type of this packet
var message_type: MessageType = MessageType.DiscoInfo  

## Bitmask of packet flags
var flags: int = 0  

## Number of network hops
var hop_count: int = 0x05 

## Packet debug sequence number
var sequence_number: int = 0x00

## Session number if flag set
var session_number: int = 0  

## Decode error of this message
var decode_error: DecodeError = DecodeError.NONE


## Creates a HiQNet header with the given message length
func get_as_packet() -> PackedByteArray:
	var header: PackedByteArray = PackedByteArray()
	var header_length: int = 25
	var message: PackedByteArray = _get_as_packet()
	var message_length: int = message.size()
	
	if (flags & Flags.SESSION_NUMBER) != 0:
		header_length += 2
	
	message_length += header_length
	
	header.append_array([HIQNET_VERSION])
	header.append(header_length)
	
	# Message length (4 bytes)
	header.append_array(ba(message_length, 4))
	
	# Source device and address
	header.append_array(ba(source_device, 2))
	header.append_array(source_address)
	
	# Destination device and address
	header.append_array(ba(dest_device, 2))
	header.append_array(dest_address)
	
	# Message type and flags
	header.append_array(ba(message_type, 2))
	header.append_array(ba(flags, 2))
	
	header.append_array([hop_count])
	header.append_array([0x00, sequence_number])
	
	# Session number if flag set
	if (flags & Flags.SESSION_NUMBER) != 0:
		header.append_array(ba(session_number, 2))
	
	header.append_array(message)
	return header


## Sets or clears the REQUEST_ACK flag
func set_request_ack(value: bool) -> void:
	if value:
		flags |= Flags.REQUEST_ACK
	else:
		flags &= ~Flags.REQUEST_ACK


## Sets or clears the ACKNOWLEDGEMENT flag
func set_acknowledgement(value: bool) -> void:
	if value:
		flags |= Flags.ACKNOWLEDGEMENT
	else:
		flags &= ~Flags.ACKNOWLEDGEMENT


## Sets or clears the INFORMATION flag
func set_information(value: bool) -> void:
	if value:
		flags |= Flags.INFORMATION
	else:
		flags &= ~Flags.INFORMATION


## Sets or clears the ERROR flag
func set_error(value: bool) -> void:
	if value:
		flags |= Flags.ERROR
	else:
		flags &= ~Flags.ERROR


## Sets or clears the GUARANTEED flag
func set_guaranteed(value: bool) -> void:
	if value:
		flags |= Flags.GUARANTEED
	else:
		flags &= ~Flags.GUARANTEED


## Sets or clears the MULTIPART flag
func set_multipart(value: bool) -> void:
	if value:
		flags |= Flags.MULTIPART
	else:
		flags &= ~Flags.MULTIPART


## Sets or clears the SESSION_NUMBER flag
func set_session_number(value: bool) -> void:
	if value:
		flags |= Flags.SESSION_NUMBER
	else:
		flags &= ~Flags.SESSION_NUMBER


## Returns true if REQUEST_ACK flag is set
func is_request_ack() -> bool:
	return (flags & Flags.REQUEST_ACK) != 0


## Returns true if ACKNOWLEDGEMENT flag is set
func is_acknowledgement() -> bool:
	return (flags & Flags.ACKNOWLEDGEMENT) != 0


## Returns true if INFORMATION flag is set
func is_information() -> bool:
	return (flags & Flags.INFORMATION) != 0


## Returns true if ERROR flag is set
func is_error() -> bool:
	return (flags & Flags.ERROR) != 0


## Returns true if GUARANTEED flag is set
func is_guaranteed() -> bool:
	return (flags & Flags.GUARANTEED) != 0


## Returns true if MULTIPART flag is set
func is_multipart() -> bool:
	return (flags & Flags.MULTIPART) != 0


## Returns true if SESSION_NUMBER flag is set
func is_session_number() -> bool:
	return (flags & Flags.SESSION_NUMBER) != 0


## Decodes header from a packet into a HiQNetHeader object
static func phrase_packet(p_packet: PackedByteArray) -> HiQNetHeader:
	if not is_packet_valid(p_packet):
		return null
	
	var p_message_type = (p_packet[18] << 8) | p_packet[19]
	var message: HiQNetHeader
	
	if p_message_type not in ClassTypes:
		return null
	
	message = ClassTypes[p_message_type].new()
	
	if len(p_packet) < 24:
		message.decode_error = DecodeError.LENGTH_INVALID
		printerr("DecodeError.LENGTH_INVALID")
		return
	
	message.source_device = (p_packet[6] << 8) | p_packet[7]
	message.source_address = PackedByteArray(p_packet.slice(8, 12))
	
	message.dest_device = (p_packet[12] << 8) | p_packet[13]
	message.dest_address = PackedByteArray(p_packet.slice(14, 18))
	
	message.flags = (p_packet[20] << 8) | p_packet[21]
	message.hop_count = p_packet[22]
	message.sequence_number = (p_packet[23] << 8) | p_packet[24]
	
	var offset: int = 25
	
	if (message.flags & Flags.ERROR):
		var length: int = (p_packet.get(offset) << 8) | p_packet.get(offset + 1)
		offset += 2 + 2 + length
	
	if (message.flags & Flags.MULTIPART):
		offset += 6
	
	if (message.flags & Flags.SESSION_NUMBER):
		message.session_number = (p_packet.get(offset) << 8) | p_packet.get(offset + 1)
	
	message._phrase_packet(p_packet)
	return message


## Returns packet body (without header)
static func get_packet_body(packet: PackedByteArray) -> PackedByteArray:
	var header_length: int = packet[1]
	return packet.slice(header_length)


## Converts an integer to a PackedByteArray
static func ba(value: int, byte_count: int = 4) -> PackedByteArray:
	var packed: PackedByteArray = PackedByteArray()
	for i in range(byte_count):
		packed.append((value >> (8 * (byte_count - 1 - i))) & 0xFF)
	return packed


## Converts an IP string to a PackedByteArray
static func ip_to_bytes(ip: String) -> PackedByteArray:
	var bytes: PackedByteArray = PackedByteArray()
	for part: String in ip.split("."):
		bytes.append(int(part))
	return bytes


## Converts an IP byte array to a string
static func bytes_to_ip(bytes: PackedByteArray) -> String:
	var ip: String = ""
	for byte: int in bytes:
		ip += str(byte) + "."
	return ip.substr(0, ip.length() - 1)


## Checks if packet is valid
static func is_packet_valid(packet: PackedByteArray) -> bool:
	return packet.size() >= 25 and packet[0] == HIQNET_VERSION


## Decodes a HiQnet parameter packet into a dictionary of Parameter objects
static func decode_parameters(p_packet: PackedByteArray) -> Dictionary[int, Parameter]:
	var parameters: Dictionary[int, Parameter] = {}
	
	# The first 2 bytes are the number of parameters (big-endian)
	var num_parameters: int = (p_packet[0] << 8) | p_packet[1]
	var offset: int = 2  # Start reading after the count
	
	for i in range(num_parameters):
		# Each parameter starts with a 2-byte Parameter ID (big-endian)
		if offset + 2 > p_packet.size():
			break
		var pid: int = (p_packet[offset] << 8) | p_packet[offset + 1]
		offset += 2
		
		# Next byte is the DataType
		if offset + 1 > p_packet.size():
			break
		var data_type: DataType = p_packet[offset] as DataType
		offset += 1
		
		match data_type:
			DataType.STRING:
				# String length is 2 bytes
				if offset + 2 > p_packet.size():
					break
				
				var string_length: int = (p_packet[offset] << 8) | p_packet[offset + 1]
				offset += 2
				
				# Make sure the packet has enough bytes
				if offset + string_length > p_packet.size():
					break
				
				var result: String = ""
				
				for index: int in range(0, string_length, 2):
					result += char((p_packet[offset + index] << 8) | p_packet[offset + 1 + index])
				
				offset += string_length
				parameters[pid] = Parameter.new(pid, DataType.STRING, result)
			
			DataType.BLOCK:
				# Block length is 2 bytes (big-endian)
				if offset + 2 > p_packet.size():
					break
				var block_length: int = (p_packet[offset] << 8) | p_packet[offset + 1]
				offset += 2
				
				# Make sure the packet has enough bytes
				if offset + block_length > p_packet.size():
					break
				
				var block_value: PackedByteArray = p_packet.slice(offset, offset + block_length)
				offset += block_length
				
				parameters[pid] = Parameter.new(pid, DataType.BLOCK, block_value)
			
			DataType.LONG:
				# Long value is 4 bytes (big-endian, signed 32-bit)
				if offset + LONG_LENGTH > p_packet.size():
					break
				var value: int = (p_packet[offset] << 24) | (p_packet[offset + 1] << 16) | (p_packet[offset + 2] << 8) | p_packet[offset + 3]

				# Handle negative numbers (sign extension for 32-bit)
				if value & 0x80000000:
					value -= 0x100000000

				offset += 4
				parameters[pid] = Parameter.new(pid, DataType.LONG, value)
	
	return parameters


## Encodes parameters into a packet with null-terminated strings
static func encode_parameters(p_parameters: Dictionary[int, Parameter]) -> PackedByteArray:
	var packet: PackedByteArray= PackedByteArray()
	
	# Write number of parameters (2 bytes, big-endian)
	packet.append_array(ba(p_parameters.size(), 2))
	
	# Encode each parameter
	for pid in p_parameters.keys():
		var param: Parameter = p_parameters[pid]
		
		# Write PID (2 bytes, big-endian)
		packet.append_array(ba(pid, 2))
		
		# Write DataType (1 byte)
		packet.append(param.data_type)
		
		match param.data_type:
			DataType.STRING:
				var ascii: PackedByteArray = str(param.value).to_ascii_buffer()
				var length: int = ((len(ascii) * 2) + 2) if ascii else 0
				packet.append_array(ba(length, 2)) # String Length
				
				for character: int in ascii:
					packet.append_array(ba(character, 2)) # String Byte
				
				if length:
					packet.append_array([0x00, 0x00]) # Append null terminator (2 bytes)
			
			DataType.BLOCK:
				printerr("DataType.BLOCK Not Supported")
				#var block_bytes: PackedByteArray = param.value
				#
				## Write length (2 bytes)
				#packet.append_array(ba(block_bytes.size(), 2))
				#
				## Write block data
				#packet.append_array(block_bytes)
			
			DataType.LONG:
				var value: int = int(param.value)
				
				# Write 4-byte signed integer
				packet.append_array(ba(value, 4))
	
	return packet


## Override this function to provide a packet payload
func _get_as_packet() -> PackedByteArray:
	return []


## Override this function to provide a decode a packet
@warning_ignore("unused_parameter")
func _phrase_packet(p_packet: PackedByteArray) -> void:
	pass
