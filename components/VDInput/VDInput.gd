class_name VDInput extends LineEdit
## Script to support entering HiQNet Virtual Device numbers


## Emitted when the vd is changed
signal vd_changed(vd: Array)


## RegEx to use to check the text
var _regex = RegEx.new()


func _ready() -> void:
	_regex.compile(r"^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])){3}$")
	
	max_length = len("255.255.255.255")
	if not text:
		text = "0.0.0.0"
	
	text_changed.connect(_check_text)
	text_submitted.connect(func (new_text: String): vd_changed.emit(get_vd()))
	
	_check_text(text)


## Sets the VD
func set_vd(vd: Array) -> void:
	text = ".".join(PackedStringArray(vd))


## Gets the inputted virtual device
func get_vd() -> Array[int]:
	if not len(text.split(".")) >= 4:
		return []
	
	var vd: Array[int] = []
	
	for byte: String in text.split("."):
		vd.append(clamp(int(byte), 0, 255))
	
	return vd


## Checks the text
func _check_text(new_text: String) -> bool:
	var result = _regex.search(new_text)
	
	if result and result.get_string():
		remove_theme_color_override("font_color")
		return true
	else:
		add_theme_color_override("font_color", Color.RED)
		return false
