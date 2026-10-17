class_name BuildingView
extends Node2D

var building: Building
var _sprite: AnimatedSprite2D
var _selected := false
const SELECT_TINT := Color(1.15, 1.15, 0.85, 1.0)
const NORMAL_TINT := Color(1, 1, 1, 1)


func bind(p_building: Building, map_view: MapView) -> void:
	building = p_building
	if _sprite == null:
		_sprite = AnimatedSprite2D.new()
		add_child(_sprite)
	var frames := BuildingVisualRegistry.get_sprite_frames_for_building(building.building_id)
	_sprite.sprite_frames = frames
	var stem := ContentLoader.stem_for_building_id(building.building_id)
	_apply_tint(BuildingVisualRegistry.get_dlc_tint(stem))
	position = map_view.grid_to_screen(building.position)
	z_index = building.position.y
	_sync_animation()


func set_highlighted(on: bool) -> void:
	_selected = on
	z_index = building.position.y + (10 if on else 0)
	var stem := ContentLoader.stem_for_building_id(building.building_id)
	_apply_tint(BuildingVisualRegistry.get_dlc_tint(stem))


func _apply_tint(base: Color) -> void:
	if _sprite == null:
		return
	if _selected:
		_sprite.modulate = base * SELECT_TINT
	else:
		_sprite.modulate = base


func refresh_from_sim() -> void:
	_sync_animation()


func _sync_animation() -> void:
	if building == null or _sprite == null or _sprite.sprite_frames == null:
		return
	var anim := BuildingVisualRegistry.animation_for_building(building)
	if _sprite.sprite_frames.has_animation(anim):
		if _sprite.animation != anim:
			_sprite.play(anim)
	elif _sprite.sprite_frames.has_animation(&"idle"):
		_sprite.play(&"idle")
