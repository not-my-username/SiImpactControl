# Copyright (c) 2025 Liam Sherwin. All rights reserved.
# This file is part of the HiQNet implementation for Godot, licensed under the LGPL v3.0 or later.
# See the LICENSE file for details.

class_name HiQNetParameterSubscribeAll extends HiQNetHeader
## HiQNet HiQNetParameterSubscribeAll packet


## Enum for  SubscriptionType
enum SubscriptionType {
	ALL,
	NONE_SENSOR,
	SENSOR
}

## Enum for SubscriptionFlags
enum SubscriptionFlags {
	SEND_INIT_UPDATE
}

## The SubscriptionType to use
var subscription_type: SubscriptionType = SubscriptionType.ALL

## Sensor update speed ms
var sensor_rate: int = 0

## Enum for SubscriptionFlags
var subscription_flags: SubscriptionFlags = SubscriptionFlags.SEND_INIT_UPDATE


## Sets message type on creation
func _init() -> void:
	message_type = MessageType.ParameterSubscribeAll


## Returns this DiscoInfo object as a network packet
func _get_as_packet() -> PackedByteArray:
	var message: PackedByteArray = PackedByteArray()
	
	message.append_array(ba(dest_device, 4))
	message.append_array(dest_address)
	
	message.append_array(ba(subscription_type, 1))
	message.append_array(ba(sensor_rate, 2))
	message.append_array(ba(subscription_flags, 2))
	
	return message


## Decodes this HiQNetDiscoInfo
func _phrase_packet(p_packet: PackedByteArray) -> void:
	p_packet = get_packet_body(p_packet)
	
	if len(p_packet) > 12:
		decode_error = DecodeError.LENGTH_INVALID
		return
	
	subscription_type = p_packet[0]
	sensor_rate = (p_packet[1] << 8) | p_packet[2]
	subscription_flags = (p_packet[3] << 8) | p_packet[4]
