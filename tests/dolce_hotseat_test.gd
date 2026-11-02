extends "res://games/dolces_adventure/tests/dolce_scene_test.gd"

## Uses the scene suite's input-only driver and save restoration. No turn is
## ended by editing its body, hearts, clock or course.

const Standings = preload("res://games/dolces_adventure/run_standings.gd")


func _run() -> void:
	_snapshot()
	GameCatalog.select(Options.GAME_ID)
	_test_ranking()
	if _fresh_progress():
		await _test_shared_match(Options.DAILY, 3)
		await _test_shared_match(Options.HILLS, 2)
		await _test_stage_match()
	await _play(0.1)
	get_root().get_node("GameSession").call("configure_single_player")
	_restore()
	_finish()


func _test_ranking() -> void:
	var a := State.new()
	var b := State.new()
	var c := State.new()
	a.furthest_x = 200.9 * Grid.TILE
	b.furthest_x = 200.1 * Grid.TILE
	b.item_points = 99999
	c.furthest_x = 201.0 * Grid.TILE
	var runs: Array[State] = [a, b, c]
	_expect(
		(
			Standings.order(runs, false) == [2, 0, 1]
			and Standings.place(runs, 0, false) == 2
			and Standings.place(runs, 1, false) == 2
		),
		"Whole metres rank endless runs; hidden fractions and food scores cannot break a tie."
	)
	a.cleared = true
	a.clear_time = 40.01
	b.cleared = true
	b.clear_time = 40.04
	_expect(
		Standings.order(runs, true) == [0, 1, 2] and Standings.same(a, b, true),
		"A clear beats a longer failure; equal displayed tenths tie."
	)
	b.clear_time = 39.9
	_expect(Standings.order(runs, true) == [1, 0, 2], "The fastest clear ranks first.")
	a.cleared = false
	b.cleared = false
	_expect(
		Standings.order(runs, true) == [2, 0, 1],
		"Failed stages compare distance, not time or score."
	)


func _test_shared_match(level_id: String, players: int) -> void:
	var session := get_root().get_node("GameSession")
	var store := get_root().get_node("Store")
	session.call("configure_multiplayer", 0, 1, players)
	session.call("set_level", level_id)
	var game := await _open()
	game.set_process(false)
	game.call("_update_round", 0.0, 0.0)
	var runs: Array = game.get("_runs")
	var streams: Array = game.get("_streams")
	var opening: Array = streams[0].placed.duplicate(true)
	var daily := level_id == Options.DAILY
	var date: String = game.get("_daily").utc_date if daily else ""
	var seed: int = game.get("_seed")
	var before := int(store.call("points", Options.GAME_ID))
	var music: AudioStream = game.get("music")
	for player in players:
		_expect(
			(
				runs[player].hearts == 3
				and runs[player].elapsed == 0.0
				and streams[player].placed == opening
				and streams[player].run_seed == seed
			),
			"Every seat begins fresh on the captured course (%d)." % (player + 1)
		)
		_expect(
			game.get("_state") == runs[player] and game.get("_active_player") == player,
			"The live model belongs to the current seat."
		)
		_expect(
			game.call("_controller_device") == session.call("controller_device_for_player", 0),
			"A seat without its own pad can use the shared first pad or keyboard."
		)
		await _drive(game, false, true)
		if player == players - 1:
			break
		_expect(
			(
				not (game.get_node("%RoundOver") as Control).visible
				and int(store.call("points", Options.GAME_ID)) == before
			),
			"An intermediate turn does not settle shell results or pay the wallet."
		)
		var elapsed: float = runs[player].elapsed
		game.call("_update_round", 5.0, 0.0)
		_expect(runs[player].elapsed == elapsed, "The handoff cannot advance the old body.")
		var handoff: Control = game.get("_handoff")
		Input.action_press(Options.JUMP)
		game.call("_process", 0.0)
		game.call("_start_next_turn")
		_expect(
			handoff.visible and handoff.get("button").disabled,
			"A held Jump cannot accept a handoff or start the next turn."
		)
		Input.action_release(Options.JUMP)
		game.call("_process", 0.0)
		game.set(
			"test_unix_time", int(Time.get_unix_time_from_datetime_string("2026-11-02T00:00:01"))
		)
		game.call("_start_next_turn")
		Input.action_press(Options.JUMP)
		game.call("_update_round", 1.0, 0.0)
		_expect(
			runs[player + 1].elapsed == 0.0 and game.get("_wait_for_release"),
			"The new body waits again if a Start press also holds a gameplay key."
		)
		Input.action_release(Options.JUMP)
		game.call("_update_round", 0.0, 0.0)
		_expect(
			(
				game.get("_seed") == seed
				and (game.get("_daily").utc_date == date if daily else game.get("_stream").hills)
			),
			"Handoffs cannot change the captured course or daily date."
		)
		_expect(
			(
				game.get("music") == music
				and bool(get_root().get_node("AudioManager").call("is_music_playing"))
			),
			"Turn boundaries keep one existing music loop."
		)
	_expect(
		(game.get_node("%RoundOver") as Control).visible,
		"The final turn opens normal shell results."
	)
	var best := 0
	var burgers := 0
	for player in runs.size():
		best = maxi(best, runs[player].score())
		burgers += runs[player].burgers
		var stats: Dictionary = game.call("_player_stats", player)
		_expect(
			stats["hits"] == runs[player].burgers and stats["score"] == runs[player].score(),
			"Each result card uses its own body, not the last seat's."
		)
	_expect(
		int(store.call("points", Options.GAME_ID)) - before == roundi(best * 0.01) + 3,
		"Hot-seat turns pay the shared best-score payout exactly once."
	)
	_expect(
		int(game.call("_round_totals")["hits"]) == burgers, "Match food totals include all seats."
	)
	var payload: Dictionary = game.call("_share_payload")
	_expect(
		(
			payload["players"].size() == players
			and payload["course_seed"] == seed
			and payload["standings"] == range(players)
			and (payload["daily_date"] == date if daily else payload["level_id"] == Options.HILLS)
		),
		"The share payload retains all tied seats and the captured course identity."
	)
	var record := Records.new().best("daily_" + date if daily else level_id)
	_expect(record["score"] == best, "All turns merge into the selected course's bests.")
	game.call("_update_round", 1.0, 0.0)
	_expect(
		int(store.call("points", Options.GAME_ID)) - before == roundi(best * 0.01) + 3,
		"Later frames cannot settle the match or pay it again."
	)
	game.call("_on_play_again_pressed")
	_expect(
		(
			game.get("_active_player") == 0
			and not game.get("_handoff").visible
			and game.get("_runs").size() == players
			and (
				game.get("_daily").utc_date == "2026-11-02" if daily else game.get("_stream").hills
			)
		),
		"Play Again restarts all seats and recaptures the course/date."
	)
	for run: State in game.get("_runs"):
		_expect(
			run.elapsed == 0.0 and run.hearts == 3 and run.burgers == 0,
			"A rematch has no previous turn state."
		)
	game.queue_free()
	await process_frame
	_expect(
		not bool(get_root().get_node("AudioManager").call("is_music_playing")),
		"Leaving gameplay stops the music loop."
	)


func _test_stage_match() -> void:
	var session := get_root().get_node("GameSession")
	var store := get_root().get_node("Store")
	session.call("configure_multiplayer", 0, 1, 2)
	session.call("set_level", Options.STAGE_BACKYARD)
	var game := await _open()
	game.set_process(false)
	game.call("_update_round", 0.0, 0.0)
	var before := int(store.call("points", Options.GAME_ID))
	await _drive(game)
	_expect(
		(
			not (game.get_node("%RoundOver") as Control).visible
			and not get_root().get_node("AchievementManager").call(
				"is_unlocked", Options.CLEARED_BACKYARD
			)
		),
		"The first clear waits for the second seat before settling progression."
	)
	game.call("_process", 0.0)
	game.call("_start_next_turn")
	game.call("_update_round", 0.0, 0.0)
	var second_outfit: Array[String] = [Options.COLLAR_BLUE, Options.HAT_PARTY, ""]
	game.set("_outfit", second_outfit)
	game.call("_dress")
	await _drive(game)
	var runs: Array = game.get("_runs")
	_expect(
		runs[0].cleared and runs[1].cleared and runs[0].clear_time == runs[1].clear_time,
		"Normal identical input on the shared stage clears in the same model time."
	)
	_expect(
		game.get("_result_label").text == "SHARED FIRST PLACE",
		"Equal stage clears share first rather than comparing hidden score or seat order."
	)
	var earned := (
		roundi(maxi(runs[0].score(), runs[1].score()) * 0.01) + 3 + Options.TREATS_PER_CLEAR
	)
	_expect(
		int(store.call("points", Options.GAME_ID)) - before == earned,
		"A stage match pays once, including only one clear bonus."
	)
	_expect(
		get_root().get_node("AchievementManager").call("is_unlocked", Options.CLEARED_BACKYARD),
		"The match awards the real stage-clear achievement."
	)
	var record := Records.new().best(Options.STAGE_BACKYARD)
	_expect(
		record["time_ms"] == roundi(runs[0].clear_time * 1000.0),
		"Shared-place precision does not reduce the saved personal-best precision."
	)
	var after_match: Array[String] = [Options.COLLAR_RED, Options.HAT_FLOWERS, ""]
	game.set("_outfit", after_match)
	game.call("_dress")
	var payload: Dictionary = game.call("_share_payload")
	_expect(
		(
			payload["outfit"] == payload["players"][0]["outfit"]
			and payload["players"][1]["outfit"] == second_outfit
			and payload["players"][0]["outfit"] != second_outfit
		),
		"Wardrobe changes preserve both the leading portrait and every completed turn's outfit."
	)
	game.queue_free()
	await process_frame
