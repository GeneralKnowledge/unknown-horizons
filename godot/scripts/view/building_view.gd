class_name BuildingView
extends Node2D

var building: Building
var _sprite: AnimatedSprite2D


func bind(p_building: Building, map_view: MapView) -> void:
	building = p_building
	if _sprite == null:
		_sprite = AnimatedSprite2D.new()
		add_child(_sprite)
	var frames := BuildingVisualRegistry.get_sprite_frames_for_building(building.building_id)
	_sprite.sprite_frames = frames
	var stem := ContentLoader.stem_for_building_id(building.building_id)
	_sprite.modulate = BuildingVisualRegistry.get_dlc_tint(stem)
	position = map_view.grid_to_screen(building.position)
	_sync_animation()


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
