# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the HiQNet implementation for Godot, licensed under the LGPL v3.0 or later.
# See the LICENSE file for details.

class_name HiQNetParameterSubscribeAll extends HiQNetHeader
## HiQNet HiQNetParameterSubscribeAll packet


## Enum for  SubscriptionType
enum SubscriptionTypeFlags {
	ALL					= 1,
	NONE_SENSOR			= 2,
	SENSOR				= 4,
}

## Enum for SubscriptionFlags
enum SubscriptionFlags {
	SEND_INIT_UPDATE	= 1,
}

## The SubscriptionType to use
var subscription_type: int = SubscriptionTypeFlags.ALL | SubscriptionTypeFlags.SENSOR

## Sensor update speed ms
var sensor_rate: int = 0

## Enum for SubscriptionFlags
var subscription_flags: int = SubscriptionFlags.SEND_INIT_UPDATE


## Sets message type on creation
func _init() -> void:
	message_type = MessageType.ParameterSubscribeAll


## Returns this HiQNetParameterSubscribeAll object as a network packet
func _get_as_packet() -> PackedByteArray:
	var message: PackedByteArray = PackedByteArray()
	
	message.append_array(ba(dest_device, 2))
	message.append_array(dest_address)
	
	message.append_array(ba(subscription_type, 1))
	message.append_array(ba(sensor_rate, 2))
	message.append_array(ba(subscription_flags, 2))
	
	return message


## Decodes this HiQNetParameterSubscribeAll
func _phrase_packet(p_packet: PackedByteArray) -> void:
	p_packet = get_packet_body(p_packet)
	
	if len(p_packet) < 5:
		decode_error = DecodeError.LENGTH_INVALID
		printerr("DecodeError.LENGTH_INVALID")
		return
	
	subscription_type = p_packet[0] as SubscriptionTypeFlags
	sensor_rate = (p_packet[1] << 8) | p_packet[2]
	subscription_flags = (p_packet[3] << 8) | p_packet[4] as SubscriptionFlags
