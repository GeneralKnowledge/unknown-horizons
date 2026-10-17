extends Node

## Minimal ambient playback for exported legacy OGGs (view layer only).

const MANIFEST_PATH := "res://resources/audio/exported/manifest.json"
const BUS_AMBIENT := "Ambient"

var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_ensure_ambient_bus()


func _ensure_ambient_bus() -> void:
	if AudioServer.get_bus_index(BUS_AMBIENT) >= 0:
		return
	AudioServer.add_bus(1)
	AudioServer.set_bus_name(1, BUS_AMBIENT)
	AudioServer.set_bus_send(1, &"Master")


func play_ambient_res(res_path: String, volume_db: float = 0.0) -> bool:
	if res_path.is_empty() or not ResourceLoader.exists(res_path):
		push_warning("GameAudioService: missing audio %s" % res_path)
		return false
	var stream: Variant = load(res_path)
	if stream == null or not (stream is AudioStream):
		push_warning("GameAudioService: not an AudioStream %s" % res_path)
		return false
	var player := AudioStreamPlayer.new()
	player.bus = BUS_AMBIENT
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	_players.append(player)
	player.finished.connect(func(): _players.erase(player))
	player.play()
	return true


func play_exported_legacy_key(manifest_key: String) -> bool:
	var pack_res := ContentTheme.legacy_audio_res_for_key(manifest_key)
	if not pack_res.is_empty():
		return play_ambient_res(pack_res)
	if not FileAccess.file_exists(MANIFEST_PATH):
		return false
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if typeof(manifest) != TYPE_DICTIONARY:
		return false
	var files: Dictionary = manifest.get("files", {})
	if not files.has(manifest_key):
		return false
	return play_ambient_res(str(files[manifest_key]))
