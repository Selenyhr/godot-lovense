@icon("GDLovense.webp")
class_name GDLovense
extends HTTPRequest

## Interfaces Godot with the Lovense remote app to control toys.

## Emitted when a network request has completed, to prevent sending several ones at once.
signal network_completed(success: bool)
## Emitted when toys are done synching, indicating whether it was a success or a failure.
signal toys_synced(success: bool)


## HTTP API URL.
const HTTP_API_URL: String = "http://{domain}:{port}/command"
## HTTPS API URL.
const HTTPS_API_URL: String = "https://{domain}:{port}/command"

## Domain for a locally running remote app.
const DOMAIN_LOCAL_REMOTE_APP: String = "127-0-0-1.lovense.club"
## HTTP port for a locally running remote app.
const PORT_LOCAL_REMOTE_APP_HTTP: int = 20010
## HTTPS port for a locally running remote app.
const PORT_LOCAL_REMOTE_APP_HTTPS: int = 30010

## X-platform header required by app.
const PLATFORM_HEADER: String = "X-platform"


## Invalid JSON from API.
const ERROR_INVALID_JSON: int = 50


## If enabled, will use TLS for all connections. May experience some slowdowns.
@export var use_https: bool = false

## Domain to contact a Lovense Remote app at. If empty, will use the local remote app domain.
@export var remote_domain: String

## Port to contact a Lovense Remote app at. If zero, will use the local remote app port.
@export var remote_port: int


## Last error message when doing a request.
var last_error: int = OK

## Indicates whether the Node is currently busy waiting for a request.
var is_busy_request: bool = false

## List of toys currently connected.
var connected_toys: Array[GDLovenseToy] = []

## List of queued commands, in case the code sends them too fast.
var queued_commands: Array[Callable] = []



## Converts an error code to a readable string.
func _get_error_string(code: int) -> String:
	match code:
		1: return tr(&"Request failed due to a mismatch between the expected and actual chunked body size during transfer. Possible causes include network errors, server misconfiguration, or issues with chunked encoding.", &"gd_lovense.error_code")
		2: return tr(&"Request failed while connecting.", &"gd_lovense.error_code")
		3: return tr(&"Request failed while resolving.", &"gd_lovense.error_code")
		4: return tr(&"Request failed due to connection (read/write) error.", &"gd_lovense.error_code")
		5: return tr(&"Request failed on TLS handshake.", &"gd_lovense.error_code")
		6: return tr(&"Request does not have a response (yet).", &"gd_lovense.error_code")
		7: return tr(&"Request exceeded its maximum size limit, see body_size_limit.", &"gd_lovense.error_code")
		8: return tr(&"Request failed due to an error while decompressing the response body. Possible causes include unsupported or incorrect compression format, corrupted data, or incomplete transfer.", &"gd_lovense.error_code")
		9: return tr(&"Request failed (currently unused).", &"gd_lovense.error_code")
		10: return tr(&"HTTPRequest couldn't open the download file.", &"gd_lovense.error_code")
		11: return tr(&"HTTPRequest couldn't write to the download file.", &"gd_lovense.error_code")
		12: return tr(&"Request reached its maximum redirect limit, see max_redirects.", &"gd_lovense.error_code")
		13: return tr(&"Request failed due to a timeout. If you expect requests to take a long time, try increasing the value of timeout or setting it to 0.0 to remove the timeout completely.", &"gd_lovense.error_code")
		ERROR_INVALID_JSON: return tr(&"API does not return valid JSON.", &"gd_lovense.error_code")
		500: return tr(&"HTTP server not started or disabled.", &"gd_lovense.error_code")
		400: return tr(&"Invalid Command.", &"gd_lovense.error_code")
		401: return tr(&"Toy Not Found.", &"gd_lovense.error_code")
		402: return tr(&"Toy Not Connected.", &"gd_lovense.error_code")
		403: return tr(&"Toy Doesn't Support This Command.", &"gd_lovense.error_code")
		404: return tr(&"Invalid Parameter.", &"gd_lovense.error_code")
		506: return tr(&"Server Error. Restart Lovense Connect.", &"gd_lovense.error_code")
		_: return tr(&"Unknown Error.", &"gd_lovense.error_code")


## Returns the correct API URL depending on the settings.
func _get_api_url() -> String:
	return (HTTPS_API_URL if use_https else HTTP_API_URL).format(
		{
			"domain": DOMAIN_LOCAL_REMOTE_APP if remote_domain.is_empty() else remote_domain,
			"port": (PORT_LOCAL_REMOTE_APP_HTTPS if use_https else PORT_LOCAL_REMOTE_APP_HTTP) if remote_port == 0 else remote_port,
		})


## Returns the required HTTP headers for the API to accept a request.
func _get_headers() -> Dictionary[String, String]:
	return {
		PLATFORM_HEADER: ProjectSettings.get_setting("application/config/name"),
		"Content-Type": "application/json",
	}


## Callable function that takes the results of the API call, and calls another callable depending on the result.
func _request_callable(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, success_callable: Callable, fail_callable: Callable) -> void:
	# Check for network error
	if result != RESULT_SUCCESS or response_code != HTTPClient.ResponseCode.RESPONSE_OK:
		fail_callable.call(result if response_code == 0 else response_code)
		return

	var response: Variant = JSON.parse_string(body.get_string_from_utf8())

	# Check for correct JSON decoded to a Dictionary.
	if typeof(response) != TYPE_DICTIONARY or response == null:
		fail_callable.call(ERROR_INVALID_JSON)
		return

	# Check for correct response code.
	if "code" not in response or response["code"] != HTTPClient.ResponseCode.RESPONSE_OK:
		fail_callable.call(int(response["code"]))
		return

	success_callable.call(response)


## Sends a command to the API.
func send_command(command: GDLovenseCommand, success_callable: Callable = _on_network_generic_success, fail_callable: Callable = _on_network_generic_fail) -> void:
	if is_busy_request:
		queued_commands.append(send_command.bind(command, success_callable, fail_callable))
		return

	var built_headers: PackedStringArray = PackedStringArray()

	last_error = OK

	is_busy_request = true

	var headers: Dictionary[String, String] = _get_headers()
	for header: String in headers:
		built_headers.append("{header}: {value}".format({"header": header, "value": headers[header]}))

	request_completed.connect(_request_callable.bind(success_callable, fail_callable), CONNECT_ONE_SHOT)

	request(_get_api_url(), built_headers, HTTPClient.METHOD_POST, str(command))


## Callback function for a network/API fail.
func _on_network_generic_fail(response_code: int) -> void:
	last_error = response_code
	push_error("API replied with {code}: {message}".format({"code": response_code, "message": _get_error_string(response_code)}))
	_finish_request(false)


## Callback function for an API success.
func _on_network_generic_success(_data: Dictionary) -> void:
	last_error = OK
	_finish_request(true)


## Finishes the request transaction, or continues with the ones that have been queued while waiting for the request to finish.
func _finish_request(success: bool) -> void:
	is_busy_request = false
	if queued_commands.is_empty():
		network_completed.emit(success)
	else:
		queued_commands[0].call()


## Synchronises the connected toys list.
func sync_toys_list() -> void:
	var command: GDLovenseCommand = GDLovenseCommand.new()
	command.command = GDLovenseCommand.GET_TOYS
	send_command(command, _sync_toys_list_success, _sync_toys_list_fail)


## Populates the toys list upon successful sync request.
func _sync_toys_list_success(data: Dictionary) -> void:
	if "data" not in data or "toys" not in data.data:
		push_error("Invalid API data.")
		toys_synced.emit(false)
		return

	var toys_data: Dictionary = JSON.parse_string(data.data.toys)

	for toy_id: String in toys_data:
		if typeof(toys_data[toy_id]) != TYPE_DICTIONARY:
			push_error("Invalid API data for toy `{}`.".format([toy_id]))
			continue
		connected_toys.append(GDLovenseToy.new_from_api_dict(toys_data[toy_id]))

	last_error = OK
	_finish_request(true)
	toys_synced.emit(true)


## Stores the error returned by a failed sync request.
func _sync_toys_list_fail(error_code: int) -> void:
	last_error = error_code
	_finish_request(false)
	toys_synced.emit(false)


## Set toys values for all toys that match a certain type.
func set_toys_values_by_type(type: int, values: Dictionary[StringName, Variant]) -> void:
	for toy: GDLovenseToy in connected_toys:
		if toy.type & type > 0:
			toy.set_properties(values)
			if toy.has_changed():
				var command: GDLovenseCommand = toy.get_function_command()
				send_command(command)
				if await network_completed:
					toy.previous_command = command
