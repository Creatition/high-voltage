extends RefCounted
class_name RoomTemplate
## A hand-authored room shape that the generator can stamp into a cell.
##
## Templates are text-grids — small 2D arrays of single-character glyphs —
## so they can be authored by hand without touching .tscn files. Each glyph
## maps to a runtime spawn:
##
##   "."  -> empty floor
##   "#"  -> wall tile
##   "<>v^"-> door anchors (left/right/down/up)
##   "P"  -> player spawn (start rooms only)
##   "e"  -> generic enemy spawn marker (room type decides scene)
##   "E"  -> elite enemy spawn marker
##   "B"  -> boss spawn marker (boss rooms only)
##   "T"  -> trap anchor (era-specific)
##   "$"  -> shop terminal (shop rooms only)
##   "+"  -> reward shrine (shrine rooms only)
##   "*"  -> generic loot/pickup
##   "x"  -> breakable wall (secret-room hint)
##   "p"  -> decoration / prop anchor

var id: String = ""
var room_type: int = DungeonCell.Type.NORMAL
var size: Vector2i = Vector2i.ZERO
var glyphs: PackedStringArray = PackedStringArray()
var tags: Array[String] = []        # e.g. ["medieval", "narrow", "intro"]


func _init(p_id: String, p_room_type: int, p_glyphs: Array, p_tags: Array = []) -> void:
	id = p_id
	room_type = p_room_type
	glyphs = PackedStringArray()
	for row in p_glyphs:
		glyphs.append(String(row))
	if glyphs.size() > 0:
		size = Vector2i(glyphs[0].length(), glyphs.size())
	for t in p_tags:
		tags.append(String(t))


func glyph_at(x: int, y: int) -> String:
	if y < 0 or y >= glyphs.size():
		return "."
	var row: String = glyphs[y]
	if x < 0 or x >= row.length():
		return "."
	return row[x]


func iterate_glyphs() -> Array:
	var out: Array = []
	for y in size.y:
		for x in size.x:
			out.append({
				"pos": Vector2i(x, y),
				"glyph": glyph_at(x, y),
			})
	return out


func has_tag(tag: String) -> bool:
	return tag in tags
