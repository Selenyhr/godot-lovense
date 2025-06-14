class_name TaskRunner
extends RefCounted


## Allows to execute async tasks in batch and get their return values one after the other.


## A single task has finished.
signal task_completed(task: Callable)
## All tasks have finished executing.
signal tasks_finished()


## List of remaining tasks to execute.
var remaining_tasks: Array[Callable] = []
## Tasks results sorted in a Dictionary.
var results: Dictionary[Callable, Variant] = {}

## Lock to prevent from re-running if tasks are still ongoing.
var running: bool = false


func _init() -> void:
	task_completed.connect(_on_task_completed)


## Runs all tasks given as an argument
func run(tasks: Array[Callable]) -> Dictionary[Callable, Variant]:
	if running:
		push_error("Re-running tasks while previous tasks are ongoing is not supported.")
		return {}

	if tasks.is_empty():
		return {}

	results = {}
	remaining_tasks = tasks
	running = true
	_autorun_next()
	await tasks_finished
	running = false
	return results


## Removes a task from the list once it is done, and starts the next one.
func _on_task_completed(task: Callable) -> void:
	remaining_tasks.erase(task)
	_autorun_next()


## Autoruns the next task if there are some left, otherwise emits `tasks_finished`.
func _autorun_next() -> void:
	if remaining_tasks.is_empty():
		tasks_finished.emit()
	else:
		_run_task(remaining_tasks[0])


## Runs a single task, stores its result in the aggregated Dictionary and emits the corresponding signal.
func _run_task(task: Callable) -> void:
	results[task] = await task.call()
	task_completed.emit(task)
