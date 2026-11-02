extends RefCounted

## Headline precision decides ties, so a hidden fraction cannot beat an equal
## distance or clear time on the results card. Scores remain separate.

const State = preload("res://games/dolces_adventure/run_state.gd")


static func before(a: State, b: State, stage: bool) -> bool:
	if stage and a.cleared != b.cleared:
		return a.cleared
	if stage and a.cleared:
		return roundi(a.clear_time * 10.0) < roundi(b.clear_time * 10.0)
	return floori(a.distance_m()) > floori(b.distance_m())


static func same(a: State, b: State, stage: bool) -> bool:
	return not before(a, b, stage) and not before(b, a, stage)


static func order(runs: Array[State], stage: bool) -> Array[int]:
	var seats: Array[int] = []
	seats.assign(range(runs.size()))
	seats.sort_custom(
		func(a: int, b: int) -> bool:
			return a < b if same(runs[a], runs[b], stage) else before(runs[a], runs[b], stage)
	)
	return seats


static func place(runs: Array[State], player: int, stage: bool) -> int:
	var rank := 1
	for run in runs:
		rank += int(before(run, runs[player], stage))
	return rank
