# v1.9.0 Release — Handoff

All code is committed and pushed to `master` (tip: `7a7bf6f`). What's left can
only be done from a machine with a full dev environment (Flutter SDK, and
unrestricted git — this sandbox's proxy blocks tag pushes). Run these steps in
Claude Code locally.

## Why this is left to do

- **No Flutter/Dart SDK in the sandbox** — the Flutter port
  (`flutter_app/`) was written by mirroring existing code patterns exactly,
  but was never compiled or run. It needs `flutter analyze` and a real build
  before it ships.
- **Tag pushes are blocked by the sandbox's git proxy** (403, org egress
  policy) — branch pushes work, tag pushes don't.
- **Releases in this repo are built manually**, not via CI (`gh api
  repos/mayJag/ChronoRep/actions/workflows` returns zero workflows) — there's
  no pipeline to trigger instead.

## Steps

### 1. Sync and sanity-check

```bash
git fetch origin
git checkout master
git pull
git log -1 --oneline   # should show 7a7bf6f as the tip (or later)
```

### 2. Flutter: analyze and build

```bash
cd flutter_app
flutter pub get
flutter analyze
```

Fix anything `analyze` flags — the new files (`lib/data/exercise_library.dart`,
`lib/data/substitutions.dart`) and the edited
`lib/screens/exercise_library_screen.dart` /
`lib/screens/active_workout_screen.dart` are the highest-risk spots since they
were never compiled. I bracket-balance-checked them but that's not a
substitute for `flutter analyze`.

```bash
flutter build apk --release
```

Confirm the app actually runs: exercise library screen loads and filters
(muscle + equipment chips), tapping an exercise shows the instructions sheet,
and the swap icon in the active workout screen brings up substitute options
and swaps correctly.

Output APK: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`

### 3. Web app: optional re-verify

Already build/lint verified and browser-tested in the sandbox, but if you want
to double check after pulling:

```bash
npm install
npm run lint
npm run build
```

### 4. Tag and push

The commit is already the intended release point (`7a7bf6f`). Tag it:

```bash
git tag -a v1.9.0 -m "ChronoRep v1.9.0 — full exercise library, instructions, and exercise substitutions"
git push origin v1.9.0
```

### 5. Create the GitHub Release

Create a release for tag `v1.9.0`, attach the APK from step 2, and use these
notes (adjust as you like):

---

**Version 1.9.0 — Full Exercise Library & Smart Substitutions**

**1,300+ exercise library** — the catalogue jumps from ~50 curated staples to
over 1,300 movements, each with target and secondary muscles and
step-by-step instructions. Browse and filter by muscle group and equipment;
tap any exercise for its full instructions.

**Exercise swaps** — every exercise in an active workout now has a swap
button. Tap it for a ranked list of alternatives that hit the same muscles
with whatever equipment you have — works for generated plans and every
imported program (Powerbuilding included).

*Note: exercise data from the open [exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset);
GIF/thumbnail media excluded (© Gym visual, separate license required).*

*Installs over v1.8.0 — all logged workouts, plans, and goals carry over.*

---

## What's in this release (for context)

Commits `7533abc` → `7a7bf6f` on `master`:

- `scripts/import_exercises_dataset.mjs` — converts the exercises-dataset into
  `src/data/exerciseLibrary.json` / `flutter_app/assets/data/exercise_library.json`
  (name/muscle-group/equipment/category/target/secondary-muscles/instructions;
  no media).
- `src/lib/substitutions.js` / `flutter_app/lib/data/substitutions.dart` —
  substitution engine (target-muscle match, secondary-muscle overlap,
  category, equipment), wired into ActiveWorkout / PlanBuilder (web) and the
  Active Workout screen (Flutter) via a swap button.
- `src/lib/muscleStandards.js` — NSCA/ACSM per-muscle weekly-set ranges,
  replacing the old flat cap in `planGenerator.js`; shown in the Goals page
  volume panel. (Flutter's plan generator already had per-muscle standards
  since v1.6.0 — not touched.)
- Exercise Library page/screen — filters, pagination (web), detail
  view/sheet with instructions.
- **Regression fix**: the auto plan-generator and Quick Workout generator
  were initially drawing from the full 1,300-exercise pool, producing
  obscure picks instead of proven staples. Both now filter to curated
  exercises + user custom exercises only; the dataset still powers the
  library browser and substitution engine.
- Removed the old, broken, unused `exerciseSubstitutions` static map in
  `expertPowerbuilding.js` (superseded by the live engine).
- Version bumped: `package.json` → 1.9.0, `flutter_app/pubspec.yaml` →
  1.9.0+10 (aligned to the project's actual release-tag cadence, which was
  already at v1.8.0 — not the stale 1.5.0 baseline package.json had drifted
  to).

## Known gaps / deliberately out of scope

- **Media (GIFs/thumbnails)** from exercises-dataset is not bundled — it's
  © Gym visual and requires a separate license from gymvisual.com. Only the
  MIT-licensed non-media fields were imported.
- **Non-English instructions** (the dataset has es/it/tr/ru/zh) were not
  imported — English only, to keep scope reasonable.
- A handful of legacy program exercise names have no dataset match (e.g.
  "Nordic Ham Curl", "Lateral Band Walk") — swap will show "no close
  matches" for those rather than guessing wrong.
