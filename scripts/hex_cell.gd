class_name HexCell
extends Node3D

var coordinates: HexCoordinates;
var color: Color = Color.WHITE:
	set(value):
		if color == value:
			return;
		color = value;
		_refresh();
		
var chunk: HexGridChunk
var _neighbors: Array[HexCell] = [];
var _elevation_initialized: bool = false;

var elevation: int = 0:
	set(value):
		if _elevation_initialized and elevation == value:
			return;
			
		elevation = value;
		_elevation_initialized = true;
		
		var noise: Color = HexMetrics.sample_noise(position);
		position.y = (
			value * HexMetrics.ELEVATION_STEP
			+ (noise.g * 2.0 - 1.0) * HexMetrics.CELL_ELEVATION_PERTURB_STRENGTH
		);
		_refresh();
		
func _init() -> void:
	_neighbors.resize(HexDirection.COUNT);
	
func get_neighbor(direction: int) -> HexCell:
	return _neighbors[direction];

func set_neighbor(direction: int, cell: HexCell) -> void:
	_neighbors[direction] = cell;
	cell._neighbors[HexDirection.opposite(direction)] = self;
	
func get_edge_type(other: HexCell) -> int:
	return HexMetrics.get_edge_type(elevation, other.elevation);

func _refresh() -> void:
	if chunk != null:
		chunk.refresh();
	
	for direction: int in [HexDirection.SW, HexDirection.W, HexDirection.NW]:
		var neighbor: HexCell = get_neighbor(direction);

		if neighbor == null or neighbor.chunk == null:
			continue;

		if neighbor.chunk != chunk:
			neighbor.chunk.refresh();
			
			
	var label: Label3D = get_node("CoordinateLabel") as Label3D;
	label.text = str(coordinates.X) + "\n" + str(coordinates.Z) + "\n" + str(elevation);
