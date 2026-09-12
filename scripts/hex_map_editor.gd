class_name HexMapEditor
extends CanvasLayer
const RAY_LENGTH: float = 1000.0

@export var hex_grid: HexGrid
@export var camera: Camera3D
@export var colors: Array[Color] = [
	Color.BLUE,
	Color.SANDY_BROWN,
	Color.WEB_GREEN,
	Color.LIGHT_GRAY,
]

@export var color_buttons: Array[Button] = [];
@export var elevation_slider: HSlider;
@export var elevation_label: Label;

@export var brush_size_slider: HSlider;
@export var brush_size_label: Label;

@export var no_color_button: Button;
@export var apply_elevation_toggle: CheckButton;
@export var labels_toggle: CheckButton;

var _active_color: Color;
var _active_elevation: int = 0;

var _apply_color: bool = true;
var _apply_elevation: bool = true;

var _brush_size: int = 0;

func _ready() -> void:
	assert(not colors.is_empty());
	assert(color_buttons.size() == colors.size());

	var button_group := ButtonGroup.new();

	for index in range(color_buttons.size()):
		var button: Button = color_buttons[index];

		button.toggle_mode = true;
		button.button_group = button_group;
		button.self_modulate = colors[index];

		button.pressed.connect(
			select_color.bind(index)
		);
		
	no_color_button.toggle_mode = true;
	no_color_button.button_group = button_group;
	no_color_button.pressed.connect(select_color.bind(-1));
	
	apply_elevation_toggle.set_pressed_no_signal(true);
	apply_elevation_toggle.toggled.connect(set_apply_elevation);
	
	labels_toggle.set_pressed_no_signal(false);
	labels_toggle.toggled.connect(show_labels);

	color_buttons[0].button_pressed = true;
	select_color(0);
	
	elevation_slider.value_changed.connect(set_elevation);
	set_elevation(elevation_slider.value);
	
	brush_size_slider.value_changed.connect(set_brush_size);
	set_brush_size(brush_size_slider.value);

func _physics_process(_delta: float) -> void:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return

	# Do not paint the map while the pointer is over UI.
	if get_viewport().gui_get_hovered_control() != null:
		return

	_handle_input()

func _edit_cell(cell: HexCell) -> void:
	if cell == null:
		return;

	if _apply_color:
		cell.color = _active_color;

	if _apply_elevation:
		cell.elevation = _active_elevation;
	
func _handle_input() -> void:
	var mouse_position: Vector2 = (
		get_viewport().get_mouse_position()
	);

	var ray_origin: Vector3 = (
		camera.project_ray_origin(mouse_position)
	);

	var ray_end: Vector3 = (
		ray_origin
		+ camera.project_ray_normal(mouse_position)
		* RAY_LENGTH
	);

	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_end
	);

	var space_state: PhysicsDirectSpaceState3D = (
		hex_grid.get_world_3d().direct_space_state
	);

	var hit: Dictionary = space_state.intersect_ray(query);

	if hit.is_empty():
		return;

	var collider := hit["collider"] as Object;

	if not hex_grid.is_grid_collider(collider):
		return;

	var hit_position: Vector3 = hit["position"];
	_edit_cells(hex_grid.get_cell(hit_position));
	
func _edit_cells(centre: HexCell) -> void:
	if centre == null:
		return;

	var centre_x: int = centre.coordinates.X;
	var centre_z: int = centre.coordinates.Z;

	for row in range(_brush_size + 1):
		var z: int = centre_z - _brush_size + row;
		for x in range(centre_x - row, centre_x + _brush_size + 1):
			_edit_cell(hex_grid.get_cell_at_axial(x, z));
	
	for row in range(_brush_size):
		var z: int = centre_z + _brush_size - row;
		for x in range(centre_x - _brush_size, centre_x + row + 1):
			_edit_cell(hex_grid.get_cell_at_axial(x, z));

func select_color(index: int) -> void:
	if index == -1:
		_apply_color = false;
		return;
		
	if index < 0 or index >= colors.size():
		return;
		
	_apply_color = true;
	_active_color = colors[index];

func set_apply_elevation(enabled: bool) -> void:
	_apply_elevation = enabled;
	
func set_elevation(value: float) -> void:
	_active_elevation = roundi(value);
	elevation_label.text = str(roundi(value));
	
func set_brush_size(value: float) -> void:
	_brush_size = maxi(0, roundi(value));
	brush_size_label.text = str(_brush_size);
	
func show_labels(enabled: bool) -> void:
	hex_grid.show_labels(enabled);
