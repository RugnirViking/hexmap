class_name HexMapCamera
extends Node3D

@onready var grid: HexGrid = get_parent() as HexGrid;
@onready var swivel: Node3D = $Swivel;
@onready var stick: Node3D = $Swivel/Stick;

@export var distance_zoomed_out: float = 250.0;
@export var distance_zoomed_in: float = 45.0;

@export var pitch_zoomed_out: float = -90.0;
@export var pitch_zoomed_in: float = -45.0;

@export var move_speed_zoomed_out: float = 400.0;
@export var move_speed_zoomed_in: float = 100.0;

@export var rotation_speed: float = 180.0;

@export var zoom_step: float = 0.1;
@export var mouse_rotation_degrees_per_pixel: float = 0.25;

@onready var view_camera: Camera3D = $Swivel/Stick/Camera3D;

var _drag_button: MouseButton = MOUSE_BUTTON_NONE;
var _drag_start_mouse: Vector2;
var _drag_start_yaw: float;
var _drag_start_pitch: float;
var _pan_anchor: Vector3;

var _zoom: float = 1.0;

func _ready() -> void:
	_centre_on_map.call_deferred();

func _process(delta: float) -> void:
	var turn: float = Input.get_axis("map_rotate_left", "map_rotate_right");
	rotation_degrees.y = wrapf(
		rotation_degrees.y - turn * rotation_speed * delta, 0.0, 360.0
	);
	
	var movement: Vector2 = Input.get_vector(
		"map_left", "map_right", "map_forward", "map_back"
	);
	_adjust_position(movement, delta);

func _adjust_position(movement: Vector2, delta: float) -> void:
	var direction: Vector3 = basis * Vector3(movement.x, 0.0, movement.y);
	var speed: float = lerpf(
		move_speed_zoomed_out, move_speed_zoomed_in, _zoom
	);
	position = _clamp_position(position + direction * speed * delta);

func _clamp_position(candidate: Vector3) -> Vector3:
	var maximum: Vector3 = _map_maximum();
	candidate.x = clampf(candidate.x, 0.0, maximum.x);
	candidate.z = clampf(candidate.z, 0.0, maximum.z);
	return candidate;

func _map_maximum() -> Vector3:
	return Vector3(
		(grid._cellCountX - 0.5) * HexMetrics.HEX_INNER_RADIUS * 2.0,
		0.0,
		(grid._cellCountZ - 1) * HexMetrics.HEX_OUTER_RADIUS * 1.5
	);

func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton or not event.pressed:
		return;
	if not event.pressed:
		return;
	if _drag_button != MOUSE_BUTTON_NONE:
		return;
	if get_viewport().gui_get_hovered_control() != null:
		return;
	
	match event.button_index:
		MOUSE_BUTTON_RIGHT:
			_drag_button = MOUSE_BUTTON_RIGHT;
			_drag_start_mouse = event.position;
			_drag_start_yaw = rotation_degrees.y;
			_drag_start_pitch = swivel.rotation_degrees.x;

		MOUSE_BUTTON_MIDDLE:
			var hit: Variant = _mouse_on_pan_plane(event.position);
			if hit == null:
				return;

			_pan_anchor = hit as Vector3;
			_drag_button = MOUSE_BUTTON_MIDDLE;

		MOUSE_BUTTON_WHEEL_UP:
			_adjust_zoom(zoom_step);

		MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_zoom(-zoom_step);

		_:
			return;

	get_viewport().set_input_as_handled();

func _input(event: InputEvent) -> void:
	if _drag_button == MOUSE_BUTTON_NONE:
		return;

	if event is InputEventMouseButton:
		if event.button_index == _drag_button and not event.pressed:
			_drag_button = MOUSE_BUTTON_NONE;
			get_viewport().set_input_as_handled();
		return;

	if event is not InputEventMouseMotion:
		return;

	match _drag_button:
		MOUSE_BUTTON_RIGHT:
			_rotate_drag(event.position);

		MOUSE_BUTTON_MIDDLE:
			_pan_drag(event.position);

	get_viewport().set_input_as_handled()

func _rotate_drag(mouse_position: Vector2) -> void:
	var displacement: Vector2 = mouse_position - _drag_start_mouse;

	rotation_degrees.y = (
		_drag_start_yaw
		- displacement.x * mouse_rotation_degrees_per_pixel
	);

	swivel.rotation_degrees.x = clampf(
		_drag_start_pitch
		- displacement.y * mouse_rotation_degrees_per_pixel,
		-90.0,
		-15.0
	);


func _pan_drag(mouse_position: Vector2) -> void:
	var hit: Variant = _mouse_on_pan_plane(mouse_position);
	if hit == null:
		return;

	var current_point: Vector3 = hit as Vector3;
	position = _clamp_position(position + _pan_anchor - current_point);

func _adjust_zoom(amount: float) -> void:
	_zoom = clampf(_zoom + amount, 0.0, 1.0);
	stick.position.z = lerpf(distance_zoomed_out, distance_zoomed_in, _zoom);
	swivel.rotation_degrees.x = lerpf(pitch_zoomed_out, pitch_zoomed_in, _zoom);

func _centre_on_map() -> void:
	position = _map_maximum() * 0.5;

func _mouse_on_pan_plane(mouse_position: Vector2) -> Variant:
	var world_origin: Vector3 = view_camera.project_ray_origin(mouse_position);
	var world_direction: Vector3 = view_camera.project_ray_normal(mouse_position);

	var grid_inverse: Transform3D = grid.global_transform.affine_inverse();
	var local_origin: Vector3 = grid_inverse * world_origin;
	var local_direction: Vector3 = (
		grid_inverse.basis * world_direction
	).normalized();

	var plane := Plane(Vector3.UP, position.y);
	return plane.intersects_ray(local_origin, local_direction);
