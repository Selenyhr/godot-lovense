@icon("GDLovense.webp")
class_name GDLovenseCommand
extends RefCounted

## Describes a Lovense API command to send.[br]
## Online documentation: [url]https://developer.lovense.com/docs/standard-solutions/standard-api.html#by-local-application[/url][br]
## Properties marked with [kbd]TAGS[/kbd] can only be used with specific commands.


## GetToys command.
const GET_TOYS: String = "GetToys"
## GetToyName command.
const GET_TOY_NAME: String = "GetToyName"
## Function command.
const FUNCTION: String = "Function"
## Position command.
const POSITION: String = "Position"
## Pattern command.
const PATTERN: String = "Pattern"
## PatternV2 command.
const PATTERN_V2: String = "PatternV2"
## Preset command.
const PRESET: String = "Preset"


## [kbd]PATTERN_V2[/kbd] Setup type.
const TYPE_SETUP: String = "Setup"
## [kbd]PATTERN_V2[/kbd] Play type.
const TYPE_PLAY: String = "Play"
## [kbd]PATTERN_V2[/kbd] Stop type.
const TYPE_STOP: String = "Stop"
## [kbd]PATTERN_V2[/kbd] SyncTime Type.
const TYPE_SYNC_TIME: String = "SyncTime"


## Type of request.
var command: String
## [kbd]FUNCTION[/kbd]: Control the function and strength of the toy.
var action: String
## [kbd]FUNCTION[/kbd]: Total running time.
var time_sec: float = 0.0
## [kbd]FUNCTION[/kbd]: Running time.
var loop_running_sec: float = 0.0
## [kbd]FUNCTION[/kbd]: Suspend time.
var loop_pause_sec: float = 0.0
## [kbd]FUNCTION[/kbd] [kbd]POSITION[/kbd]: Toy ID.
var toy: String
## [kbd]FUNCTION[/kbd]: Stop all previous commands and execute current commands.
var stop_previous: int = 1
## [kbd]POSITION[/kbd]: The position of the stroker.
var value: String
## [kbd]PATTERN[/kbd]: [code]"V:1;F:v,r,p,t,f,s,d,o;S:1000#"[/code][br]
## [code]V:1;[/code] Protocol version, this is static;[br]
## [code]F:v,r,p,t,f,s,d,o;[/code] Features: v is vibrate, r is rotate, p is pump, t is thrusting, f is fingering, s is suction, d is depth, o is oscillate, this should match the strength below.[br]
## [code]F:;[/code] Leave blank to make all functions respond;[br]
## [code]S:1000;[/code] Intervals in Milliseconds, should be greater than 100.
var rule: String
## [kbd]PATTERN[/kbd]: The pattern. For example: 20;20;5;20;10.
var strength: String
## [kbd]PATTERN_V2[/kbd]: Type of operation.
var type: String
## [kbd]PATTERN_V2[/kbd]: List of actions. Each action consists of a timestamp (in ms) and a corresponding position value (0~100).[br]
## [code][{"ts":0,"pos":10},{"ts":100,"pos":100},{"ts":200,"pos":10},{"ts":400,"pos":15},{"ts":800,"pos":88}][/code]
var actions: Array[Dictionary]
## [kbd]PATTERN_V2[/kbd] [kbd]TYPE_PLAY[/kbd]: The start time of playback.
var start_time: int = 0
## [kbd]PATTERN_V2[/kbd] [kbd]TYPE_PLAY[/kbd]: The client-server offset time.
var offset_time: int = 0
## [kbd]PATTERN_V2[/kbd] [kbd]TYPE_PLAY[/kbd]: Total running time.
var time_ms: float = 0.0
## [kbd]PRESET[/kbd]: Preset pattern name.[br]
## We provide four preset patterns in the Lovense Remote app: pulse, wave, fireworks, earthquake.
var name: String


## Converts the command as a dictionary with keys accepted by the API.
func _to_dict() -> Dictionary[String, Variant]:
	var dictionary: Dictionary[String, Variant] = {
		"command": command,
		"apiVer": 1,
	}

	if command in [FUNCTION]:
		dictionary["action"] = action
	if command in [FUNCTION, PATTERN, PRESET]:
		dictionary["timeSec"] = time_sec

	if command in [FUNCTION] and loop_running_sec > 1.0:
		dictionary["loopRunningSec"] = loop_running_sec
	if command in [FUNCTION] and loop_pause_sec > 1.0:
		dictionary["loopPauseSec"] = loop_pause_sec
	if command in [FUNCTION, POSITION, PATTERN, PATTERN_V2, PRESET] and not toy.is_empty():
		dictionary["toy"] = toy
	if command in [FUNCTION]:
		dictionary["stopPrevious"] = stop_previous
	if command in [POSITION]:
		dictionary["value"] = value
	if command in [PATTERN]:
		dictionary["rule"] = rule
	if command in [PATTERN]:
		dictionary["strength"] = strength
	if command in [PATTERN_V2]:
		dictionary["type"] = type
	if command in [PATTERN_V2] and type == TYPE_SETUP:
		dictionary["actions"] = actions
	if command in [PATTERN_V2] and type == TYPE_PLAY:
		dictionary["startTime"] = start_time
	if command in [PATTERN_V2] and type == TYPE_PLAY and time_ms > 100.0:
		dictionary["timeMs"] = time_ms
	if command in [PRESET]:
		dictionary["name"] = name

	return dictionary


## Converts the command as a string that can be accepted by the API.
func _to_string() -> String:
	return JSON.stringify(_to_dict())
