class_name LazyBinaryCacheElement
extends RefCounted

var _owner: BinaryBuildabilityCache
var _width: int
var _cache: CoordSet = CoordSet.new()
var _ready: bool = false


func _init(owner: BinaryBuildabilityCache, width: int) -> void:
	_owner = owner
	_width = width


func ensure_ready() -> CoordSet:
	if not _ready:
		_init_size_cache()
	return _cache


func _init_size_cache() -> void:
	var r3x3: CoordSet = _owner.cache[Vector2i(3, 3)]
	var offset := _width - 3
	var usable := CoordSet.new()
	for coords in r3x3.keys():
		var c: Vector2i = coords
		var x := c.x
		var y := c.y
		if (
			r3x3.has(Vector2i(x + offset, y))
			and r3x3.has(Vector2i(x, y + offset))
			and r3x3.has(Vector2i(x + offset, y + offset))
		):
			usable.add(coords)
	_cache = usable
	_ready = true
	var size := Vector2i(_width, _width)
	_owner.cache[size] = _cache
