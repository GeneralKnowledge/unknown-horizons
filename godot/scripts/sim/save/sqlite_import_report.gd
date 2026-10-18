class_name SqliteImportReport
extends RefCounted

## Diagnostics for partial legacy SQLite import (desktop).

var source_path: String = ""
var map_id: String = ""
var savegamerev: int = -1
var partial: bool = true

var buildings_extracted: int = 0
var buildings_total_in_save: int = -1
var buildings_truncated: bool = false
var buildings_placed: int = 0
var buildings_rejected: int = 0
var rejection_counts: Dictionary = {} # reason -> count

var storage_rows_total: int = 0
var storage_rows_applied: int = 0
var storage_rows_skipped: int = 0
var settlement_storage_rows_applied: int = 0

var unit_rows_total: int = 0
var wild_animals_spawned: int = 0
var collector_rows_in_save: int = 0
var collectors_skipped_yaml_duplicate: int = 0
var collectors_unsupported: int = 0
var collectors_restored: int = 0
var collectors_save_homes: int = 0
var collectors_unsupported_no_collecting_yaml: int = 0

var production_rows_total: int = 0
var production_rows_applied: int = 0
var production_rows_skipped: int = 0


func record_rejection(reason: String) -> void:
	buildings_rejected += 1
	rejection_counts[reason] = int(rejection_counts.get(reason, 0)) + 1


func to_dictionary() -> Dictionary:
	return {
		"source_path": source_path,
		"map_id": map_id,
		"savegamerev": savegamerev,
		"partial": partial,
		"buildings_extracted": buildings_extracted,
		"buildings_total_in_save": buildings_total_in_save,
		"buildings_truncated": buildings_truncated,
		"buildings_placed": buildings_placed,
		"buildings_rejected": buildings_rejected,
		"rejection_counts": rejection_counts.duplicate(),
		"storage_rows_total": storage_rows_total,
		"storage_rows_applied": storage_rows_applied,
		"storage_rows_skipped": storage_rows_skipped,
		"settlement_storage_rows_applied": settlement_storage_rows_applied,
		"unit_rows_total": unit_rows_total,
		"wild_animals_spawned": wild_animals_spawned,
		"collector_rows_in_save": collector_rows_in_save,
		"collectors_skipped_yaml_duplicate": collectors_skipped_yaml_duplicate,
		"collectors_unsupported": collectors_unsupported,
		"collectors_restored": collectors_restored,
		"collectors_save_homes": collectors_save_homes,
		"collectors_unsupported_no_collecting_yaml": collectors_unsupported_no_collecting_yaml,
		"production_rows_total": production_rows_total,
		"production_rows_applied": production_rows_applied,
		"production_rows_skipped": production_rows_skipped,
	}


static func from_dictionary(data: Dictionary) -> SqliteImportReport:
	var r := SqliteImportReport.new()
	r.source_path = str(data.get("source_path", ""))
	r.map_id = str(data.get("map_id", ""))
	r.savegamerev = int(data.get("savegamerev", -1))
	r.partial = bool(data.get("partial", true))
	r.buildings_extracted = int(data.get("buildings_extracted", 0))
	r.buildings_total_in_save = int(data.get("buildings_total_in_save", -1))
	r.buildings_truncated = bool(data.get("buildings_truncated", false))
	r.buildings_placed = int(data.get("buildings_placed", 0))
	r.buildings_rejected = int(data.get("buildings_rejected", 0))
	r.rejection_counts = data.get("rejection_counts", {}).duplicate()
	r.storage_rows_total = int(data.get("storage_rows_total", 0))
	r.storage_rows_applied = int(data.get("storage_rows_applied", 0))
	r.storage_rows_skipped = int(data.get("storage_rows_skipped", 0))
	r.settlement_storage_rows_applied = int(data.get("settlement_storage_rows_applied", 0))
	r.unit_rows_total = int(data.get("unit_rows_total", 0))
	r.wild_animals_spawned = int(data.get("wild_animals_spawned", 0))
	r.collector_rows_in_save = int(data.get("collector_rows_in_save", 0))
	r.collectors_skipped_yaml_duplicate = int(data.get("collectors_skipped_yaml_duplicate", 0))
	r.collectors_unsupported = int(data.get("collectors_unsupported", 0))
	r.collectors_restored = int(data.get("collectors_restored", 0))
	r.collectors_save_homes = int(data.get("collectors_save_homes", 0))
	r.collectors_unsupported_no_collecting_yaml = int(
		data.get("collectors_unsupported_no_collecting_yaml", 0)
	)
	r.production_rows_total = int(data.get("production_rows_total", 0))
	r.production_rows_applied = int(data.get("production_rows_applied", 0))
	r.production_rows_skipped = int(data.get("production_rows_skipped", 0))
	return r
