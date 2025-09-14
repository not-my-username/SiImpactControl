# Copyright (c) 2024 Liam Sherwin, All rights reserved.

class_name SiPanelSettings extends Control
## UI Panel for controlling settings for the SiImpactContol module


## SettingsModuleContainer VBox
@export var _settings_module_container: VBoxContainer

## The SiControlPanel
var _panel: SiControlPanel


## Sets the component
func set_panel(panel: SiControlPanel) -> void:
	_panel = panel
	if not is_instance_valid(panel):
		return
	
	for classname: String in panel.get_settings().keys():
		var new_module: SiPanelSettingsModule = load("res://components/Settings/ClassSettingsModule/SiPanelSettingsModule.tscn").instantiate()
		new_module.set_title(classname)
		
		var settings: Array = panel.get_settings()[classname].values()
		if settings:
			for setting: Dictionary in settings:
				if setting.data_type == TYPE_OBJECT:
					var custom_panel: Control = setting.custom_panel.instantiate()
					
					if custom_panel.has_method(setting.entry_point):
						custom_panel.get(setting.entry_point).call(panel)
					
					new_module.show_custom(custom_panel)
				else:
					new_module.show_setting(setting.setter, setting.getter, setting.signal, setting.data_type, setting.visual_line, setting.visual_name, setting.min, setting.max)
		else:
			new_module.set_disable(true)
		_settings_module_container.add_child(new_module)
