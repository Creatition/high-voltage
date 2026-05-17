extends RefCounted
class_name BSPPartitioner
## Binary-space-partition splitter for dungeon layout.
##
## Recursively splits a rectangular region into smaller leaves until no leaf
## can be split further. Each leaf becomes a candidate room slot — the
## DungeonGenerator picks one cell inside each leaf to be the room, then
## carves corridors between sibling leaves.
##
## Why BSP + walker instead of pure walker:
##   - Walker dungeons curl in on themselves and produce few side branches.
##   - BSP guarantees visual spread + reachable subdivisions for shop/shrine
##     rooms to live in their own pocket of the map.
##
## Designed for small grids (8x8..12x12), not big roguelike maps — speed isn't
## the constraint; layout quality is.

const MIN_LEAF_SIZE: int = 2

var rng: RandomNumberGenerator
var leaves: Array = []                  # Array[Rect2i]
var connections: Array = []             # Array of [Rect2i, Rect2i] sibling pairs


func _init(p_rng: RandomNumberGenerator = null) -> void:
	rng = p_rng if p_rng != null else RandomNumberGenerator.new()


func partition(rect: Rect2i, max_depth: int = 4) -> void:
	leaves.clear()
	connections.clear()
	_split(rect, max_depth)


func _split(rect: Rect2i, depth: int) -> void:
	if depth <= 0 or (rect.size.x <= MIN_LEAF_SIZE * 2 and rect.size.y <= MIN_LEAF_SIZE * 2):
		leaves.append(rect)
		return
	var split_horizontal := rect.size.x < rect.size.y
	# A small random chance to flip orientation to avoid grid-aligned monotony.
	if rng.randf() < 0.25:
		split_horizontal = not split_horizontal
	if split_horizontal and rect.size.y < MIN_LEAF_SIZE * 2:
		split_horizontal = false
	if (not split_horizontal) and rect.size.x < MIN_LEAF_SIZE * 2:
		split_horizontal = true
	var a: Rect2i
	var b: Rect2i
	if split_horizontal:
		var min_y := MIN_LEAF_SIZE
		var max_y := rect.size.y - MIN_LEAF_SIZE
		if max_y <= min_y:
			leaves.append(rect)
			return
		var split: int = rng.randi_range(min_y, max_y)
		a = Rect2i(rect.position, Vector2i(rect.size.x, split))
		b = Rect2i(rect.position + Vector2i(0, split), Vector2i(rect.size.x, rect.size.y - split))
	else:
		var min_x := MIN_LEAF_SIZE
		var max_x := rect.size.x - MIN_LEAF_SIZE
		if max_x <= min_x:
			leaves.append(rect)
			return
		var split: int = rng.randi_range(min_x, max_x)
		a = Rect2i(rect.position, Vector2i(split, rect.size.y))
		b = Rect2i(rect.position + Vector2i(split, 0), Vector2i(rect.size.x - split, rect.size.y))
	connections.append([a, b])
	_split(a, depth - 1)
	_split(b, depth - 1)


## Pick a single cell inside a leaf to act as that leaf's "room slot".
func cell_in_leaf(leaf: Rect2i) -> Vector2i:
	var rx: int = leaf.position.x + rng.randi_range(0, maxi(leaf.size.x - 1, 0))
	var ry: int = leaf.position.y + rng.randi_range(0, maxi(leaf.size.y - 1, 0))
	return Vector2i(rx, ry)
