# Dolce's Adventure

**v1.0.0 Windows local release:** gameplay is owner-accepted, and implementation
and automated release checks pass on Godot 4.7.2. The package is prepared
locally; it has not been signed, tagged or published.

**v2 source development:** Daily UTC, Hills, two/three-human hot-seat turns,
an optional Chase camera and original background music are implemented.
The accepted v1 EXE/PCK/ZIP remain frozen; no v2 package or owner acceptance
is claimed.

An original side-scrolling platformer for a small dog with a big appetite,
played solo or in human hot-seat turns.
Run, jump, bonk pests and eat burgers through the Backyard, Park, Main Street,
Boardwalk Pier and Night Market.

This is a **Godot 4.7 game folder**, not a standalone Godot project. It lives at
`godot-base\games\dolces_adventure`; the DeskCanSaw host supplies the project,
menus, settings, pause, results, store, gallery, achievements and share cards.

## Playing

**Endless runs** assemble seeded, hand-authored chunks. Distance counts from
your chosen start point; later starts unlock through distance achievements.
The course seed appears in results so a run can be replayed.

**Daily UTC - Backyard** (v2 source) is always available in the same run
picker. Every attempt on one UTC date uses the same Backyard endless course,
with unlimited retries and separate daily bests. Your device's UTC clock
chooses the date; a started run keeps its date/seed through midnight. Play
Again on the next UTC date starts that day's course. Assists, achievements
and Treats work normally; there is no online leaderboard.

**Endless - Hills** (v2 source) starts in the Backyard and follows the same
five-biome schedule, with separate bests and authored, solid ramps. Dolce
walks up/down and jumps from them normally. Only this mode uses slopes:
ordinary Endless, Daily UTC and the fixed stages keep their existing courses.

**Five fixed stages**, one per biome, are roughly 300 m long. Reach the
food-truck goal to clear a stage and unlock the next. Clear time is the
headline; the clock uses model time, so the game-speed assist does not improve
a saved time.

**Two/three-human hot seat** works in every mode. Each seat gets a fresh body,
food and pests on the same seed/course; Daily UTC keeps one date for the whole
match, even across midnight. Release the controls before passing them on and
starting the next seat. Endless modes rank whole metres. On stages, a clear
beats a failure, fastest displayed tenth-second clear wins, and failed runs
compare metres. Headline ties share a place; score never breaks them. There
is no CPU opponent or split-screen.

Dolce starts with three hearts. Stomp pests from above, but jump over pointed
gnome hats and hot-sauce drops. Burgers score points; every hundredth restores
a heart. A Big Burger makes her Full, absorbing one pest hit. A Golden Bone
restores a heart. Pits cost a heart unless Kind pits protects a Full Dolce.
Losing the last heart ends the attempt.

Runs pay Treats for cosmetic collars, hats and bandanas: score / 100,
rounded to whole Treats, plus three for playing and twenty for a clear. A hot-seat match
pays once after its final turn, using the best score and one clear bonus if
anyone cleared. Every seat contributes its own achievements and bests.
Outfits appear in the run, setup preview, gallery and share portrait; share
data preserves what each completed turn actually wore.

## Controls and assists

| Action | Keyboard | Gamepad | Touch |
| --- | --- | --- | --- |
| Move | A / D, left / right arrows | Left stick / D-pad | Left / right icons |
| Jump | Space, up arrow | A | Hold Jump for height; tap for a hop |
| Sprint | Shift | X / right trigger | Tap Right, then tap again and hold |
| Pause | Escape | Start | Pause icon |

A, D, Space and Shift are rebindable in Settings. Arrows and gamepad controls
are fixed extras, approved for v1. Independent fingers can hold Right and Jump; lifting one
finger, canceling a gesture or opening pause cannot leave another action stuck.

On a touchscreen, a one-time **Auto-run** tip offers one-thumb play. Accepting
it enables the saved assist; **Not now** or starting to play dismisses it.
Auto-run stays off unless enabled, and Left then brakes to a walk.

Settings also offers **Kind pits**, **Game speed** (70-100%) and **Day / night
cycle**. Kind pits and Game speed apply to the next run/match; live Auto-run
changes apply to every hot-seat player. **Camera** switches between the
default **Side** view and an angled orthographic **Chase** view, without
changing movement, physics or the left boundary.

The original quiet melody/bass loop uses the shared **Music** and **Master**
volume/mute controls. It continues through pause, results and turn handoffs,
and stops when leaving gameplay. Assists never block achievements. Reduced
motion, intense-effects controls and audio captions use the host's
accessibility settings. Touch targets stay at least 44 physical pixels, with
room kept clear for the counters and active captions.

## Running in the host

From this game folder, in PowerShell:

```powershell
Set-Location ..\..
$godot = 'C:\path\to\Godot_v4.7-stable_win64.exe'
Start-Process -FilePath $godot -ArgumentList @(
    '--path', '.', '--', '--game=dolces_adventure'
) -Wait
```

Replace `$godot` with your executable. To replay an ordinary Endless or Hills
course, add `'--dolce-seed=42'` after the game argument. Daily UTC ignores that
override with a warning, so it cannot silently present a different course.

## Tests

Run suites **one at a time** from `godot-base`. A real run can write progress;
use an isolated profile even though the scene and view suites restore their
save snapshots. On Windows, set `APPDATA` before starting Godot; on Linux,
set `XDG_DATA_HOME`.

```powershell
$env:APPDATA = Join-Path $env:TEMP ('dolce-tests-' + [guid]::NewGuid())
$env:LOCALAPPDATA = $env:APPDATA
New-Item -ItemType Directory -Path $env:APPDATA | Out-Null
$tests = Get-ChildItem .\games\dolces_adventure\tests -Filter '*_test.gd' -File |
    Where-Object Name -ne 'dolce_view_test.gd' | Sort-Object Name
foreach ($test in $tests) {
    $process = Start-Process -FilePath $godot -ArgumentList @(
        '--headless', '--path', '.', '--script',
        "res://games/dolces_adventure/tests/$($test.Name)", '--', '--game=all'
    ) -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "$($test.Name) failed." }
}
```

There are fourteen game suites: thirteen headless and `dolce_view_test.gd`,
which needs a real window: omit `--headless`. It checks rendered visibility,
portrait/landscape phones,
tablet, ultrawide, large UI, long scores, Full, captions and airborne poses
in both cameras, plus Hills and the hot-seat handoff. The far bank of the
widest authored pit must draw visible pixels before take-off on small phones.
It can save screenshots with `--dolce-view-captures=<absolute directory>`.
Daily UTC's full date remains visible and readable at 14 physical pixels
on the smallest phone layouts, even when the short header hides its title.
Run the host's fifteen framework suites with `--game=all` before closing a
milestone. Exact suite commands are in [AGENTS.md](AGENTS.md).

The current regression pass used **Godot 4.7.2**: all fourteen game suites and
fifteen framework suites exited 0. Two host suites (`lives_mode_test` and
`single_game_test`) reported unrelated shared-UI and Chicken Pit audio
resources in use at shutdown.
The scene suite drives **all five full stages** through normal input actions,
with three hearts and no hits or pit recoveries, checking results, Treats,
saved clear times and sequential unlocks from fresh progression. Seed 42
also runs **2.25 km from Backyard into the Night Market**, collecting 148
burgers and stomping 27 pests without damage. Real input collisions then
end that run, checking all endless-start unlocks and its saved result.
The test-only player predicts on deep copies of the live physics, terrain
and pests; it cannot move the real body or consume its food during lookahead.
Its fixed seed is supplied to the normal round constructor, not by replacing
a live run. These helpers are excluded from exports; they are not a shipped
assist. Legacy jump tuning, courses and validator jump margins remain unchanged.

The v2 pass also drives Daily UTC through genuine deaths and same-day
**Play Again** retries, then **2,257 m** from Backyard into Market on
2026-11-01's seed **020758**, with Kind pits enabled. Advancing the injected
clock through UTC midnight cannot reseed/relabel the run, overwrite tomorrow's
best or change its share date. The actual results preserve the six populated v1
start/stage bests and pay the normal Treats rule. A real-window run confirms
that even `--dolce-seed=999999` cannot override the daily course.
Hills seed 42 reaches **2,461 m** across all five biomes, with **351 burgers**
and **36 stomps**, ending through real collisions. The hot-seat suite plays
three-player Daily UTC across midnight, two-player Hills and tied Stage 1
clears; it checks release gates, fresh retries, ranking, records, one payout
and per-turn outfits. The complete-scene suite also passes in a real window
with `--dolce-test-chase`, reproducing the same full-course results as Side.
Audio tests check the original loop's deterministic PCM, level and seam;
speaker/listening QA remains separate. New scripts pass format checks, with
no introduced lint diagnostics (26 existing diagnostics across the edited
scripts are unchanged).

## Release configuration

The frozen v1 release was built with the host's
**Windows - Dolce's Adventure (standalone)** preset for v1.0.0,
with the `dolces_adventure` feature tag and the approved permanent save
directory **`DeskCanSaw Games/Dolce's Adventure`**. It packages only this
game, excluding tests and development tools. Keep `DolcesAdventure.exe`
and `DolcesAdventure.pck` together in `build\dolces_adventure`.
The collection preset includes Dolce without changing its own save directory.
Source `--game=dolces_adventure` launches still use the host's development
profile; a command-line catalog selection is not a save-directory override.

The verified distribution is
`build\dolces_adventure\DolcesAdventure-v1.0.0-windows-x86_64.zip`
(about 46 MB). Extract both files together. Both native release EXEs booted
in real Windows graphics windows without errors; both exact release PCKs
passed headless and rendered checks for catalog contents, actual save paths,
branding/version, required media and gameplay. Standalone includes only Dolce,
with tests/tools excluded; collection retains all ten playable games.
The EXE is **unsigned**; signing, publication and commits are not performed
by these build checks. Commits/tags and host gitlink integration remain
owner-managed; this v2 source phase creates none.

Companion **`RELEASE-NOTES.txt`** and **`SHA256SUMS.txt`** sit beside the ZIP
in `build\dolces_adventure`. The checksums cover the ZIP and both extracted
files. The ZIP itself is unchanged: its two entries still match the verified
EXE/PCK byte-for-byte. The final standalone boot and exact-PCK checks pass
with isolated saves and correct native title/version, catalog and save path.

**Do not export current v2 source into the v1 release directory.** The
existing preset still targets v1's version/output. A future v2 distribution
needs its own version, output path and export QA; no v2 package is claimed
by the source regression pass.

## Art, saves and QA evidence

Models, scenery, synthesized cues and music are original and procedural.
The model is node-free at 120 Hz; the 3D view cannot change physics. New chunks must pass
the fairness validator, not loosen it.

Best distance, score and burger totals live in `user://dolces_adventure.cfg`,
with the best `time_ms` per stage and a separate `[hills]` section. Daily UTC
uses `[daily_YYYY-MM-DD]` sections; historical dates and v1 sections are preserved.
Records merge and never regress. The host
stores outfits, achievements and settings separately; the touch-tip flag is
in `settings.cfg`, not an extra Settings option.

After changing biome art or gates, rerun `tools\capture_art.gd`;
`--only=hills` refreshes just the new Hills selector still. After changing
Stage 1, the HUD or tutorial captions, run the host's recorder:

```powershell
.\tools\record_tutorials.ps1 -Godot $godot -Games dolces_adventure -Variants solo -Quality 6
```

The walkthrough is a real 27-second Stage 1 run, with a poster at six seconds.
See [DESIGN.md](DESIGN.md) for the rules and [TODO.md](TODO.md) for progress.
The owner approved the current procedural art for v1; reference photos are
optional later work. On **2026-11-01**, the owner accepted gameplay:
"It plays nicely and all is good", then approved local v1 release finalization.
A detailed human full-course, physical-device or speaker test matrix was not
supplied; the acceptance and automated checks do not claim those measurements.