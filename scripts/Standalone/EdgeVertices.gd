class_name EdgeVertices;
extends RefCounted;

var v1: Vector3;
var v2: Vector3;
var v3: Vector3;
var v4: Vector3;


func _init(
	corner1: Vector3 = Vector3.ZERO,
	corner2: Vector3 = Vector3.ZERO
) -> void:
	v1 = corner1;
	v2 = corner1.lerp(corner2, 1.0 / 3.0);
	v3 = corner1.lerp(corner2, 2.0 / 3.0);
	v4 = corner2;
	
static func terrace_lerp(a: EdgeVertices, b: EdgeVertices, step: int) -> EdgeVertices:
	var result := EdgeVertices.new();
	result.v1 = HexMetrics.terrace_lerp(a.v1, b.v1, step);
	result.v2 = HexMetrics.terrace_lerp(a.v2, b.v2, step);
	result.v3 = HexMetrics.terrace_lerp(a.v3, b.v3, step);
	result.v4 = HexMetrics.terrace_lerp(a.v4, b.v4, step);
	return result;
