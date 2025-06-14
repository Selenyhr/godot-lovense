@icon("GDLovense.webp")
class_name GDLovenseToy
extends RefCounted


## Describes a Lovense toy, with its functions, and its intended use.


## Toy functions enum, to be used as flags.
enum Functions {
	VIBRATE = 1,
	ROTATE = 2,
	PUMP = 4,
	THRUSTING = 8,
	FINGERING = 16,
	SUCTION = 32,
	DEPTH = 64,
	STROKE = 128,
	OSCILLATE = 256,
	POSITION = 512,
}


## Toy intended use type, to allow making different choregraphies for different toys.
enum Types {
	MALE_MASTURBATOR = 1,
	COCKRING = 2,
	PROSTATE_MASSOR = 4,
	ANAL_PLUG = 8,
	CLITORIS_VIBE = 16,
	DILDO = 32,
	NIPPLE_CLAMP = 64,
}


## Maximum value for Vibrate Function.
const MAX_VIBRATE: int = 20
## Maximum value for Rotate Function.
const MAX_ROTATE: int = 20
## Maximum value for Pump Function.
const MAX_PUMP: int = 3
## Maximum value for Thrusting Function.
const MAX_THRUSTING: int = 20
## Maximum value for Fingering Function.
const MAX_FINGERING: int = 20
## Maximum value for Suction Function.
const MAX_SUCTION: int = 20
## Maximum value for Depth Function.
const MAX_DEPTH: int = 3
## Maximum value for Stroke Function.[br]
## @warning Stroke should be used in conjunction with Thrusting, and there should be a minimum difference of 20 between the minimum and maximum values. Otherwise, it will be ignored.
const MAX_STROKE: int = 100
## Maximum value for Oscillate Function.
const MAX_OSCILLATE: int = 20


## Associative Function strings for each of the enum values.
const FUNCTIONS_STRINGS: Dictionary[int, String] = {
	Functions.VIBRATE: "Vibrate",
	Functions.ROTATE: "Rotate",
	Functions.PUMP: "Pump",
	Functions.THRUSTING: "Thrusting",
	Functions.FINGERING: "Fingering",
	Functions.SUCTION: "Suction",
	Functions.DEPTH: "Depth",
	Functions.STROKE: "Stroke",
	Functions.OSCILLATE: "Oscillate",
	Functions.POSITION: "Position",
}


## Associative type strings for each of the enum values.
const TYPES_STRINGS: Dictionary[String, int] = {
	"gravity": Types.DILDO | Types.CLITORIS_VIBE,
	"gemini": Types.NIPPLE_CLAMP,
	"flexer": Types.DILDO | Types.CLITORIS_VIBE,
	"exomoon": Types.CLITORIS_VIBE,
	"xmachine": Types.DILDO,
	"mini xmachine": Types.DILDO,
	"calor": Types.MALE_MASTURBATOR,
	"hush": Types.ANAL_PLUG,
	"gush": Types.MALE_MASTURBATOR | Types.COCKRING,
	"hyphy": Types.DILDO | Types.CLITORIS_VIBE,
	"dolce": Types.DILDO | Types.CLITORIS_VIBE,
	"lush": Types.DILDO | Types.CLITORIS_VIBE,
	"diamo": Types.COCKRING,
	"edge": Types.PROSTATE_MASSOR | Types.ANAL_PLUG,
	"ferri": Types.CLITORIS_VIBE,
	"domi": Types.PROSTATE_MASSOR | Types.CLITORIS_VIBE,
	"osci": Types.DILDO | Types.CLITORIS_VIBE,
	"max": Types.MALE_MASTURBATOR,
	"nora": Types.DILDO | Types.CLITORIS_VIBE,
	"ambi": Types.CLITORIS_VIBE,
	"ridge": Types.PROSTATE_MASSOR | Types.ANAL_PLUG,
	"tenera": Types.CLITORIS_VIBE,
	"solace": Types.MALE_MASTURBATOR,
	"vulse": Types.DILDO | Types.CLITORIS_VIBE,
	"lapis": Types.DILDO | Types.CLITORIS_VIBE,
	"solace pro": Types.MALE_MASTURBATOR,
	"mission": Types.DILDO,
}


## List of Functions available for each toy generally speaking. Functions will be set on a case-by-case basis depending on what the API returns.
const TOYS_FUNCTIONS: Dictionary[String, int] = {
	"gravity": Functions.VIBRATE | Functions.THRUSTING,
	"gemini": Functions.VIBRATE,
	"flexer": Functions.VIBRATE | Functions.FINGERING,
	"exomoon": Functions.VIBRATE,
	"xmachine": Functions.THRUSTING,
	"mini xmachine": Functions.THRUSTING,
	"calor": Functions.VIBRATE,
	"hush": Functions.VIBRATE,
	"gush": Functions.VIBRATE | Functions.OSCILLATE,
	"hyphy": Functions.VIBRATE,
	"dolce": Functions.VIBRATE,
	"lush": Functions.VIBRATE,
	"diamo": Functions.VIBRATE,
	"edge": Functions.VIBRATE,
	"ferri": Functions.VIBRATE,
	"domi": Functions.VIBRATE,
	"osci": Functions.ROTATE | Functions.VIBRATE | Functions.OSCILLATE,
	"max": Functions.VIBRATE | Functions.PUMP,
	"nora": Functions.VIBRATE | Functions.ROTATE,
	"ambi": Functions.VIBRATE,
	"ridge": Functions.VIBRATE | Functions.ROTATE,
	"tenera": Functions.SUCTION,
	"solace": Functions.THRUSTING | Functions.DEPTH,
	"vulse": Functions.VIBRATE | Functions.THRUSTING,
	"lapis": Functions.VIBRATE,
	"solace pro": Functions.THRUSTING | Functions.STROKE | Functions.POSITION,
	"mission": Functions.VIBRATE,
}


## Format string for a Function action.
const FUNCTION_ACTION_FORMAT: String = "{function}:{value}"


## Toy identifier.
@export var id: String
## Toy name.
@export var name: String
## Toy battery.
@export var battery: int
## Toy nickname.
@export var nick_name: String
## Toy Functions.
@export_flags("Vibrate:1", "Rotate:2", "Pump:4", "Thrusting:8", "Fingering:16", "Suction:32", "Depth:64", "Stroke:128", "Oscillate:256", "Position:512", "All:1023") var functions: int = 0
## Toy response types. By default all types.
@export_flags("Male Masturbator:1", "Cockring:2", "Prostate Massor:4", "Anal Plug:8", "Clitoris Vibe:16", "Dildo:32", "Nipple Clamp:64") var type: int = 127


## Previously sent command.
var previous_command: GDLovenseCommand


## Vibrate strength.
var vibrate: float = 0.0
## Rotate strength.
var rotate: float = 0.0
## Pump strength.
var pump: float = 0.0
## Thrusting strength.
var thrusting: float = 0.0
## Fingering strength.
var fingering: float = 0.0
## Suction strength.
var suction: float = 0.0
## Depth strength.
var depth: float = 0.0
## Stroke strength.
var stroke: float = 0.0
## Oscillate strength.
var oscillate: float = 0.0


## Creates a new instance from a Dictionary returned by the API, and JSON-decoded.
static func new_from_api_dict(dict: Dictionary) -> GDLovenseToy:
	var toy: GDLovenseToy = new()

	if "id" in dict:
		toy.id = dict.id
	if "name" in dict:
		toy.name = dict.name
	if "battery" in dict:
		toy.battery = dict.battery
	if "nickName" in dict:
		toy.nick_name = dict.nickName
	if "fullFunctionNames" in dict:
		toy._set_functions(dict.fullFunctionNames)

	if toy.id.is_empty() or toy.name.is_empty() or toy.functions == 0:
		push_error("Received toy data from API is incomplete.")
		return null

	if toy.name not in TYPES_STRINGS:
		push_warning("Toy `{name}` has no default type pre-configured. Please add it, and contribute back to the repository.")
	else:
		toy.type = TYPES_STRINGS[toy.name]

	return toy


## Set properties from a Dictionary.
func set_properties(values: Dictionary[StringName, Variant]) -> void:
	for property: StringName in values:
		if property in self:
			set(property, values[property])


## Sets all functions to a new value.
func all(value: float) -> void:
	vibrate = value
	rotate = value
	pump = value
	thrusting = value
	fingering = value
	suction = value
	depth = value
	stroke = value
	oscillate = value


## Stops all functions.
func stop() -> void:
	all(0.0)


## Indicates whether the toy settings have changed, to prevent from resynching every single poll.
func has_changed() -> bool:
	return not is_instance_valid(previous_command) or previous_command.action != _get_action_string()


## Returns a command to send to the API to reflect the current toy's status.[br]
## This command is designed to be regularly sent after updating any of the toy settings, but needs to be manually called to make sure we don't overload the player's system.
func get_function_command() -> GDLovenseCommand:
	var command: GDLovenseCommand = GDLovenseCommand.new()
	command.command = GDLovenseCommand.FUNCTION
	command.action = _get_action_string()
	command.time_sec = 0.0
	command.loop_running_sec = 1.0
	command.toy = id
	command.stop_previous = 0
	return command


## Sets the toy Functions capabilities with the fullFunctionNames returned by GetToys command.
func _set_functions(full_function_names: Array) -> void:
	functions = 0
	for function: String in full_function_names:
		var found: bool = false
		for value: int in Functions.values():
			if function == FUNCTIONS_STRINGS[value]:
				functions += value
				found = true
		if not found:
			push_error("Unknown toy Function: {function}.".format({"function": function}))


## Returns the Function value the API expects to receive.
func _get_function_value(function: int) -> int:
	match function:
		Functions.VIBRATE:
			return roundi(float(MAX_VIBRATE) * vibrate)
		Functions.ROTATE:
			return roundi(float(MAX_ROTATE) * rotate)
		Functions.PUMP:
			return roundi(float(MAX_PUMP) * pump)
		Functions.THRUSTING:
			return roundi(float(MAX_THRUSTING) * thrusting)
		Functions.FINGERING:
			return roundi(float(MAX_FINGERING) * fingering)
		Functions.SUCTION:
			return roundi(float(MAX_SUCTION) * suction)
		Functions.DEPTH:
			return roundi(float(MAX_DEPTH) * depth)
		Functions.STROKE:
			return roundi(float(MAX_STROKE) * stroke)
		Functions.OSCILLATE:
			return roundi(float(MAX_OSCILLATE) * oscillate)
		_:
			push_error("Unknown toy Function: {function}.".format({"function": function}))
			return 0


## Returns the action string expected for a Function API command depending on the toy capabilities.
func _get_action_string() -> String:
	var actions: Array[String] = []

	for value: int in Functions.values():
		if functions & value > 0:
			actions.append(FUNCTION_ACTION_FORMAT.format({"function": FUNCTIONS_STRINGS[value], "value": str(_get_function_value(value))}))

	return ",".join(actions)
