class_name HexGrid
extends Node3D

@export_range(1, 100, 1) var chunk_count_x: int = 4
@export_range(1, 100, 1) var chunk_count_z: int = 3
@export var hex_cell: PackedScene;
@export var chunk_scene: PackedScene
@export var camera: Camera3D
@export var default_color: Color = Color.WHITE
@export var noise_source: Texture2D

const RAY_LENGTH: float = 1000.0;

var cells: Array[HexCell] = [];
var chunks: Array[HexGridChunk] = [];
var _cellCountX: int = 6;
var _cellCountZ: int = 6;

func _ready()-> void:
	assert(noise_source != null, "Assign the noise texture on HexGrid.")
	HexMetrics.noise_image = noise_source.get_image()
	assert(HexMetrics.noise_image != null)
	assert(not HexMetrics.noise_image.is_compressed(), "Import noise as Lossless.")
	
	_cellCountX = chunk_count_x * HexMetrics.CHUNK_SIZE_X;
	_cellCountZ = chunk_count_z * HexMetrics.CHUNK_SIZE_Z;
	
	_create_chunks();
	create_cells();
	
	refresh();

func _create_chunks() -> void:
	chunks.resize(chunk_count_x * chunk_count_z);

	for z in range(chunk_count_z):
		for x in range(chunk_count_x):
			var chunk := chunk_scene.instantiate() as HexGridChunk;
			chunk.name = "Chunk_%d_%d" % [x, z];
			add_child(chunk);
			chunks[x + z * chunk_count_x] = chunk;
			
func create_cells() -> void:
	cells.resize(_cellCountZ * _cellCountX)

	var i: int = 0
	for z in range(_cellCountZ):
		for x in range(_cellCountX):
			create_cell(x, z, i);
			i += 1;

func _add_cell_to_chunk(x: int, z: int, cell: HexCell) -> void:
	var chunk_x: int = floori(float(x) / HexMetrics.CHUNK_SIZE_X);
	var chunk_z: int = floori(float(z) / HexMetrics.CHUNK_SIZE_Z);
	var chunk: HexGridChunk = chunks[chunk_x + chunk_z * chunk_count_x];

	var local_x: int = x % HexMetrics.CHUNK_SIZE_X;
	var local_z: int = z % HexMetrics.CHUNK_SIZE_Z;
	chunk.add_cell(local_x + local_z * HexMetrics.CHUNK_SIZE_X, cell);

func get_cell(world_position: Vector3) -> HexCell:
	var coordinates := HexCoordinates.FROM_POSITION(to_local(world_position));
	return get_cell_at_axial(coordinates.X, coordinates.Z);

## get a cell at a given x and z pos in the hex map
func get_cell_at_axial(x: int, z: int) -> HexCell:
	if z < 0 or z >= _cellCountZ:
		return null;

	var offset_x: int = x + floori(float(z) / 2.0);
	if offset_x < 0 or offset_x >= _cellCountX:
		return null;

	return cells[offset_x + z * _cellCountX];

func refresh() -> void:
	for chunk in chunks:
		chunk.refresh()

func is_grid_collider(collider: Object) -> bool:
	var body : StaticBody3D = collider as StaticBody3D;
	return (
		body != null
		and is_ancestor_of(body)
		and body.get_parent() is HexMesh
	);

# try to connect a neighbor with a given coord to a cell (fail if coords out of bounds)
func _connect_neighbor(
	cell: HexCell,
	direction: int,
	x: int,
	z: int
	) -> void:
	if x < 0 or x >= _cellCountX or z < 0 or z >= _cellCountZ:
		return;

	cell.set_neighbor(direction, cells[x + z * _cellCountX]);

func show_labels(enabled: bool) -> void:
	for chunk in chunks:
		chunk.show_labels(enabled);
		
func create_cell(x: int, z: int, _i: int) -> void:
	
	var new_position: Vector3= Vector3((x+z*0.5-z/2) * HexMetrics.HEX_INNER_RADIUS*2,	0,	z*HexMetrics.HEX_OUTER_RADIUS*1.5);
	var cell: HexCell = hex_cell.instantiate()
	
	add_child(cell)
	cell.position = new_position;
	cell.coordinates = HexCoordinates.FROM_OFFSET_COORDINATES(x,z);
	cell.color = default_color;
	cell.elevation = 0
	
	cells[_i] = cell;
	
	# Sort out cell neighbor graphs
	var row_shift: int = z % 2

	_connect_neighbor(cell, HexDirection.W, x - 1, z);
	_connect_neighbor(cell, HexDirection.SW, x - 1 + row_shift, z - 1);
	_connect_neighbor(cell, HexDirection.SE, x + row_shift, z - 1);

	
	var label: Label3D = cell.get_node("CoordinateLabel") as Label3D;
	label.text = cell.coordinates._to_string_separate_lines();
	
	_add_cell_to_chunk(x, z, cell);
