class_name OverheadCamera
extends Node3D
## Free overhead camera. There is no player character.
## Pitch stays steep so the view cannot drop into a walking camera.
## Pan: WASD / arrows, middle-mouse drag, and screen-edge.
## Orbit: right-mouse drag. Zoom: mouse wheel.

@export var min_distance: float = 12.0
@export var max_distance: float = 60.0
@export var min_pitch_deg: float = 30.0
@export var max_pitch_deg: float = 80.0
@export var pan_speed: float = 25.0
@export var edge_margin: float = 22.0
@export var edge_pan_enabled: bool = true

var distance: float = 40.0
var target_distance: float = 40.0
var pitch_deg: float = 55.0
var yaw_deg: float = 0.0
var _home_position := Vector3.ZERO
var _home_yaw := 0.0
var _home_pitch := 55.0
var _home_distance := 40.0

var bounds_min := Vector2(-40, -12)
var bounds_max := Vector2(40, 12)

var _orbiting := false
var _dragging := false

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_actions()
	camera.current = true
	_apply_transform()


func capture_home() -> void:
	_home_position = global_position
	_home_yaw = yaw_deg
	_home_pitch = pitch_deg
	_home_distance = target_distance


func reset_home() -> void:
	global_position = _home_position
	yaw_deg = _home_yaw
	pitch_deg = _home_pitch
	target_distance = _home_distance
	distance = _home_distance
	_apply_transform()


func set_bounds(min_xz: Vector2, max_xz: Vector2) -> void:
	bounds_min = min_xz
	bounds_max = max_xz
	_clamp_focus()


func _process(delta: float) -> void:
	var step := _unscaled(delta)
	_keyboard_pan(step)
	if edge_pan_enabled and not _orbiting and not _dragging:
		_edge_pan(step)
	pitch_deg = clampf(pitch_deg, min_pitch_deg, max_pitch_deg)
	target_distance = clampf(target_distance, min_distance, max_distance)
	var blend := 1.0 - exp(-10.0 * step)
	distance = lerpf(distance, target_distance, blend)
	_clamp_focus()
	_apply_transform()


func _unscaled(delta: float) -> float:
	# Camera motion ignores game speed and keeps moving while the sim is paused.
	var scale := Engine.time_scale
	if scale <= 0.0001:
		return delta
	return delta / scale


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = mouse.pressed
		elif mouse.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = mouse.pressed
		elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_distance = clampf(target_distance - 2.4, min_distance, max_distance)
		elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_distance = clampf(target_distance + 2.4, min_distance, max_distance)
	elif event is InputEventMouseMotion and (_orbiting or _dragging):
		var motion := event as InputEventMouseMotion
		if _orbiting:
			yaw_deg = wrapf(yaw_deg - motion.relative.x * 0.22, -180.0, 180.0)
			pitch_deg = clampf(pitch_deg - motion.relative.y * 0.16, min_pitch_deg, max_pitch_deg)
		if _dragging:
			# Grab the ground: the focus moves opposite the drag.
			var scale := distance * 0.0018
			global_position -= _look_right() * motion.relative.x * scale
			global_position += _look_forward() * motion.relative.y * scale
			_clamp_focus()


func _keyboard_pan(delta: float) -> void:
	var input := Input.get_vector("pan_left", "pan_right", "pan_back", "pan_forward")
	if input == Vector2.ZERO:
		return
	var speed := pan_speed * (distance / 40.0)
	global_position += (_look_right() * input.x + _look_forward() * input.y) * speed * delta


func _edge_pan(delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var viewport := get_viewport()
	if viewport == null:
		return
	var size := viewport.get_visible_rect().size
	if size.x < 2.0 or size.y < 2.0:
		return
	var mouse := viewport.get_mouse_position()
	if mouse.x < 0.0 or mouse.y < 0.0 or mouse.x > size.x or mouse.y > size.y:
		return
	var pan := Vector2.ZERO
	if mouse.x <= edge_margin:
		pan.x = -1.0
	elif mouse.x >= size.x - edge_margin:
		pan.x = 1.0
	if mouse.y <= edge_margin:
		pan.y = 1.0
	elif mouse.y >= size.y - edge_margin:
		pan.y = -1.0
	if pan == Vector2.ZERO:
		return
	var speed := pan_speed * (distance / 40.0)
	global_position += (_look_right() * pan.x + _look_forward() * pan.y) * speed * delta


func _apply_transform() -> void:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
	camera.position = offset
	if global_position.distance_squared_to(camera.global_position) > 0.001:
		camera.look_at(global_position, Vector3.UP)


func _look_forward() -> Vector3:
	var yaw := deg_to_rad(yaw_deg)
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func _look_right() -> Vector3:
	var yaw := deg_to_rad(yaw_deg)
	return Vector3(cos(yaw), 0.0, -sin(yaw))


func _clamp_focus() -> void:
	global_position.x = clampf(global_position.x, bounds_min.x, bounds_max.x)
	global_position.y = 0.0
	global_position.z = clampf(global_position.z, bounds_min.y, bounds_max.y)


func _ensure_actions() -> void:
	_bind("pan_left", [KEY_A, KEY_LEFT])
	_bind("pan_right", [KEY_D, KEY_RIGHT])
	_bind("pan_forward", [KEY_W, KEY_UP])
	_bind("pan_back", [KEY_S, KEY_DOWN])


func _bind(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)
