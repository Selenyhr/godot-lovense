# Lovense toys integration for Godot.
<p align="center">
	<a href="https://www.lovense.com/">
		<img src="GDLovense.webp" alt="Lovense logo" />
	</a>
</p>

Use a connected Lovense toy through the official remote app in Godot 4.4+.

<sub>The Lovense names and logos belong to HYTTO PTE. LTD. and are used for illustrative purposes only. This repository uses their official API through the Lovense Remote app, and does not intend on breaching any intellectual property.</sub>


# How to use this integration.

This integration requires the use of the Lovense Remote app along with its "Game Mode" under the "Discover" tab. A local network connection will be made to the API served by this feature.

It is recommended to clone this repository as a [submodule](https://github.blog/open-source/git/working-with-submodules/).

This repository is not a Godot addon, as such it can be inserted anywhere within your `res://` project folder.

> [!WARNING]
> If using a Godot export mode that has permissions control, you need to enable internet permissions for the network connection to process.

> [!IMPORTANT]
> For now, this integration only supports the use of [`Function` API calls](https://developer.lovense.com/docs/standard-solutions/standard-api.html#function-request) for sending commands to the toys.
> A simplification layer is provided to make sure it can easily be used without having to manage the network layer.

# Registered classes.

This project registers the following classes at the project level. As such, make sure you don't have a pre-existing conflict:
```gdscript
class_name GDLovense
class_name GDLovenseCommand
class_name GDLovenseToy
class_name GDLovenseToyFunction
class_name TaskRunner
```

The `TaskRunner` class is not needed for the integration to function, it is a helper class for writing test series that use coroutines.

# Recommended setup.

## `GDLovense` autoload.

It is recommended to define an [autoload](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html) with a single [`GDLovense` node](gd_lovense.gd).

This node contains three export variables that can be set:
* `use_https` (`bool`, default `false`) make use of a TLS connection to connect with the API. Can slow down link speed and response time.
* `remote_domain` (`String`) domain to try and contact the Lovense Remote app at. If empty, it will attempt to communicate with a locally-running Remote app.
* `remote_port` (`int`) port to try and contact the Lovense Remote app at. Note that this setting has precedence over `use_https`.

It is recommended to give the player a way of choosing for themselves the value for these variables.

### Synching connected toys.

For the integration to know about the toys that are currently connected, calling `GDLovense.sync_toys_list()` is required.

This function gathers all toys data, and stores the status of the connected toys at the time of call. **This data does not automatically refresh**, so you may want to periodically resynchronize it, especially if relying on the battery information or having just received an error message from the connection attempt.

### Network errors.

If experiencing any error, such as Lovense Remote app not joinable, no toys connected, etc. the `GDLovense.last_error` variable can be checked. The `GDLovense._get_error_string(GDLovense.last_error)` function can be called to get a human-readable message describing the issue.

> [!NOTE]
> Lovense sometimes uses standard HTTP codes for other meanings than their official ones. So make sure to properly communicate with the players what went wrong, and not to assume it is a generic HTTP error.

## Using `GDLovenseToyFunction`.

The main way of interacting with this integration is through the use of `GDLovenseToyFunction` nodes.

This node contains the following export variables that need to be set-up internally:
* `gd_lovense` (`GDLovense`) link to the node that will manage the connection to the Lovense Remote app.

It also includes the following variables that are recommended to be set by the player:
* `frequency` (`float`, default `5.0`) maximum frequency at which this toy will poll the API. Meaning that it will regularly send its data to the `GDLovense` node, which will decide whether to send on the network or not. Higher value obviously means higher network usage.

### Setting-up the `toy_type`.

This `GDLovenseToyFunction` node relies on setting-up the type of toy that be interacted with firsthand.

A list of all available Lovense toys as well as their intended use has been compiled within this code, so the detection will pre-populate the toy types when [synching connected toys](#synching-connected-toys). It can also be changed manually by accessing the `GDLovenseToy.type` variable for each of the `GDLovense.connected_toys`.

### Sending commands to the toy.

Upon setting up the desired toy type, a list of all typically-available functions for toys that match this type will appear. All of these functions are simple `float` variables that range from `0.0` to `1.0`, indicating the strength intended for this function to be.

When changing any of these function values, the node will automatically try and sync itself with the linked `GDLovense` node, and the toy should activate soon after. There may be a delay due to the way the polling system works to prevent from hyper-sending requests if modifying the values through `Tween` or `AnimationPlayer`.

> [!CAUTION]
> Having several `GDLovenseToyFunction` working on the same toy type will have unintended consequences, as the two nodes will keep on fighting each other to process their respective function values.


### Preparing choregraphies for special game scenes.

As briefly mentioned earlier, this integration has been designed to be used in conjuction with `Tween` and `AnimationPlayer`. This is designed to make preparing choregraphies for special game scenes possible, and easier.

For example, how to use a `Tween` to interact with the toys, to make it slowly increase its vibration up to the maximum power, and then stopping it:
```gdscript
# Make sure the toy is at a known starting point.
gd_lovense_toy_function.vibrate = 0.0

# Prepare the Tween, and wait 2s.
var tween: Tween = create_tween()
tween.tween_property(gd_lovense_toy_function, "vibrate", 1.0, 1.5)
await get_tree().create_timer(2.0).timeout

# Stop the vibration.
gd_lovense_toy_function.vibrate = 0.0
```

The same logic can be applied to `AnimationPlayer` nodes, since the `GDLovenseToyFunction` node exposes its variables to the editor, so they can easily be sampled to make curves and whatnot.

It is however recommended not to dynamically change the `GDLovenseToyFunction.toy_type` when using `AnimationPlayer`, and instead rely on several nodes that manage the different toy types if you want to have different profiles for different types.
