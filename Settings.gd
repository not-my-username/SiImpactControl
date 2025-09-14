# Copyright (c) 2024 Liam Sherwin, All rights reserved.

class_name SiSettingsControl extends SiControlPanel
## UI Control panel for managing settings


## The TabContainer for settings tabs
@export var _tab_container: TabContainer

## FileDialog for saving and loading files
@export var _file_dialog: FileDialog

## List of panels to show settings for
@export var panels: Array[SiControlPanel]


## File mode
var _file_mode: FileDialog.FileMode


func _ready() -> void:
	register_setting("Save / Load", "save_file", save_file_pressed, Callable(), Signal(), TYPE_NIL, 0, "Save File")
	register_setting("Save / Load", "load_file", load_file_pressed, Callable(), Signal(), TYPE_NIL, 0, "Load File")
	
	await get_tree().process_frame
	
	for panel: SiControlPanel in panels:
		var new_tab: VBoxContainer = VBoxContainer.new()
		var new_component_settings: SiPanelSettings = load("res://components/Settings/SiPanelSettings.tscn").instantiate()
		
		new_tab.set_name(panel.name)
		new_component_settings.set_panel(panel)
		
		new_tab.add_child(new_component_settings)
		_tab_container.add_child(new_tab)


## Called when the save buton is pressed
func save_file_pressed() -> void:
	_file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_file_dialog.popup()


## Called when the load button is pressed
func load_file_pressed() -> void:
	_file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.popup()


## Returns a serialized copy of this SiImpactControl 
func serialize_si_controller() -> Dictionary:
	var saved_data: Dictionary = {
		"panels": {}
	}
	
	for panel: SiControlPanel in panels:
		saved_data.panels[panel.name] = panel.save()
	
	return saved_data


## Loads this SiImpactControl from serialize_si_controller()
func load_si_controller(saved_data: Dictionary) -> void:
	var saved_panels: Dictionary = type_convert(saved_data.get("panels"), TYPE_DICTIONARY)
	
	if saved_panels:
		for panel: SiControlPanel in panels:
			if saved_panels.has(panel.name):
				panel.reset()
				panel.load(saved_panels[panel.name])


## Called when a file is selected in the file dialog
func _on_file_dialog_file_selected(path: String) -> void:
	match _file_mode:
		FileDialog.FILE_MODE_SAVE_FILE:
			Utils.save_json_to_file(_file_dialog.current_dir, _file_dialog.current_file, serialize_si_controller(), true)
		
		FileDialog.FILE_MODE_OPEN_FILE:
			var saved_data: Variant = str_to_var(FileAccess.open(_file_dialog.current_path, FileAccess.READ).get_as_text())
			if saved_data is Dictionary:
				load_si_controller(saved_data)
