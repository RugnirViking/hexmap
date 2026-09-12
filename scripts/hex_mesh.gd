class_name HexMesh
extends MeshInstance3D

@onready var mesh_collider: CollisionShape3D = (
	$StaticBody3D/CollisionShape3D
)

## add a triangle and move each of the points slightly according to the 
## noise texture. Two points sharing a position should get moved to the same place.
func _add_triangle (surface_tool: SurfaceTool, 
					v1: Vector3, 
					v2: Vector3, 
					v3: Vector3,
					color1: Color,
					color2: Color,
					color3: Color) -> void:
						
	_add_triangle_unperturbed(surface_tool, _perturb(v1), _perturb(v2), _perturb(v3),
		color1, color2, color3);
	
## add a triangle where none of the points get moved
func _add_triangle_unperturbed(surface_tool: SurfaceTool,
	v1: Vector3, v2: Vector3, v3: Vector3,
	c1: Color, c2: Color, c3: Color
	) -> void:
		
	surface_tool.set_color(c1);
	surface_tool.add_vertex(v1);
	surface_tool.set_color(c2);
	surface_tool.add_vertex(v2);
	surface_tool.set_color(c3);
	surface_tool.add_vertex(v3);
	
func _add_quad(surface_tool: SurfaceTool,
	v1: Vector3,
	v2: Vector3,
	v3: Vector3,
	v4: Vector3,
	near_color: Color,
	far_color: Color
	) -> void:
	_add_quad_colors(surface_tool, v1, v2, v3, v4,
		near_color, near_color, far_color, far_color);
		
func _add_quad_colors(
	surface_tool: SurfaceTool,
	v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3,
	c1: Color, c2: Color, c3: Color, c4: Color
	) -> void:
	_add_triangle(surface_tool, v1, v2, v3, c1, c2, c3);
	_add_triangle(surface_tool, v2, v4, v3, c2, c4, c3);
	
func _add_corner_triangle(
	surface_tool: SurfaceTool,
	bottom: Vector3, left: Vector3, right: Vector3,
	bottom_color: Color, left_color: Color, right_color: Color
	) -> void:
	# Corner routines retain the tutorial's geometric left/right order.
	# We need to reverse it here when submitting a triangle to Godot.
	_add_triangle(surface_tool, bottom, right, left,
		bottom_color, right_color, left_color);
	
func _add_corner_triangle_unperturbed(
	surface_tool: SurfaceTool,
	bottom: Vector3, left: Vector3, right: Vector3,
	bottom_color: Color, left_color: Color, right_color: Color
	) -> void:
	# Corner routines retain the tutorial's geometric left/right order.
	# We need to reverse it here when submitting a triangle to Godot.
	_add_triangle_unperturbed(surface_tool, bottom, right, left,
		bottom_color, right_color, left_color);

func _triangulate_cell(surface_tool: SurfaceTool, cell: HexCell) -> void:
	for direction in range(HexDirection.COUNT):
		_triangulate_direction(surface_tool, direction, cell);
	
## calculates all the triangles for a straight edge, split into four separate vertices 
## to allow for more variation ("fanned")
func _triangulate_edge_fan(
	surface_tool: SurfaceTool, centre: Vector3, edge: EdgeVertices, color: Color
	) -> void:
		
	_add_triangle(surface_tool, edge.v1, centre, edge.v2, color, color, color);
	_add_triangle(surface_tool, edge.v2, centre, edge.v3, color, color, color);
	_add_triangle(surface_tool, edge.v3, centre, edge.v4, color, color, color);
	
## for each direction from the hex cell, we turn one face/direction into triangles
func _triangulate_direction(
	surface_tool: SurfaceTool,
	direction: int,
	cell: HexCell
	) -> void:
		
	var centre: Vector3 = to_local(cell.global_position);
	var edge := EdgeVertices.new(
		centre + HexMetrics.get_first_solid_corner(direction),
		centre + HexMetrics.get_second_solid_corner(direction)
	);
	
	_triangulate_edge_fan(surface_tool, centre, edge, cell.color);

	if direction <= HexDirection.SE:
		_triangulate_connection(surface_tool, direction, cell, edge);
		
## triangulate "connections" which are the bits between cells. Terraces, cliffs, and corners
func _triangulate_connection(
	surface_tool: SurfaceTool,
	direction: int,
	cell: HexCell,
	near_edge: EdgeVertices
	) -> void:
	var neighbor: HexCell = cell.get_neighbor(direction);
	if neighbor == null:
		return;

	var bridge: Vector3 = HexMetrics.get_bridge(direction);
	bridge.y = to_local(neighbor.global_position).y - near_edge.v1.y;
	var far_edge := EdgeVertices.new(
		near_edge.v1 + bridge,
		near_edge.v4 + bridge
	);
	# slopes are cliffs
	if cell.get_edge_type(neighbor) == HexEdgeType.SLOPE:
		_triangulate_edge_terraces(
			surface_tool, 
			near_edge, 
			cell,
			far_edge, 
			neighbor
		);
	else:
		# otherwise its flat or a cliff, either way it can be a quad
		_triangulate_edge_strip(surface_tool, near_edge, cell.color, far_edge, neighbor.color);
		
	if direction > HexDirection.E:
		# don't create corners for half the directions - the cell on the other side will make them
		return;
		
	var next_neighbor: HexCell = cell.get_neighbor(HexDirection.next(direction));
	if next_neighbor == null:
		return;

	var v5: Vector3 = near_edge.v4 + HexMetrics.get_bridge(HexDirection.next(direction));
	v5.y = to_local(next_neighbor.global_position).y;
	_triangulate_corner_from_lowest(surface_tool, near_edge.v4, cell, far_edge.v4, neighbor, v5, next_neighbor);

func _triangulate_edge_strip(
	surface_tool: SurfaceTool,
	near_edge: EdgeVertices, near_color: Color,
	far_edge: EdgeVertices, far_color: Color
	) -> void:
	_add_quad(surface_tool, near_edge.v1, near_edge.v2, far_edge.v1, far_edge.v2,
		near_color, far_color)
	_add_quad(surface_tool, near_edge.v2, near_edge.v3, far_edge.v2, far_edge.v3,
		near_color, far_color)
	_add_quad(surface_tool, near_edge.v3, near_edge.v4, far_edge.v3, far_edge.v4,
		near_color, far_color)

## turn a slope/terrace edge "bridge" into a series of steps made of triangles
func _triangulate_edge_terraces(
	surface_tool: SurfaceTool,
	begin: EdgeVertices,
	begin_cell: HexCell,
	end: EdgeVertices, 
	end_cell: HexCell
	) -> void:
		
	var previous: EdgeVertices = begin;
	var previous_color: Color = begin_cell.color;

	for step in range(1, HexMetrics.TERRACE_STEPS + 1):
		var current: EdgeVertices = EdgeVertices.terrace_lerp(begin, end, step);
		var current_color: Color = HexMetrics.terrace_color_lerp(
			begin_cell.color, end_cell.color, step
		);
		_triangulate_edge_strip(surface_tool, previous, previous_color, current, current_color);
		previous = current;
		previous_color = current_color;

func _triangulate_corner_from_lowest(
	surface_tool: SurfaceTool,
	a: Vector3, a_cell: HexCell,
	b: Vector3, b_cell: HexCell,
	c: Vector3, c_cell: HexCell
	) -> void:
	# Rotate the three pairs; do not sort them and change the winding.
	if a_cell.elevation <= b_cell.elevation and a_cell.elevation <= c_cell.elevation:
		_triangulate_corner(surface_tool, a, a_cell, b, b_cell, c, c_cell);
	elif b_cell.elevation <= c_cell.elevation:
		_triangulate_corner(surface_tool, b, b_cell, c, c_cell, a, a_cell);
	else:
		_triangulate_corner(surface_tool, c, c_cell, a, a_cell, b, b_cell);

func _triangulate_corner(
	surface_tool: SurfaceTool,
	bottom: Vector3, bottom_cell: HexCell,
	left: Vector3, left_cell: HexCell,
	right: Vector3, right_cell: HexCell
	) -> void:
	var left_type: int = bottom_cell.get_edge_type(left_cell)
	var right_type: int = bottom_cell.get_edge_type(right_cell)

	if left_type == HexEdgeType.SLOPE and right_type == HexEdgeType.SLOPE:
		_triangulate_corner_terraces(surface_tool, bottom, bottom_cell, left, left_cell, right, right_cell)
	elif left_type == HexEdgeType.SLOPE and right_type == HexEdgeType.FLAT:
		_triangulate_corner_terraces(surface_tool, left, left_cell, right, right_cell, bottom, bottom_cell)
	elif left_type == HexEdgeType.FLAT and right_type == HexEdgeType.SLOPE:
		_triangulate_corner_terraces(surface_tool, right, right_cell, bottom, bottom_cell, left, left_cell)
	elif left_type == HexEdgeType.SLOPE:
		_triangulate_corner_terraces_cliff(surface_tool, bottom, bottom_cell, left, left_cell, right, right_cell)
	elif right_type == HexEdgeType.SLOPE:
		_triangulate_corner_cliff_terraces(surface_tool, bottom, bottom_cell, left, left_cell, right, right_cell)
	elif left_cell.get_edge_type(right_cell) == HexEdgeType.SLOPE:
		if left_cell.elevation < right_cell.elevation:
			_triangulate_corner_cliff_terraces(surface_tool, right, right_cell, bottom, bottom_cell, left, left_cell)
		else:
			_triangulate_corner_terraces_cliff(surface_tool, left, left_cell, right, right_cell, bottom, bottom_cell)
	else:
		_add_corner_triangle(surface_tool, bottom, left, right,
			bottom_cell.color, left_cell.color, right_cell.color)

func _triangulate_corner_terraces(
	surface_tool: SurfaceTool,
	begin: Vector3, begin_cell: HexCell,
	left: Vector3, left_cell: HexCell,
	right: Vector3, right_cell: HexCell
	) -> void:
	var previous_left: Vector3 = begin
	var previous_right: Vector3 = begin
	var previous_left_color: Color = begin_cell.color
	var previous_right_color: Color = begin_cell.color

	for step in range(1, HexMetrics.TERRACE_STEPS + 1):
		var current_left: Vector3 = HexMetrics.terrace_lerp(begin, left, step)
		var current_right: Vector3 = HexMetrics.terrace_lerp(begin, right, step)
		var left_color: Color = HexMetrics.terrace_color_lerp(begin_cell.color, left_cell.color, step)
		var right_color: Color = HexMetrics.terrace_color_lerp(begin_cell.color, right_cell.color, step)

		if step == 1:
			_add_corner_triangle(surface_tool, begin, current_left, current_right,
				begin_cell.color, left_color, right_color)
		else:
			_add_quad_colors(surface_tool, previous_left, previous_right, current_left, current_right,
				previous_left_color, previous_right_color, left_color, right_color)

		previous_left = current_left
		previous_right = current_right
		previous_left_color = left_color
		previous_right_color = right_color

func _triangulate_corner_terraces_cliff(
	surface_tool: SurfaceTool,
	begin: Vector3, begin_cell: HexCell,
	left: Vector3, left_cell: HexCell,
	right: Vector3, right_cell: HexCell
	) -> void:
	var fraction: float = 1.0 / absi(right_cell.elevation - begin_cell.elevation);
	var boundary: Vector3 = _perturb(begin).lerp(_perturb(right), fraction);
	var boundary_color: Color = begin_cell.color.lerp(right_cell.color, fraction);

	_triangulate_boundary_triangle(surface_tool, begin, begin_cell, left, left_cell,
		boundary, boundary_color);

	if left_cell.get_edge_type(right_cell) == HexEdgeType.SLOPE:
		_triangulate_boundary_triangle(surface_tool, left, left_cell, right, right_cell,
			boundary, boundary_color);
	else:
		_add_corner_triangle_unperturbed(
			surface_tool, _perturb(left), _perturb(right), boundary,
			left_cell.color, right_cell.color, boundary_color
		);

func _triangulate_corner_cliff_terraces(
	surface_tool: SurfaceTool,
	begin: Vector3, begin_cell: HexCell,
	left: Vector3, left_cell: HexCell,
	right: Vector3, right_cell: HexCell
	) -> void:
	var fraction: float = 1.0 / absi(left_cell.elevation - begin_cell.elevation);
	var boundary: Vector3 = _perturb(begin).lerp(_perturb(left), fraction);
	var boundary_color: Color = begin_cell.color.lerp(left_cell.color, fraction);

	_triangulate_boundary_triangle(surface_tool, right, right_cell, begin, begin_cell,
		boundary, boundary_color)

	if left_cell.get_edge_type(right_cell) == HexEdgeType.SLOPE:
		_triangulate_boundary_triangle(surface_tool, left, left_cell, right, right_cell,
			boundary, boundary_color)
	else:
		_add_corner_triangle_unperturbed(
			surface_tool, _perturb(left), _perturb(right), boundary,
			left_cell.color, right_cell.color, boundary_color
		)

func _triangulate_boundary_triangle(
	surface_tool: SurfaceTool,
	begin: Vector3, begin_cell: HexCell,
	end: Vector3, end_cell: HexCell,
	boundary: Vector3, boundary_color: Color
	) -> void:
	var previous: Vector3 = _perturb(begin);
	var previous_color: Color = begin_cell.color;

	for step in range(1, HexMetrics.TERRACE_STEPS + 1):
		var current: Vector3 = _perturb(HexMetrics.terrace_lerp(begin, end, step));
		var current_color: Color = HexMetrics.terrace_color_lerp(begin_cell.color, end_cell.color, step);
		_add_corner_triangle_unperturbed(surface_tool, previous, current, boundary,
			previous_color, current_color, boundary_color);
		previous = current;
		previous_color = current_color;
		
## take a point and shift it some random amount in xyz based on noise texture rgb
## (bilinear filtering - we can choose a point between pixels and smoothly interpolate)
func _perturb(point: Vector3) -> Vector3:
	var noise: Color = HexMetrics.sample_noise(point);
	return point + Vector3(
		noise.r * 2.0 - 1.0,
		0,
		noise.b * 2.0 - 1.0
	) * HexMetrics.CELL_PERTURB_STRENGTH;
	

func triangulate(cells: Array[HexCell]) -> void:
	var surface_tool := SurfaceTool.new();
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES);

	# -1 means each triangle gets a flat normal.
	surface_tool.set_smooth_group(-1);

	for cell in cells:
		_triangulate_cell(surface_tool, cell);

	surface_tool.generate_normals();
	
	var generated_mesh: ArrayMesh = surface_tool.commit();
	mesh = generated_mesh;
	
	var trimesh_shape: ConcavePolygonShape3D = (
		generated_mesh.create_trimesh_shape()
	);

	# Useful for our currently flat, single-sided mesh.
	trimesh_shape.backface_collision = true;
	mesh_collider.shape = trimesh_shape;
	
	
