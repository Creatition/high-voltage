extends RefCounted
class_name DungeonCell
## A single cell in the dungeon grid. Rooms are 1x1 cells; corridors are also
## tracked here. The cell remembers which of its four neighbours it connects to
## (NORTH/EAST/SOUTH/WEST), which the generator uses to carve doors and which
## the minimap uses to draw walls.
##
## Cells are pure data — they hold no Node2Ds. Templates own the visuals.

const DIR_NORTH := Vector2i(0, -1)
const DIR_EAST  := Vector2i(1, 0)
const DIR_SOUTH := Vector2i(0, 1)
const DIR_WEST  := Vector2i(-1, 0)
const DIRS := [DIR_NORTH, DIR_EAST, DIR_SOUTH, DIR_WEST]

enum Type {
	EMPTY,        ## Outside the dungeon
	START,        ## Player spawn room
	NORMAL,       ## Standard combat room
	ELITE,        ## Tougher fight, better reward
	SHOP,         ## ShopTerminal room
	SHRINE,       ## RewardShrine room
	BOSS,         ## Era's boss
	SECRET,       ## Hidden room behind a breakable wall
	CORRIDOR,     ## Connector between rooms
}

var coord: Vector2i = Vector2i.ZERO
var type: int = Type.EMPTY
var connections: Array[Vector2i] = []     ## Directions this cell connects to (subset of DIRS)
var era: String = "present"
var depth: int = 0                         ## Graph distance from START cell
var template_id: String = ""               ## Filled in during template-stamping pass
var visited: bool = false                  ## For player-progress / minimap
var has_loot: bool = false
var has_secret_hint: bool = false          ## A neighbour cell points at a SECRET behind a wall


func connect_to(direction: Vector2i) -> void:
	if direction in connections:
		return
	connections.append(direction)


func disconnect_from(direction: Vector2i) -> void:
	connections.erase(direction)


func is_connected_to(direction: Vector2i) -> bool:
	return direction in connections


func is_room() -> bool:
	return type != Type.EMPTY and type != Type.CORRIDOR


func is_combat() -> bool:
	return type == Type.NORMAL or type == Type.ELITE or type == Type.BOSS


func type_name() -> String:
	match type:
		Type.EMPTY:    return "empty"
		Type.START:    return "start"
		Type.NORMAL:   return "normal"
		Type.ELITE:    return "elite"
		Type.SHOP:     return "shop"
		Type.SHRINE:   return "shrine"
		Type.BOSS:     return "boss"
		Type.SECRET:   return "secret"
		Type.CORRIDOR: return "corridor"
	return "?"


func opposite(direction: Vector2i) -> Vector2i:
	return Vector2i(-direction.x, -direction.y)
