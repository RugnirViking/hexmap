class_name HexCoordinates
extends Node

var X: int;
var Z: int;

func hex_coordinates (x: int, z: int) -> void:
	X = x;
	Z = z;

var Y: int: 
	get: 
		return -X - Z;

func _to_string() -> String:
	return "(" + str(X) + ", " + str(Y) + ", " + str(Z) + ")";
	
func _to_string_separate_lines() -> String:
	return str(X) + "\n" + str(Y)+ "\n" + str(Z);
	
static func FROM_OFFSET_COORDINATES(x: int, z: int) -> HexCoordinates:
	var coords: HexCoordinates = HexCoordinates.new();
	coords.hex_coordinates(x - z / 2,z);
	return coords;

static func FROM_POSITION(position: Vector3) -> HexCoordinates:
	var fractional_x: float = (
		position.x / (HexMetrics.HEX_INNER_RADIUS * 2.0)
	)
	var fractional_y: float = -fractional_x

	var offset: float = (
		position.z / (HexMetrics.HEX_OUTER_RADIUS * 3.0)
	)

	fractional_x -= offset
	fractional_y -= offset

	var fractional_z: float = -fractional_x - fractional_y

	var rounded_x: int = roundi(fractional_x)
	var rounded_y: int = roundi(fractional_y)
	var rounded_z: int = roundi(fractional_z)

	if rounded_x + rounded_y + rounded_z != 0:
		var delta_x: float = absf(fractional_x - rounded_x)
		var delta_y: float = absf(fractional_y - rounded_y)
		var delta_z: float = absf(fractional_z - rounded_z)

		if delta_x > delta_y and delta_x > delta_z:
			rounded_x = -rounded_y - rounded_z
		elif delta_z > delta_y:
			rounded_z = -rounded_x - rounded_y
			
	var coords: HexCoordinates = HexCoordinates.new();
	coords.hex_coordinates(rounded_x, rounded_z);
	return coords
