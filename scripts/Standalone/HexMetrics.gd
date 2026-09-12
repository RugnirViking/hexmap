class_name HexMetrics
extends Node

static var HEX_OUTER_RADIUS: float = 10;
static var HEX_INNER_RADIUS : float = HEX_OUTER_RADIUS * 0.866025404;
static var HEX_CORNERS : Array[Vector3] = [
	Vector3(0,					0,		HEX_OUTER_RADIUS			),
	Vector3(HEX_INNER_RADIUS,	0,		0.5 * HEX_OUTER_RADIUS		),
	Vector3(HEX_INNER_RADIUS,	0,		-0.5 * HEX_OUTER_RADIUS		),
	Vector3(0,					0,		-HEX_OUTER_RADIUS			),
	Vector3(-HEX_INNER_RADIUS,	0,		-0.5 * HEX_OUTER_RADIUS		),
	Vector3(-HEX_INNER_RADIUS,	0,		0.5 *HEX_OUTER_RADIUS		),
	Vector3(0,					0,		HEX_OUTER_RADIUS			)
]
static var noise_image: Image;

const SOLID_FACTOR: float = 0.8; # how much of the hex is solid color
# how much of the hex is blended with neighbors
const BLEND_FACTOR: float = 1.0 - SOLID_FACTOR;
const ELEVATION_STEP: float = 3.0; # how high a single step of elevation goes up or down

const TERRACES_PER_SLOPE: int = 2;
const TERRACE_STEPS: int = TERRACES_PER_SLOPE * 2 + 1;
const HORIZONTAL_TERRACE_STEP_SIZE: float = 1.0 / TERRACE_STEPS;
const VERTICAL_TERRACE_STEP_SIZE: float = 1.0 / (TERRACES_PER_SLOPE + 1);
const NOISE_SCALE: float = 0.003;
const CELL_PERTURB_STRENGTH: float = 4.0;
const CELL_ELEVATION_PERTURB_STRENGTH: float = 1.5;
const CHUNK_SIZE_X: int = 5;
const CHUNK_SIZE_Z: int = 5;

static func get_first_corner(direction: int) -> Vector3:
	return HEX_CORNERS[direction];


static func get_second_corner(direction: int) -> Vector3:
	return HEX_CORNERS[(direction + 1) % HexDirection.COUNT];


static func get_first_solid_corner(direction: int) -> Vector3:
	return get_first_corner(direction) * SOLID_FACTOR;


static func get_second_solid_corner(direction: int) -> Vector3:
	return get_second_corner(direction) * SOLID_FACTOR;
	
static func get_bridge(direction: int) -> Vector3:
	return (
		get_first_corner(direction)
		+ get_second_corner(direction)
	) * BLEND_FACTOR;

static func get_edge_type(elevation_a: int, elevation_b: int) -> int:
	var difference: int = absi(elevation_a - elevation_b)
	if difference == 0:
		return HexEdgeType.FLAT
	if difference == 1:
		return HexEdgeType.SLOPE
	return HexEdgeType.CLIFF

## (I think) picks a point between point a and b that is step/HORIZONTAL_TERRACE_STEP_SIZE between the two
static func terrace_lerp(a: Vector3, b: Vector3, step: int) -> Vector3:
	var horizontal: float = step * HORIZONTAL_TERRACE_STEP_SIZE;
	var vertical: float = floori((step + 1) / 2.0) * VERTICAL_TERRACE_STEP_SIZE;

	return Vector3(
		lerpf(a.x, b.x, horizontal),
		lerpf(a.y, b.y, vertical),
		lerpf(a.z, b.z, horizontal)
	);

static func terrace_color_lerp(a: Color, b: Color, step: int) -> Color:
	return a.lerp(b, step * HORIZONTAL_TERRACE_STEP_SIZE)

static func _noise_pixel(x: int, y: int) -> Color:
	var size: Vector2i = noise_image.get_size();
	return noise_image.get_pixel(posmod(x, size.x), posmod(y, size.y));
	
static func sample_noise(point: Vector3) -> Color:
	var size: Vector2i = noise_image.get_size();
	var u: float = fposmod(point.x * NOISE_SCALE, 1.0);
	var v: float = fposmod(point.z * NOISE_SCALE, 1.0);
	var px: float = u * size.x - 0.5;
	var py: float = v * size.y - 0.5;
	var x0: int = floori(px);
	var y0: int = floori(py);
	var tx: float = px - x0;
	var ty: float = py - y0;

	var top: Color = _noise_pixel(x0, y0).lerp(
		_noise_pixel(x0 + 1, y0), tx
	);
	var bottom: Color = _noise_pixel(x0, y0 + 1).lerp(
		_noise_pixel(x0 + 1, y0 + 1), tx
	);
	return top.lerp(bottom, ty);
	
