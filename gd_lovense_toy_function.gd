@tool
@icon("GDLovense.webp")
class_name GDLovenseToyFunction
extends Node


## Node used to periodically send Function commands to a certain toy type.


## Lovense connection Node to use when sending periodic commands.
@export var gd_lovense: GDLovense


## Toy types to send commands for. Allows to have several Nodes working independently for different toy types.[br]
## Keep in mind some toys can have several usages, so commands could overlap.
@export_flags("Male Masturbator:1", "Cockring:2", "Prostate Massor:4", "Anal Plug:8", "Clitoris Vibe:16", "Dildo:32", "Nipple Clamp:64", "All:127") var toy_type: int:
	set(new_toy_type):
		toy_type = new_toy_type
		functions.clear()
		_set_functions_list()
		notify_property_list_changed()


## Frequency to send periodic commands at, in Hertz.[br]
## Higher frequency allows to better match the AnimationPlayer curve, but increases resource consumption.
@export_range(0.0, 20.0) var frequency: float = 5.0


## Contains the values for all toy functions.[br]
## [color=red]Internal usage only, it is used for the editor panel.[/color]
var functions: Dictionary[StringName, Variant] = {}


## Last sync time, to process the frequency.
var last_sync: float = 0.0


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	for function: StringName in functions:
		functions[function] = 0.0
	await gd_lovense.set_toys_values_by_type(toy_type, functions)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not is_instance_valid(gd_lovense):
		return
	last_sync += delta
	if last_sync >= 1.0 / frequency:
		last_sync = 0.0
		await gd_lovense.set_toys_values_by_type(toy_type, functions)


func _get(property: StringName) -> Variant:
	if property not in functions:
		return null
	return functions[property]


func _set(property: StringName, value: Variant) -> bool:
	if property in functions:
		if typeof(value) not in [TYPE_FLOAT, TYPE_INT]:
			push_error("GDLovenseToyFunction properties expect to be floats.")
			return true
		functions[property] = clampf(float(value), 0.0, 1.0)
		return true
	return false


func _set_functions_list() -> void:
	var added_toys: Array[String] = []
	var added_functions: Array[int] = []

	for type: GDLovenseToy.Types in GDLovenseToy.Types.values():
		if toy_type & type > 0:
			for toy_name: String in GDLovenseToy.TYPES_STRINGS:
				if GDLovenseToy.TYPES_STRINGS[toy_name] & type > 0:
					added_toys.append(toy_name)

	for toy: String in added_toys:
		for function: GDLovenseToy.Functions in GDLovenseToy.Functions.values():
			if function not in added_functions and GDLovenseToy.TOYS_FUNCTIONS[toy] & function > 0:
				added_functions.append(function)

	for function: int in added_functions:
		var function_name: StringName = GDLovenseToy.FUNCTIONS_STRINGS[function].to_lower()
		if function_name not in functions:
			functions[function_name] = 0.0


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	for function: StringName in functions:
		properties.append({
			"name": function,
			"type": TYPE_FLOAT,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1",
		})

	return properties


func _property_can_revert(property: StringName) -> bool:
	return property in functions


func _property_get_revert(property: StringName) -> Variant:
	if property in functions:
		return 0.0
	return null
