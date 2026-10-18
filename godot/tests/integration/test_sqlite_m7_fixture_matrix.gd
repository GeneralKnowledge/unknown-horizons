extends GutTest

## M7: T1k inventory totals at load for every tiered sqlite fixture in one gate test.

const M7_FIXTURE_PATHS := {
	"fire": "legacy/tests/game/fixtures/fire.sqlite",
	"settlement-range": "legacy/tests/game/fixtures/settlement-range.sqlite",
	"traderoute": "legacy/tests/game/fixtures/traderoute.sqlite",
	"savegame-rev-76": "legacy/tests/game/fixtures/savegame-rev-76.sqlite",
	"blackdeath": "legacy/tests/game/fixtures/blackdeath.sqlite",
	"plain": "legacy/tests/gui/ingame/fixtures/plain.sqlite",
}


func test_m7_tier_fixtures_inventory_totals_at_load() -> void:
	if OS.has_feature("web"):
		pending("desktop only")
		return
	for fixture_name in M7_FIXTURE_PATHS.keys():
		M7SaveTestHelpers.assert_inventory_totals_at_load(
			self, fixture_name, M7_FIXTURE_PATHS[fixture_name]
		)
