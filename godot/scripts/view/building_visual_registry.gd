extends Node

## Maps building stems / IDs to SpriteFrames (idle + working).

const GFX_ROOT := "res://resources/gfx/"

var _frames_by_stem: Dictionary = {}


func get_sprite_frames_for_building(building_id: int) -> SpriteFrames:
	var stem := ContentLoader.stem_for_building_id(building_id)
	if _frames_by_stem.has(stem):
		return _frames_by_stem[stem] as SpriteFrames
	for manifest_path in manifest_paths_for_stem(stem):
		if FileAccess.file_exists(manifest_path):
			_load_manifest_for_stem(stem, manifest_path)
			if _frames_by_stem.has(stem):
				return _frames_by_stem[stem] as SpriteFrames
	return _make_placeholder_frames(Color(0.55, 0.55, 0.55), Color(0.75, 0.55, 0.35))


func manifest_paths_for_stem(stem: String) -> Array[String]:
	var paths: Array[String] = []
	var pack_root := ContentTheme.gfx_root.strip_edges()
	if not pack_root.is_empty():
		paths.append("%s/%s/sprite_manifest.json" % [pack_root, stem])
	paths.append("%s%s/sprite_manifest.json" % [GFX_ROOT, stem])
	return paths


func get_dlc_tint(stem: String) -> Color:
	var pack_manifest := _pack_sprite_manifest_path()
	if pack_manifest.is_empty():
		return Color.WHITE
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(pack_manifest))
	var tints: Dictionary = data.get("building_tints", {})
	if tints.has(stem):
		var c: Array = tints[stem]
		return Color(float(c[0]), float(c[1]), float(c[2]), float(c[3]))
	return Color.WHITE


func _pack_sprite_manifest_path() -> String:
	var pack_root := ContentTheme.gfx_root.strip_edges()
	if pack_root.is_empty():
		return ""
	var path := "%s/sprite_manifest.json" % pack_root
	if FileAccess.file_exists(path):
		return path
	return ""


func animation_for_building(building: Building) -> StringName:
	if _building_has_active_collector_haul(building):
		return &"working"
	var producer := building.get_producer()
	if producer == null:
		return &"idle"
	var state := producer._get_current_state()
	if state == ProductionStates.PRODUCING:
		return &"working"
	return &"idle"


static func _building_has_active_collector_haul(building: Building) -> bool:
	if building.collecting == null:
		return false
	for collector in building.collecting.collectors:
		if collector is BuildingCollector:
			var bc := collector as BuildingCollector
			if bc.state == "moving" or bc.state == "working":
				return true
	return false


func _load_manifest_for_stem(stem: String, manifest_path: String) -> void:
	if not FileAccess.file_exists(manifest_path):
		_frames_by_stem[stem] = _make_placeholder_frames(
			Color(0.55, 0.4, 0.25), Color(0.7, 0.5, 0.2)
		)
		return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	var base := manifest_path.get_base_dir()
	var anims: Dictionary = manifest.get("animations", {})
	var sf := SpriteFrames.new()
	_add_manifest_animation(sf, &"idle", base, anims.get("idle", {}), "idle.png")
	_add_manifest_animation(sf, &"working", base, anims.get("working", {}), "working.png")
	_frames_by_stem[stem] = sf


func _add_manifest_animation(
	sf: SpriteFrames,
	anim_name: StringName,
	base_dir: String,
	anim_data: Variant,
	fallback_texture: String,
) -> void:
	if typeof(anim_data) != TYPE_DICTIONARY:
		anim_data = {"texture": fallback_texture, "fps": 1.0}
	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, float(anim_data.get("fps", 1.0)))
	var frames: Array = anim_data.get("frames", [])
	if frames.is_empty():
		var tex_path := str(anim_data.get("texture", fallback_texture))
		sf.add_frame(anim_name, _load_texture(base_dir + "/" + tex_path))
		return
	for frame_name in frames:
		sf.add_frame(anim_name, _load_texture(base_dir + "/" + str(frame_name)))


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
