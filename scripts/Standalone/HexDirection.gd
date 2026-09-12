class_name HexDirection
extends RefCounted

enum {
	NE,
	E,
	SE,
	SW,
	W,
	NW,
	COUNT,
}

static func opposite(direction: int) -> int:
	return (direction + 3) % COUNT;

static func previous(direction: int) -> int:
	if direction == NE:
		return NW;

	return direction - 1;


static func next(direction: int) -> int:
	if direction == NW:
		return NE;

	return direction + 1;
