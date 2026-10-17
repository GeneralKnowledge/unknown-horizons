extends GutTest


func test_ambient_bus_exists_after_ready() -> void:
	var svc := GameAudioService
	assert_gte(AudioServer.get_bus_index("Ambient"), 0)


func test_play_missing_asset_does_not_crash() -> void:
	var ok := GameAudioService.play_ambient_res("res://resources/audio/exported/does_not_exist.ogg")
	assert_false(ok)


func test_play_exported_manifest_entry_if_present() -> void:
	if not FileAccess.file_exists("res://resources/audio/exported/manifest.json"):
		pending("run export_audio.py")
		return
	var ok := GameAudioService.play_exported_legacy_key("content/audio/sounds/lumberjack.ogg")
	assert_true(ok)
