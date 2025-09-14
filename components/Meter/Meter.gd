class_name Meter extends Control


func set_label(text: String) -> void:
	$Name.text = text


func get_label() -> String:
	return $Name.text


func set_value(value: float) -> void:
	$VU.value = value

	if get_label() == "CH 33":
		print(value)

func set_gate_color(gate_color: Color) -> void:
	$PanelContainer/Gate.color = gate_color


func set_comp_value(comp_amount: int) -> void:
	$Comp.value = comp_amount
