class_name HexEdgeType
extends RefCounted

enum {
	## a flat connection between two cells of the same height 
	FLAT, 
	## a terrace connection between two cells of one height difference
	SLOPE, 
	## a sheer cliff connection between two cells of two or more height difference
	CLIFF 
};
