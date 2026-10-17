extends Node

## Maps building stems / IDs to SpriteFrames (idle + working).

const GFX_ROOT := "res://resources/gfx/"

var _frames_by_stem: Dictionary = {}
var _manifest_stems: Array[String] = [
	"lumberjackcamp",
	"hunterstent",
	"fishermanstent",
	"brickyard",
	"warehouse",
]


func _ready() -> void:
	for stem in _manifest_stems:
		_load_manifest_for_stem(stem)


func get_sprite_frames_for_building(building_id: int) -> SpriteFrames:
	var stem := ContentLoader.stem_for_building_id(building_id)
	if _frames_by_stem.has(stem):
		return _frames_by_stem[stem] as SpriteFrames
	return _make_placeholder_frames(Color(0.55, 0.55, 0.55), Color(0.75, 0.55, 0.35))


func get_dlc_tint(stem: String) -> Color:
	var path := "res://resources/dlc/northern_company/gfx/sprite_manifest.json"
	if not FileAccess.file_exists(path):
		return Color.WHITE
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var tints: Dictionary = data.get("building_tints", {})
	if tints.has(stem):
		var c: Array = tints[stem]
		return Color(float(c[0]), float(c[1]), float(c[2]), float(c[3]))
	return Color.WHITE


func animation_for_building(building: Building) -> StringName:
	var producer := building.get_producer()
	if producer == null:
		return &"idle"
	var state := producer._get_current_state()
	if state == ProductionStates.PRODUCING:
		return &"working"
	return &"idle"


func _load_manifest_for_stem(stem: String) -> void:
	var manifest_path := "%s%s/sprite_manifest.json" % [GFX_ROOT, stem]
	if not FileAccess.file_exists(manifest_path):
		_frames_by_stem[stem] = _make_placeholder_frames(
			Color(0.55, 0.4, 0.25), Color(0.7, 0.5, 0.2)
		)
		return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	var base := manifest_path.get_base_dir()
	var anims: Dictionary = manifest.get("animations", {})
	var idle_tex := _load_texture(base + "/" + str(anims.get("idle", {}).get("texture", "idle.png")))
	var work_tex := _load_texture(base + "/" + str(anims.get("working", {}).get("texture", "working.png")))
	var sf := SpriteFrames.new()
	sf.add_animation(&"idle")
	sf.set_animation_speed(&"idle", float(anims.get("idle", {}).get("fps", 1.0)))
	sf.add_frame(&"idle", idle_tex)
	sf.add_animation(&"working")
	sf.set_animation_speed(&"working", float(anims.get("working", {}).get("fps", 4.0)))
	sf.add_frame(&"working", work_tex)
	_frames_by_stem[stem] = sf


func _load_texture(path: String) -> Texture2D:
	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color.MAGENTA)
	var tex := ImageTexture.create_from_image(img)
	return tex


func _make_placeholder_frames(idle_c: Color, work_c: Color) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.add_animation(&"idle")
	sf.add_frame(&"idle", _texture_from_color(idle_c))
	sf.add_animation(&"working")
	sf.add_frame(&"working", _texture_from_color(work_c))
	return sf


func _texture_from_color(c: Color) -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return ImageTexture.create_from_image(img)
