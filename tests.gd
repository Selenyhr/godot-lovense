extends Node


const TEST_OK_STRING: String = "[color=green]Test OK: {0}.[/color]"
const TEST_KO_STRING: String = "[b][color=red]Test KO: {0}.[/color][/b]"


## Fail tests take longer since they rely on timeout.
@export var do_fail_tests: bool = true


@onready var gd_lovense: GDLovense = $GDLovense
@onready var gd_lovense_toy_function: GDLovenseToyFunction = $GDLovenseToyFunction


var gd_lovense_properties: Dictionary[String, Variant] = {}

var network_result: bool = false


func _ready() -> void:
	gd_lovense_properties = _get_default_properties(gd_lovense)
	await run_tests()


func run_tests() -> void:
	var result: bool = true

	var tests: Array[Dictionary] = [
		{"description": "API URL constructor", "callable": _test_api_url},
		{"description": "Headers generation", "callable": _test_headers},
		{"description": "GetToys/GetToyName commands", "callable": _test_get_toys},
		{"description": "Max 2 Function commands", "callable": _test_max_2_function},
		{"description": "GDLovenseToy simplification layer", "callable": _test_toy_layer},
	]

	for test: Dictionary in tests:
		result = await _run_test(test["description"], test["callable"]) and result

	print_rich("[color=green]All tests OK.[/color]" if result else "[b][color=red]Some tests KO.[/color][/b]")


#region General functions
## Returns the default properties for a node. Used in conjuction with the restore to default after each test, to prevent state changes.
func _get_default_properties(node: Node) -> Dictionary[String, Variant]:
	var values: Dictionary[String, Variant] = {}

	for property: Dictionary in node.get_property_list():
		if (property["usage"] & PROPERTY_USAGE_STORAGE > 0 or property["usage"] & PROPERTY_USAGE_EDITOR > 0 or property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE > 0) and property["name"] not in ["download_file", "download_chunk_size", "use_threads", "body_size_limit"]:
			values[property["name"]] = node.get(property["name"])

	return values


## Restore all objects to their default states.
func _restore_default() -> void:
	network_result = false
	for property: String in gd_lovense_properties:
		gd_lovense.set(property, gd_lovense_properties[property])


## Runs a test, prints the result, and restores all elements to default.
func _run_test(descriptor: String, test_callable: Callable) -> bool:
	var result: bool = await test_callable.call()
	print_rich((TEST_OK_STRING if result else TEST_KO_STRING).format([descriptor]))

	_restore_default()

	return result


## Runs a series of network tasks, and returns the overall aggregated result.
func _run_network_tasks(tasks_normal: Array[Callable], tasks_fail: Array[Callable]) -> bool:
	var result: bool = true

	var tasks: Array[Callable] = tasks_normal.duplicate()
	if do_fail_tests:
		tasks.append_array(tasks_fail)
	var task_runner: TaskRunner = TaskRunner.new()
	var results: Dictionary[Callable, Variant] = await task_runner.run(tasks)

	for task: Callable in tasks:
		if task not in results:
			push_error("Task {task} has not been run.".format({"task": task.get_method()}))
			result = false
		else:
			result = result and results[task]

	return result
#endregion


## Runs the API URL constructor tests.
func _test_api_url() -> bool:
	var result: bool = true

	# Default settings: API URL is the HTTP local app
	gd_lovense.use_https = false
	gd_lovense.remote_domain = ""
	gd_lovense.remote_port = 0
	if gd_lovense._get_api_url() != "http://127-0-0-1.lovense.club:20010/command":
		result = false
		push_error("Default API URL is not the HTTP local app")

	# Use HTTPS settings with all default
	gd_lovense.use_https = true
	if gd_lovense._get_api_url() != "https://127-0-0-1.lovense.club:30010/command":
		result = false
		push_error("Use HTTPS setting is not correct")

	# Change port to a custom value
	gd_lovense.remote_port = 43812
	if gd_lovense._get_api_url() != "https://127-0-0-1.lovense.club:43812/command":
		result = false
		push_error("Port change does not work")

	# Change domain to a custom value
	gd_lovense.remote_domain = "192.168.1.100"
	if gd_lovense._get_api_url() != "https://192.168.1.100:43812/command":
		result = false
		push_error("Domain change does not work")

	# Change domain and port on HTTP
	gd_lovense.use_https = false
	if gd_lovense._get_api_url() != "http://192.168.1.100:43812/command":
		result = false
		push_error("HTTP domain and port change do not work")

	return result


## Runs the header tests.
func _test_headers() -> bool:
	var result: bool = true

	var headers: Dictionary[String, String] = gd_lovense._get_headers()

	# Check for X-platform header
	if "X-platform" not in headers:
		result = false
		push_error("X-platform header is not set")

	# Check for Content-Type header
	if "Content-Type" not in headers or headers["Content-Type"] != "application/json":
		result = false
		push_error("Content-Type is not set to application/json")

	return result


#region GetToys/GetToyName commands
## Run GetToys command.
func _test_get_toys() -> bool:
	var tasks_normal: Array[Callable] = [
		_test_get_toys_normal,
		_test_get_toy_name_normal,
		_test_sync_toys,
	]
	var tasks_fail: Array[Callable] = [
		_test_get_toys_nonexistent,
	]

	return await _run_network_tasks(tasks_normal, tasks_fail)


## Send a basic GetToys command to check connection.
func _test_get_toys_normal() -> bool:
	var command: GDLovenseCommand = GDLovenseCommand.new()
	command.command = GDLovenseCommand.GET_TOYS
	gd_lovense.send_command(command, _test_get_toys_normal_success)
	var result: bool = await gd_lovense.network_completed
	_restore_default()
	return result


## Try connecting to a non-existing server, to check for crashes.
func _test_get_toys_nonexistent() -> bool:
	gd_lovense.remote_domain = "unknown1234.local"
	var command: GDLovenseCommand = GDLovenseCommand.new()
	command.command = GDLovenseCommand.GET_TOYS
	gd_lovense.send_command(command, _test_get_toys_nonexistent_success, _test_get_toys_nonexistent_fail)
	var result: bool = await gd_lovense.network_completed
	_restore_default()
	return result


func _test_sync_toys() -> bool:
	gd_lovense.sync_toys_list()
	var result: bool = await gd_lovense.toys_synced
	_restore_default()
	return result


## Send a basic GetToyName command.
func _test_get_toy_name_normal() -> bool:
	var command: GDLovenseCommand = GDLovenseCommand.new()
	command.command = GDLovenseCommand.GET_TOY_NAME
	gd_lovense.send_command(command, _test_get_toy_name_normal_success)
	var result: bool = await gd_lovense.network_completed
	_restore_default()
	return result


## Callback function for an API success.
func _test_get_toys_normal_success(data: Dictionary) -> void:
	var data_toys: String = data["data"]["toys"]
	var toys: Dictionary = JSON.parse_string(data_toys)
	for toy: String in toys:
		print("Found toy {0}.".format([toys[toy]["id"]]))
	gd_lovense._finish_request(true)


## Callback function for server not found test if fail (normal).
func _test_get_toys_nonexistent_fail(response_code: int) -> void:
	if response_code not in [gd_lovense.RESULT_CANT_CONNECT, gd_lovense.RESULT_CANT_RESOLVE]:
		push_error("API replied with {code}: {message}".format({"code": response_code, "message": gd_lovense._get_error_string(response_code)}))
		gd_lovense._finish_request(false)
		return
	gd_lovense._finish_request(true)


## Callback function for server not found test if success (very abnormal).
func _test_get_toys_nonexistent_success(_data: Dictionary) -> void:
	push_error("API returned JSON with nonexistent server???")
	gd_lovense._finish_request(false)


## Callback function for an API success.
func _test_get_toy_name_normal_success(data: Dictionary) -> void:
	var toys: Array = data["data"]
	for toy: String in toys:
		print("Found toy {0}.".format([toy]))
	gd_lovense._finish_request(true)
#endregion


#region Max 2 Function commands
## Runs some tests to check Function on a Max 2
func _test_max_2_function() -> bool:
	var tasks_normal: Array[Callable] = [
		_test_max_2_function_continuous,
		_test_max_2_function_rapid,
	]
	var tasks_fail: Array[Callable] = [
	]

	return await _run_network_tasks(tasks_normal, tasks_fail)


## Run basic continuous functions
func _test_max_2_function_continuous() -> bool:
	var command: GDLovenseCommand = GDLovenseCommand.new()
	command.command = GDLovenseCommand.FUNCTION
	command.action = "Vibrate:2"
	command.time_sec = 5.0
	gd_lovense.send_command(command)
	var result: bool = await gd_lovense.network_completed
	await get_tree().create_timer(5.0).timeout
	_restore_default()
	return result


## Run rapid commands to check response time
func _test_max_2_function_rapid() -> bool:
	var result: bool = true
	var command: GDLovenseCommand = GDLovenseCommand.new()
	command.command = GDLovenseCommand.FUNCTION
	command.time_sec = 1.0
	for i: int in range(20):
		@warning_ignore("integer_division")
		command.action = "Vibrate:{0},Pump:{1}".format([str(i), str(clampi(i / 6, 0, 3))])
		command.stop_previous = 0
		gd_lovense.send_command(command)
		result = await gd_lovense.network_completed and result
		await get_tree().create_timer(0.1).timeout
	_restore_default()
	return result
#endregion


#region GDLovenseToy tests
## Run some tests for the GDLovenseToy simplification layer.
func _test_toy_layer() -> bool:
	if gd_lovense.connected_toys.is_empty():
		push_error("No toy connected. You need to connect toys before running this test.")
		return false

	var tasks_normal: Array[Callable] = [
		_test_all_toys,
		_test_toy_type.bind(GDLovenseToy.Types.MALE_MASTURBATOR),
		_test_toy_type.bind(GDLovenseToy.Types.COCKRING),
		_test_toy_type_tween.bind(GDLovenseToy.Types.MALE_MASTURBATOR),
	]
	var tasks_fail: Array[Callable] = [
	]

	return await _run_network_tasks(tasks_normal, tasks_fail)


## Runs all functions on all connected toys.
func _test_all_toys() -> bool:
	var result: bool = true
	for i: int in range(0, 10):
		for toy: GDLovenseToy in gd_lovense.connected_toys:
			toy.all(float(i) * 0.10)
			gd_lovense.send_command(toy.get_function_command())
			result = await gd_lovense.network_completed and result
		await get_tree().create_timer(0.2).timeout
	# Reset since GDLovenseToy loops commands to prevent from hyperpolling.
	for toy: GDLovenseToy in gd_lovense.connected_toys:
		toy.all(0.0)
		gd_lovense.send_command(toy.get_function_command())
		result = await gd_lovense.network_completed and result
	_restore_default()
	return result


## Runs tests on GDLovenseToyFunction for a certain toy type.[br]
## This test mostly relies on checking if the toy activates, since we don't want to bother with the whole network thing.
func _test_toy_type(type: int) -> bool:
	print("Start test for type: {0}".format([type]))
	gd_lovense_toy_function.toy_type = type
	gd_lovense_toy_function.vibrate = 0.3
	await get_tree().create_timer(0.5).timeout
	gd_lovense_toy_function.vibrate = 0.6
	await get_tree().create_timer(0.5).timeout
	gd_lovense_toy_function.vibrate = 0.0
	await get_tree().create_timer(1.0).timeout
	return true


## Runs tests on GDLovenseToyFunction for a certain toy type.[br]
## This test mostly relies on checking if the toy activates, since we don't want to bother with the whole network thing.
func _test_toy_type_tween(type: int) -> bool:
	print("Start Tween test for type: {0}".format([type]))
	gd_lovense_toy_function.toy_type = type
	gd_lovense_toy_function.vibrate = 0.0
	var tween: Tween = create_tween().set_trans(Tween.TRANS_CIRC)
	tween.tween_property(gd_lovense_toy_function, "vibrate", 1.0, 1.5)
	await get_tree().create_timer(2.0).timeout
	gd_lovense_toy_function.vibrate = 0.0
	await get_tree().create_timer(1.0).timeout
	return true
#endregion
