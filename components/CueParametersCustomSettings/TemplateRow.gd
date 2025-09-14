# Copyright (c) 2024 Liam Sherwin
# All rights reserved.

class_name SiCueParametersTemplateRow extends PanelContainer
## Template row for SiCueParamaterCustomSettings


## The VDInput for setting the virtual device
@export var vd_input: VDInput

## The SpinBox for from to
@export var pid_from: SpinBox

## The SpinBox for PID to
@export var pid_to: SpinBox

## The delete button
@export var delete: Button


## If of this row
var id: int = -1
