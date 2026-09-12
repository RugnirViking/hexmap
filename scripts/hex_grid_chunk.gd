class_name HexGridChunk
extends Node3D

@onready var hex_mesh: HexMesh = $HexMesh;

var cells: Array[HexCell] = [];
var _labels_visible: bool = false;

func _ready() -> void:
	cells.resize(HexMetrics.CHUNK_SIZE_X * HexMetrics.CHUNK_SIZE_Z);
	set_process(false);

func _process(_delta: float) -> void:
	set_process(false);
	hex_mesh.triangulate(cells);

func refresh() -> void:
	set_process(true);
	
func add_cell(index: int, cell: HexCell) -> void:
	cells[index] = cell;
	cell.chunk = self;
	cell.reparent(self, false);
	
	var label := cell.get_node("CoordinateLabel") as Label3D;
	label.visible = _labels_visible;

func show_labels(enabled: bool) -> void:
	_labels_visible = enabled;
	for cell in cells:
		var label := cell.get_node("CoordinateLabel") as Label3D;
		label.visible = enabled;
