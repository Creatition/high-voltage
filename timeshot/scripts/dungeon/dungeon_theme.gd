extends RefCounted
class_name DungeonTheme
## A theme bundles everything visual + flavour for an era's dungeon:
##   - palette (floor / wall / accent colours, used by templates that haven't
##     baked their own art yet)
##   - prop scenes (decorative things scattered across rooms)
##   - tile_scene_id (which tile/floor scene to use when a template asks for
##     a generic ground tile — present, medieval-stone, sandstone, etc.)
##
## Themes are *data only* and live in DungeonThemeRegistry so the generator can
## look them up by era id.

var era_id: String
var floor_color: Color
var wall_color: Color
var accent_color: Color
var tile_scene_id: String
var prop_scene_ids: Array[String] = []
var ambient_track: String = ""
var boss_arena_template: String = ""    # special-case bespoke boss arena
var description: String = ""


func _init(p_era: String = "present") -> void:
	era_id = p_era
