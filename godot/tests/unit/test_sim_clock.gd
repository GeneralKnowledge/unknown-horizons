extends GutTest


func test_sim_clock_runs_expected_ticks() -> void:
	var session := GameSession.settle().session
	var clock := SimClock.new()
	var step := 1.0 / float(GameTimer.TICKS_PER_SECOND)
	var start_tick := session.scheduler.cur_tick
	var ran := clock.accumulate_and_run(session, step * 3.5)
	assert_eq(3, ran)
	assert_eq(start_tick + 3, session.scheduler.cur_tick)
