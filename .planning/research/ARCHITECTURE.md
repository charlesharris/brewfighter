# Architecture Research

**Domain:** 2D collectible-brewing JRPG / tactical-encounter game on DragonRuby GTK (mruby)
**Project:** Brew Fighter
**Researched:** 2026-10-06
**Confidence:** MEDIUM-HIGH overall. HIGH on every DragonRuby API/behavior claim (read first-hand from the shipped docs and OSS runtime source of engine build `0d709c3`, v7.18, 2026-09-11, plus the sibling MechTech repo's hard-won learnings). MEDIUM on the genre-level structural patterns (well established, but they are applied here by synthesis, not copied from a DragonRuby precedent; none exists for this genre). LOW on items explicitly tagged `[VERIFY]` — these need a spike before a phase depends on them.

> **Source note.** `docs.dragonruby.org` serves a JS shell that does not render via fetch (same failure the sibling MechTech research hit). All engine facts below come from the local unpacked distribution at `/Users/charris/src/mechtech/dragonruby-macos/` (`docs/api/*.md`, `docs/oss/dragon/*.rb`, `samples/`, `CHANGELOG-CURR.txt`). Brew Fighter needs **its own** unpacked engine copy (engine docs: "unzip a clean copy for every game"; file IO is sandboxed relative to the binary).

---

## Executive Position (the opinionated version)

1. **Three kinds of data, never mixed.** (a) **Defs**: immutable authored content (hops, yeasts, patrons, statuses, locations) loaded at boot. (b) **Profile**: the player's persistent, saved state — pure primitives (Hash/Array/Symbol/Integer/Float/String/true/false/nil), referencing Defs **by id only**. (c) **Session**: transient runtime state (scene stack, in-flight encounter, cursor positions, animations) — never saved. Everything else in this document follows from keeping these three apart.
2. **The game's rules live in a pure domain layer with no `args` in sight.** Brewing, palate scoring, status effects, clue reveal, lineage, collection progression are plain modules over plain hashes: `(inputs) -> (new_state, events)`. They are unit-testable under `./dragonruby --test` with no window, and a headless **balance harness** can run every patron against every beer. This is the single biggest quality lever for a game whose entire value is "the matchup puzzle is genuinely good".
3. **Scenes are thin.** A scene reads an `Intent` (normalized input), calls the domain, plays back the returned **event log** as animation/dialogue, and renders. It owns no rules. (This is the Pokémon-Showdown shape: simulator emits an ordered event stream, presentation plays it back.)
4. **Explainability is an architecture requirement, not a UI nicety.** Design success criterion #2 ("players understand why one beer succeeds and another fails") means the brewing engine and scoring engine must return **ledgers** (per-source contributions) as a first-class output, not just final numbers. Retrofitting explanation onto a sum is a rewrite.
5. **Hidden information is enforced by a type boundary.** The UI can only ever receive a `PatronView` (what the player has learned), never the patron Def's true palate.
6. **Save from day one, in a boring versioned envelope.** Ids not references, plain data only, `save_version` + migrations, safe parse (no `eval` of disk text — see Save section).

---

## Standard Architecture

### System Overview

```
┌────────────────────────────────────────────────────────────────────────────┐
│ L4  PRESENTATION   (reads state, writes only args.outputs / audio)          │
│  Scenes (title, world map, location, brewing, tap lineup, encounter,       │
│  collection browsers, regulars book, settings)                              │
│  UI kit: Layout · widgets (List, Grid, Panel, Meter, Dialogue, Tooltip,    │
│  AttributeView, BeerGlass, TreeView) · Focus nav · Theme · Text            │
│  Event playback (encounter log -> timed animation / barks / SFX)            │
├────────────────────────────────────────────────────────────────────────────┤
│ L3  FLOW           (the only layer that knows about Intent + scenes)        │
│  SceneStack · Game (root: owns profile/session/scenes) · Autosave policy    │
│  Domain-event queue consumer wiring                                         │
├────────────────────────────────────────────────────────────────────────────┤
│ L2  DOMAIN         (PURE: no args, no outputs, no globals, no rand)         │
│  Brewing sim · Recipes+Lineage · Beers · YeastBank · Palate scoring ·      │
│  Statuses/Modifiers · Encounter state machine · Clues+Knowledge ·          │
│  Bosses (rule overrides) · Codex · Regulars · Perks · Progression/Unlocks · │
│  World/Location rules · Rng (seedable)                                      │
├────────────────────────────────────────────────────────────────────────────┤
│ L1  DATA                                                                    │
│  Defs registry (static content + boot validation) · Tuning (one file) ·    │
│  Profile schema (new_game, shape) · Save (envelope, migrations, IO)         │
├────────────────────────────────────────────────────────────────────────────┤
│ L0  PLATFORM SHELL (the ONLY code touching args.inputs / DR.* IO)           │
│  main.rb (boot/tick/reset) · Input -> Intent · Assets/Paths · Audio ·      │
│  Screen constants · Log · Dev tools (HUD, scene jumper, cheats)             │
└────────────────────────────────────────────────────────────────────────────┘
  Dependency rule: a layer may call only layers BELOW it. L2 never calls L3/L4.
  Exception: L4 reads L2 pure functions for display math (e.g. preview scoring).
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `main.rb` | Engine entry points only: `boot`, `tick`, `reset`. Delegates to `$game`. | Top-level functions (proven in sibling MechTech), `$game ||= Game.new; $game.args = args; $game.tick` |
| `Game` | Root owner of `@profile`, `@session`, `@scenes`. Runs one frame: input -> update top scene -> drain events -> render stack -> autosave check. | One `attr_dr` class instance in `$game` (engine docs: iVars+classes are the "long-term maintainable" option; `args.state` is for prototyping) |
| `Input` | Converts raw keyboard/mouse/controller into a per-frame `Intent` hash. The only reader of `args.inputs`. | Stateless module, `Input.frame(args) -> Intent` |
| `SceneStack` | Push/pop/replace, lifecycle (`enter/pause/resume/exit`), overlay rendering order, transitions. | Array of `{type:, s:{}}` hashes + a registry of stateless scene modules |
| `Scenes::*` | One screen's flow. Reads Intent, calls domain, renders. No rules. | Modules with `enter(params)`, `update(s, ctx)`, `render(s, ctx)` |
| `UI::*` | Reusable widgets and layout; produce primitives + hit rects; own focus navigation. | Stateless helpers over `Layout`, `Geometry.rect_navigate` |
| `Defs` | Static content registry; id lookup; boot-time validation of every cross-reference. | `Defs.register(:hop, :citra, {...})`, `Defs.get(:hop, :citra)`, `Defs.validate!` |
| `Tuning` | All balance numbers: attribute curves, scoring weights, status magnitudes. | One file, nested modules, **permanently one file** (sibling lesson: hot reload re-executes only the saved file) |
| `Brewing` | Recipe + yeast instance + Defs -> `Beer` (attributes + ledger + derived stats). | Pure staged pipeline: mash -> boil -> ferment -> condition -> finalize |
| `Recipes` / `Lineage` | Immutable recipe versions, parent links, diff, family-tree queries. | Flat hash `id -> node` with `parent_id`; children index derived |
| `Palate` | `(beer, patron palate, statuses, context) -> {total, components[]}`. | Pure function; components array is the feedback/clue source |
| `Statuses` | Status Defs as declarative modifier rules + duration/decay; apply/tick/expire. | Data rules + one evaluator |
| `Encounter` | The pour-by-pour state machine; returns `(state, events)`. | Pure; no timing, no rendering |
| `Knowledge` / `Clues` | What the player has learned about each patron; clue selection policy; `PatronView`. | Profile-persisted `revealed` facts + pure view builder |
| `Codex` | Unified discovery state (`unseen/seen/owned/mastered`) for every collectible kind. | One table in Profile, kind-adapters for UI |
| `Regulars` / `Perks` | Seen->Served->Impressed->Regular->Friend derivation; passive benefits as data effects. | Derived from per-patron stats + thresholds in Defs; `Perks.query(profile, :key)` |
| `Progression` | Consumes domain events; grants Codex discoveries, unlocks, rewards, tutorial triggers. | Event-queue consumer |
| `Save` | Versioned envelope, migrations, slots, safe IO, backup. | Own serializer + `DR.write_save_data`/`read_save_data` |
| `Assets` / `Paths` | Logical id -> file; missing-asset fallback; sprite/audio registries. | Sibling-proven `Paths` + JSON index; `Assets.sprite(kind, id)` |
| `Rng` | Seedable, serializable PRNG for mutation, drops, name generation. | ~20-line own LCG/xorshift whose state lives in Profile |

### Recommended Project Structure

Repo layout follows the sibling MechTech convention (proven by running): game source at repo-root `mygame/`, engine unpacked beside it (gitignored while the repo is private-and-small, or committed per engine guidance for "shelf life" — a roadmap-level decision; the engine license forbids redistributing the engine in a public repo), launched by a `./run` script that `cd`s into the engine dir and passes `./mygame`.

```
brewfighter/
├── run  test                         # wrapper scripts; `test` OWNS its exit code (engine --test always exits 0)
├── tools/                            # asset generation/post-processing, content lint, balance-harness runner
├── dragonruby-macos/                 # engine (own copy). mygame -> ../mygame symlink
└── mygame/
    ├── app/
    │   ├── main.rb                   # boot / tick / reset ONLY
    │   ├── boot.rb                   # THE ordered require list (adding a file = one line here)
    │   ├── core/                     # paths, screen, log, ids, rng, tuning.rb (single file), events
    │   ├── content/                  # Defs registry + one file per category (see Content section)
    │   │   ├── defs.rb  validate.rb
    │   │   ├── attributes.rb         # canonical ordered attribute list + display metadata
    │   │   ├── hops.rb grains.rb adjuncts.rb yeasts.rb techniques.rb
    │   │   ├── styles.rb statuses.rb traits.rb abilities.rb
    │   │   ├── patrons/*.rb          # one file per patron or small group
    │   │   └── locations.rb bosses.rb perks.rb
    │   ├── domain/                   # PURE. Grep for `args`/`outputs`/`inputs` here must return nothing.
    │   │   ├── vec.rb                # attribute-vector math (add/scale/clamp/dist)
    │   │   ├── brewing/              # mash.rb boil.rb ferment.rb condition.rb rules.rb simulate.rb
    │   │   ├── recipes.rb lineage.rb beers.rb yeast_bank.rb
    │   │   ├── palate.rb statuses.rb encounter.rb clues.rb knowledge.rb bosses.rb
    │   │   ├── codex.rb regulars.rb perks.rb progression.rb world.rb
    │   ├── state/                    # profile.rb (new_game + shape), session.rb, save.rb, migrations.rb, settings.rb
    │   ├── platform/                 # input.rb, audio.rb, assets.rb
    │   ├── ui/                       # theme.rb text.rb focus.rb + widgets/*.rb (attribute_view, beer_glass, list, grid, ...)
    │   ├── scenes/                   # scene_stack.rb + one file per scene
    │   ├── game.rb                   # Game root
    │   └── dev/                      # debug HUD, scene jumper, give-item cheats, fixture loaders
    ├── data/                         # runtime-read: paths.json, text corpora (dialogue/barks) as JSON
    ├── sprites/                      # portraits/ beers/ ingredients/ locations/ ui/ _missing.png
    ├── sounds/
    ├── metadata/game_metadata.txt
    └── tests/                        # test_*(args, assert): domain, golden brews, balance harness, save round-trip
```

### Structure Rationale

- **`domain/` is import-clean of the engine.** This is what makes `--test` and the balance harness possible, and it mirrors the sibling's rule ("Input and Camera are the ONLY files touching engine objects"). Enforce with a grep test.
- **`content/` separate from `domain/`.** Authoring a patron or hop must never require touching rule code; rules never contain content literals.
- **One ordered require list (`boot.rb`).** DragonRuby's `require` is not CRuby's: paths are relative to `mygame/`, order is explicit, nothing auto-resolves (`docs/oss/dragon/runtime/require.rb`).
- **`tuning.rb` stays one file.** Hot reload re-executes only the saved file; derived constants split across files go stale silently.

---

## Data Model: The Three Tiers

```
DEFS (static, boot-loaded, immutable)        PROFILE (saved, pure primitives)          SESSION (transient)
─────────────────────────────────────        ───────────────────────────────           ────────────────────
hop/grain/adjunct/yeast/technique defs       version, sim_version, rng_state           scene stack + scene states
style defs, status defs, trait/ability defs  day, location_unlocks, flags              in-flight encounter state
patron defs (TRUE palate), boss defs         inventory {ingredient_id => qty}          brew-in-progress (draft recipe)
location defs, perk defs, unlock rules       yeast_bank {culture_id => instance}       cursor/focus/scroll per scene
attribute list + display metadata            recipes {id => node(parent_id,…)}         animation timers, toasts
                                             beers {id => {recipe_id, snapshot,…}}     event queue (drained each tick)
                  ▲                          taps [beer_id × 6]                        input-mode (:mouse/:kb/:pad)
                  │ resolved by id at        codex {kind => {id => level}}
                  │ point of use             knowledge {patron_id => {facts…}}
                  └──────────────────────    patron_stats {patron_id => {served, best, wins…}}
                                             settings (separate file, cross-slot)
```

**Rules that make this work:**

1. **Ids in state; Defs resolved at point of use.** Never store a Def hash (or any object reference) in Profile or Session. Reasons: saves survive content edits; hot reload of a content file takes effect immediately; no aliasing (the engine's own serializer special-cases shared references via `entity_keys_by_ref` — avoid ever depending on that).
2. **A beer is a *result*, not a Def.** `Beer = f(recipe, yeast_instance, Defs, Tuning)`. Persist `recipe` (source of truth) **and** a cached `snapshot` (attributes + ledger) stamped with `sim_version`. On load, if `sim_version` is stale, recompute (opt-in "rebrew on patch" — a balance patch will alter players' beers slightly; accept and document, because the alternative is that Tuning fixes never reach existing saves).
3. **The yeast *instance* is part of the recipe input.** Mutation across generations means a culture is stateful (`{culture_id, generation, traits_delta, lineage}`); `Brewing` takes the instance, not just the Def id.
4. **Saves are written only at safe points** (hub/world/after-results, never mid-encounter, never mid-brew-UI). This deletes the hardest class of serialization problem (resumable encounter state) for free. Encounter state is Session-only; the encounter *outcome* is Profile.

---

## Architectural Patterns

### Pattern 1: Immediate-mode scene stack with module scenes + plain-hash state

**What:** DragonRuby calls `tick` 60x/sec and wants you to recompute everything each frame. The scene stack holds `{ type: :encounter, s: {…} }` entries; each scene *type* is a stateless module. Frame = `Input.frame` → `update` top scene only → drain events → `render` from the lowest visible scene up to the top (overlays like pause/inventory render over the scene beneath).

**When to use:** All screens. A JRPG needs at least `world → location → encounter → result popup` and `any → menu → detail panel` (two-to-four deep).

**Trade-offs:** + hot reload friendly (redefine module; state hash survives), + trivially serializable/inspectable in the console, + no stale-class-instance trap (sibling learned: reloading a *class* does not re-run `initialize`, so newly added iVars are `nil`). − A field newly added to a scene's state mid-session is `nil` until that scene is re-entered: reload-then-F5 is the dev workflow (document it).

**Example:**
```ruby
module Scenes
  module Encounter
    def self.enter(params)                       # returns the scene's state hash
      { enc: ::Encounter.start(params[:patron_id], params[:tap_ids], params[:knowledge]),
        phase: :choosing, cursor: 0, playback: [] , playback_t: 0 }
    end

    def self.update(s, ctx)                      # ctx = { intent:, profile:, nav:, defs: }
      case s[:phase]
      when :choosing
        s[:cursor] = UI::Focus.move(s[:cursor], ctx[:intent][:nav], tap_count: 6)
        if ctx[:intent][:accept]
          s[:enc], events = ::Encounter.serve(s[:enc], ctx[:profile][:taps][s[:cursor]])
          s[:playback] = events; s[:playback_t] = 0; s[:phase] = :playing_events
        end
      when :playing_events
        Playback.advance(s, ctx)                 # animates events with timing; skippable via accept
        ctx[:nav].replace(:results, enc: s[:enc]) if s[:enc][:over] && s[:playback].empty?
      end
    end

    def self.render(s, ctx) ; ... ; end
  end
end
```

### Pattern 2: Pure simulation returning `(new_state, events)`; presentation plays the event log

**What:** `Encounter.serve(state, beer) -> [state', events]` where `events` is an ordered array of typed hashes: `{t: :score_component, label:, delta:, attr:}`, `{t: :clue, fact:}`, `{t: :status_applied, id:}`, `{t: :patron_line, key:}`, `{t: :satisfaction, from:, to:}`, `{t: :encounter_over, result:}`. The scene turns events into timed animation, SFX, dialogue.

**When to use:** Encounter (primary), and any multi-step domain operation whose result the player must *watch* (brew result reveal, yeast mutation reveal).

**Trade-offs:** + logic never waits on animation (no frame counters in rules); + tests assert on event arrays; + the same events produce the "why" breakdown, the Regulars Book clue log, and replay/debug output; + skippable/fast-forward is trivial. − slightly more allocation than inline mutation (irrelevant at 3 pours/encounter).

Precedent: Pokémon Showdown's simulator consumes player choices and emits a protocol message stream that clients render; choice-requests are separate targeted messages ([Showdown simulator docs](https://github.com/smogon/pokemon-showdown/blob/master/sim/SIMULATOR.md)).

### Pattern 3: Attribute vector + contribution ledger

**What:** Every sensory profile is one canonical ordered attribute list (`ATTRIBUTES = [:malt, :sweetness, :dryness, :body, :bitterness, :hop_aroma, :citrus, :tropical, :herbal, :spice, :roast, :fruit, :funk, :sour, :carbonation, :abv]` — the design's ~16). Brewing stages **append contributions** rather than mutating one number:

```ruby
# a contribution: where it came from, what it moved, and why
{ attr: :bitterness, delta: +3.2, source: [:hop, :magnum], stage: :boil, why: :bittering_addition_60min }
# Brewing.simulate returns:
{ attrs: {malt: 4.1, …}, ledger: [ …contributions… ], derived: {og:, fg:, abv:, ibu:, srm:, atten:}, traits: [:dry_hopped] }
```

Palate scoring does the same (`components: [{attr:, delta:, kind: :like|:dislike|:tolerance|:status|:style, why:}]`).

**When to use:** Brewing, scoring, status modifiers, boss rules. **Trade-offs:** + powers "Why is my beer 7 bitter?", ingredient tooltips, post-pour breakdown, and the clue engine; + stage-local unit tests; − a little bookkeeping per rule. Separate **raw sim values** (OG/IBU/attenuation/ester index, real-ish units) from **sensory attributes** (0-10 scale) via curves in `Tuning` — it keeps the brewing "accurate enough to learn from" (tone: 70% genuine) while the matchup layer stays readable.

### Pattern 4: Declarative rules interpreted by one evaluator

**What:** Synergies (Saaz + lager yeast), status triggers/effects, boss modifiers, perk conditions, unlock conditions are **data**: `{ when: {all: [{attr: :bitterness, gt: 6}, {style_in: [:ipa]}]}, apply: {mult: 0.75, to: :hop_aroma} }`, interpreted by a single `Rules.satisfied?(pred, ctx)` / `Rules.apply(...)`. A lambda escape hatch exists in Defs (Defs are Ruby, not saved), used sparingly for bosses.

**Why:** the UI can *describe* a rule from data (tooltips, Regulars Book, status icons) and the clue engine can reason over it; arbitrary code can't be introspected. (Sibling project converged on the same shape: a single `satisfied?` evaluator.) **Trade-off:** the predicate vocabulary needs designing up front and will be extended; keep it small and grow by need.

### Pattern 5: Hidden-information boundary (`PatronView`)

**What:** `Patron Def` holds the true palate. `Knowledge.view(patron_def, profile_knowledge) -> PatronView` returns only what the player has learned (`likes: [{attr, confidence}]`, `bitterness_tolerance: :unknown | :low`, `hidden: :unrevealed`). **Scenes and widgets receive `PatronView` only.** `Palate.score` receives the true palate, and lives in L2 where only `Encounter` calls it.

**Clue policy (anti-frustration, success criterion #6):** each scored component maps to candidate facts; reveal policy picks the most informative *unrevealed* fact, guaranteeing at least one new fact per pour until the patron is fully known, with style-name hints as softer clues (never decisive — the design constraint forbids "likes IPA → serve IPA"). Knowledge persists in Profile so the Regulars Book fills in across encounters.

**Dynamic palates:** The Influencer ("preferences change with trends") and Buzzed ("preferences less strict") mean palate is *computed*: `Patron.palate_for(def, context)`. Build the hook now even if only static patrons ship first.

### Pattern 6: Intent abstraction (input)

**What:** `Input.frame(args)` runs once per tick and returns a normalized hash; scenes never read `args.inputs`. Built-ins verified in engine docs: `inputs.last_active` (`:keyboard/:mouse/:controller`), shared `key_down.left_right/up_down` for keyboard+dpad, `controller_one.accept/cancel` (handles Switch A/B swap), `connected` flag, `Geometry.rect_navigate`.

```ruby
module Input
  def self.frame(args)
    i = args.inputs; c = i.controller_one
    pad = c && c.connected
    {
      mode:    i.last_active,                                   # drives hint glyphs + hover-vs-focus
      nav:     { x: i.key_down.left_right, y: i.key_down.up_down },   # discrete menu steps
      move:    i.directional_vector,                            # continuous (world walking, if any)
      accept:  i.keyboard.key_down.enter || i.keyboard.key_down.space || (pad && c.key_down.a),
      cancel:  i.keyboard.key_down.escape || (pad && c.key_down.b),
      menu:    i.keyboard.key_down.tab    || (pad && c.key_down.start),
      detail:  i.keyboard.key_down.d      || (pad && c.key_down.west),    # prefer cardinal names (docs)
      tab_l:   i.keyboard.key_down.q      || (pad && c.key_down.l1),
      tab_r:   i.keyboard.key_down.e      || (pad && c.key_down.r1),
      pointer: { x: i.mouse.x, y: i.mouse.y, moved: i.mouse.moved, click: i.mouse.click, wheel: i.mouse.wheel },
    }
  end
end
```

**Notes:** the sibling found `controller_one` handling needs an explicit nil/connected guard and that mruby diverges from CRuby in small ways (`&.`, `defined?`, dynamic constant assignment) — **verify idioms by running, not recalling**. Remapping (commercial requirement) = a mapping table consulted inside `Input.frame` (engine sample `09_ui_controls/06_input_remapping`). Hint glyphs ("[Enter] / (A)") switch on `intent[:mode]`. `[VERIFY]` `controller.key_down.accept` vs `.a` in this build.

### Pattern 7: Focus-or-hover menu navigation (one rule everywhere)

**What:** Every interactive screen is a list of `{id:, rect:}` targets. If `mode == :mouse`, hovered target = the one under the pointer and click activates; otherwise focus moves via `Geometry.rect_navigate(rect:, rects:, left_right:, up_down:)` and `accept` activates (exactly the engine's `02_menu_navigation_advanced` sample). Put this in `UI::Focus` once; every list/grid/tab bar/tap-lineup uses it, so controller support is never a retrofit.

### Pattern 8: Ids-in-state + `Defs` registry + boot validation

**What:** content files call `Defs.register(kind, id, hash)` (idempotent overwrite, so hot-reloading one content file just re-registers its entries). `Defs.validate!` runs in `boot` and **fails loudly** on: duplicate id, unknown attribute key, ingredient referencing nonexistent trait, patron preference on a non-attribute, location referencing missing patron, status referencing missing rule, missing sprite for a Def with `art:` declared (warn + `_missing.png` fallback). Direct copy of a validated sibling pattern (`Room.validate_links!`, `Constructs.validate!` at boot).

### Pattern 9: Generic collection adapter (build the Pokédex once)

**What:** Ingredients, yeast cultures, recipes/beers, patrons, techniques, equipment are all "things you discover, own, and browse". Unify: Profile holds `codex[kind][id] = :seen | :owned | :mastered` (plus kind-specific records elsewhere), and each kind supplies a small adapter: `{ list:, tile:, detail:, sort_keys:, filters: }`. **One** `Scenes::CollectionBrowser` (grid/list + detail panel + tabs) serves them all. The Regulars Book is the same browser with a progression-aware detail panel.

**Why:** the design has ~6 collection UIs; bespoke screens would be the largest UI cost in the project.

### Pattern 10: Domain-event queue (decoupling progression from actions)

**What:** domain operations return events (`:beer_brewed`, `:patron_served`, `:encounter_won`, `:ingredient_acquired`, `:yeast_mutated`); `Game` collects them into the Session queue and calls `Progression.process(profile, events)` once per tick: codex discoveries, Regulars stage changes, unlock checks, tutorial triggers, (later) achievements. Brewing never needs to know that winning unlocks a farmer's grain.

**Trade-off:** indirection; keep the event vocabulary small (≈15 types) and typed with symbols.

### Pattern 11: Seedable, serializable RNG

DragonRuby's `rand` is global engine state (seeded from start time, reset by `DR.reset`) and cannot be saved. Anything stochastic that must be reproducible or fair (yeast mutation, drops, procedural patron names, flavor-text picks) uses `Rng.next(profile[:rng_state])` with the state in Profile, **recorded into the result** (e.g., a Beer stores `mutation_seed`). Encounters themselves must be deterministic: this is a deduction game.

---

## Data Flow

### Frame flow

```
args.inputs ─► Input.frame ─► Intent
                                │
                                ▼
                  SceneStack.top.update(s, ctx)
                                │  calls pure domain fns with Profile slices + Defs
                                ▼
          domain returns { new_state, events[] } ──► scene stores state, starts playback
                                │
                                ▼
          Game drains domain events ─► Progression.process(profile, events) ─► Profile
                                │
                                ▼
          SceneStack.render (bottom→top) ─► UI widgets ─► args.outputs.{sprites,labels,…}
                                │
                                ▼
          Autosave policy (safe points only) ─► Save.write(slot, profile)
```

### Core loop flow (Explore → Acquire → Brew → Serve → Learn → Improve)

```
WorldMap/Location ──visit──► patrons/acquisition sources (Defs.location + Profile.flags)
      │ acquire                                                    │ challenge
      ▼                                                            ▼
Profile.inventory/yeast_bank ◄── rewards ◄── Encounter result ◄── Encounter (3 pours × 6 taps)
      │                                          ▲   │
      ▼                                          │   └─► Knowledge.reveal ─► Profile.knowledge ─► PatronView
Brewing scene: draft Recipe ──Brewing.simulate──► Beer (attrs+ledger) ──► taps[6]
      │ save as child recipe (Lineage: parent_id)                      ▲
      └─────────────────── learn → modify → rebrew ───────────────────┘
```

### Encounter flow (the heart; fully headless-testable)

```
Encounter.start(patron_def, tap_beers, knowledge, ctx)  → enc{satisfaction:0, pours_left:3, statuses:[], last_served:[]}
loop (≤3 pours):
  serve(enc, beer):
    palate     = Patron.palate_for(def, ctx)                       # dynamic palates / boss rules
    components = Palate.score(beer.attrs, palate, enc.statuses, enc.last_served)
    delta      = Σ components  (+ boss/perk modifiers via Rules)
    statuses'  = Statuses.apply_triggers(enc.statuses, beer.attrs) ; Statuses.tick(...)
    facts      = Clues.select(components, def, knowledge)          # ≥1 new fact until fully known
    return enc', [ components…, status events…, clue events…, patron_line, satisfaction, maybe over ]
result → events [:encounter_won/lost] → Progression → Profile (patron_stats, knowledge, rewards, codex)
```

### State management

```
Profile (saved)  ◄── only mutated through domain functions + Progression
Session (RAM)    ◄── mutated by Game/SceneStack/scenes (their own slice)
Defs (static)    ◄── never mutated after boot (hot reload re-registers, never edits in place)
Settings         ◄── own file, applied on boot; not part of a slot
```

---

## Subsystem Notes

### Brewing engine
- **Pipeline:** `mash(grain_bill, mash_temp) → boil(hops@time, additions) → ferment(yeast_instance, temp, days) → condition(option) → finalize`. Each stage `(acc, choices, defs) → acc'` appending to the ledger. Mash temp drives fermentability/body/sweetness; boil drives bitterness/aroma/flavor by utilization-vs-time curves; fermentation drives attenuation/esters/phenols/funk via yeast Def × temperature curve (out-of-range temp = off-flavor contributions, a *teachable* mechanism); conditioning applies specialized traits.
- **Live preview:** `Brewing.simulate` must be cheap and pure so the Brewing scene recomputes the preview every change (and optionally every tick). Cache by recipe hash if profiling ever demands it — unlikely at this size.
- **ABV ambiguity (needs a design decision in the Brewing phase):** design lists ABV among the 16 "attributes" and "Alcohol strength" among the sensory list. Model **ABV as a derived physical stat** (`derived[:abv]`) and expose **perceived alcohol** as a 0-10 attribute through a curve, so patron "alcohol tolerance" and the `Buzzed` status can both key off it.
- **Determinism:** no RNG in brewing except explicit yeast-mutation draws that are recorded into the result.

### Recipe lineage
Recipes are **immutable versions**. "Modify" = create child: `{ id, parent_id, name, created_seq, choices:{…}, diff_tags:[…] }`. `Recipes.diff(parent, child)` yields human-readable change tags ("+ Dry hop 3d", "Yeast: Saison → Belgian Abbey") used for family-tree edges and auto-name suggestions. Store `parent_id` from the **first** persisted recipe — it is impossible to reconstruct ancestry later. Children index is derived at load. Family-tree UI (a `TreeView` widget) can arrive late; the data cannot.

### Collections
- **Yeast Bank:** instances with `generation`, `traits_delta`, `lineage`; mutation is a seeded draw at pitch/harvest time, resolved in a pure `YeastBank.repitch(instance, rng_state) → [instance', rng', events]`.
- **Ingredients:** Defs carry *gameplay identity* (trait bundles + synergy rules + drawbacks as Rules data), not just numbers; inventory is `{id => qty}`.
- **Regulars:** stage is **derived**, never stored (`Regulars.stage(patron_stats, def.thresholds)`), so rebalancing thresholds can't desync saves. Passive benefits are `effects: [{key: :repair_cost_mult, value: 0.8}]` in the patron Def and read through `Perks.query(profile, key)` — no per-patron special-case code.

### World
Location Def: `{ id, kind, name, unlock: pred, patrons: [spawn rules], sources: [{ingredient/yeast/recipe acquisition}], backdrop, music, hotspots }`. **Scope lever for the roadmap (needs a user decision):** the design says "explore" but does not say *how*. Free-roam tile worlds (collision, camera, Tiled maps, NPC pathing) are a large cost center and not what makes this game distinctive. Recommended v1: **node-map travel + each location as an illustrated backdrop with focusable hotspots (patrons, shop counter, brew station)** using the same focus nav as menus. Controller/mouse/keyboard parity is then free. Walkable maps can be layered later without changing Domain, because Domain only knows Location Defs and Profile flags. Time model hook: a single integer `profile[:day]` (stock rotation, festival availability) — decide in design whether brewing consumes days.

### Boss encounters
Bosses are **encounters with rule overrides**, not special code paths: Boss Def = patron Def + `rules: [...]` (declarative where possible: Beer Judge → `style_conformance` penalty rule; Untappd Guy → `commonness` penalty / `rarity` bonus; Influencer → `palate_trend` rule; German Brewmaster → `adjunct` penalty). This needs two derived beer metadata fields that must exist in `Beer` from the beginning: **style classification** (`Styles.classify(attrs, derived) → {style_id, conformance}`) and **rarity/commonness** (from ingredient rarities and style frequency). Budget them in the brewing phase even though bosses ship later.

### Save/load
- **Envelope:** `{ save_version: 1, sim_version:, content_version:, saved_at:, playtime:, profile: {…} }`; migrations are a chain `Migrations.run(data)` stepping `v→v+1`; unknown-newer version refuses to load with a clear message.
- **Slots + backup:** 3 slots; write `slotN.sav` after verifying a read-back parse; keep `slotN.bak` of the previous good save; on corrupt load, offer the backup. Autosave at safe points (return to hub, after encounter result, after brew confirm). Settings are a separate cross-slot file.
- **Engine IO facts (HIGH, read from docs):** `DR.write_save_data/read_save_data` (added 7.14) is the engine-preferred path for user-specific data (dedicated save enclave on locked-down platforms; `__save_data__` dir otherwise, excluded from packaging). `DR.write_file` goes to the sandboxed data dir: macOS `~/Library/Application Support/[gametitle]`, Windows `%APPDATA%\[devtitle]\[gametitle]`, Linux `~/.local/share/[gametitle]`; **in dev builds it writes into the game directory.** No rename/atomic API exists (only write/append/delete/stat/list) → the write-verify-backup scheme above is how to get safety.
- **Serializer choice (opinionated):** the engine's built-in `DR.serialize_state` is `state.to_s` written to disk and `DR.deserialize_state` **`eval`s the text** (`GTK::Codegen.eval_hash`, `docs/oss/dragon/runtime/save_state_load_state.rb`). Consequences: (1) loading executes whatever is in the file — acceptable for a private prototype, a liability for a commercial game with Steam Cloud, hand-edited saves, and player-typed strings (beer names!) going through `inspect` escaping `[VERIFY: mruby `String#inspect` escaping of `#{`/`#@`/`#$` and control chars]`; (2) it silently **sets `Kernel.tick_count` from a `:tick_count` key** in the loaded data — never use that key; (3) it logs a "serialization too large" warning above 20,000 characters (a realistic size for 100+ recipes with lineage). **Recommendation:** write a ~60-line JSON writer (there is **no** `to_json` in the engine) and read with `DR.parse_json` (native, no eval; returns string keys → one schema-aware `Save.symbolize` pass; store ids as strings). Spike this in the foundation phase with a round-trip test covering floats, nil, booleans, nested arrays, quotes/newlines/unicode/emoji in names. Fall back to the engine-native format only if the spike shows JSON round-tripping is lossy.
- **Profile contents must be plain primitives.** No Procs, no class instances, no shared references (use ids), floats rounded on write.

### Rendering & art pipeline
- **Pixel look (HIGH):** `metadata/game_metadata.txt`: `scale_quality=0` (nearest) and `hd=true` (the sibling's setting); sprite-level `scale_quality_enum` can override. Resolution: **recommend 1280×720 logical space, all art authored/processed at integer multiples and drawn at an integer `ART_SCALE`** (single constant in `core/screen.rb`), crisp pixel TTF text at fixed `size_px` steps. The engine also supports true low-res canvases (`aspect_mode`/`aspect_size`, e.g., 640×360, 320×180 — new in 7.14) which gives authentic chunky UI but forces every font and layout decision to be pixel-grid-exact and exposes AI-generated art's inconsistent pixel grids. `[VERIFY]` in an art-pipeline spike with real generated assets before locking; keeping all geometry behind `Screen`/`Layout` makes the switch a one-file change.
- **Beer visuals are procedural composition, cached.** Glass sprite + tinted liquid layer (sprites support `r,g,b,a` tint) + head layer sized/colored from attributes, composed into a **render target once per distinct beer visual signature** (`args.outputs[:beer_#{sig}]`) and drawn as a sprite thereafter. **Pitfall straight from the docs:** merely *accessing* `args.outputs[:name]` invalidates the cached texture — create it on first need, never every frame.
- **Text:** a glyph set is built and cached per `(font, size_px/size_enum)`; lerping size causes huge glyph caches (use render targets to scale labels). Use `String#wrap(n)` / `wrapped_lines` for dialogue boxes; `DR.calcstringbox_h` for sizing — **cache measurements** in widget state, don't remeasure per frame.
- **Asset registry:** `Assets.sprite(:portrait, :darryl, :happy)` → path by convention (`sprites/portraits/darryl_happy.png`); `Defs.validate!` + `DR.stat_file` flag missing art and substitute `_missing.png` so **content can ship before art**, and regenerated art drops in without code changes (`DR.reset` already calls `reset_sprites`, invalidating the sprite cache). Texture atlases are Pro-only — not required.
- **Audio:** `args.audio[:id] = {input:, gain:, looping:}`; wav ≤ 44.1 kHz, ogg for music; wrap in `Sfx.play(:pour)` / `Music.set(:taproom)` (gain-lerp crossfade).

### Testing & balance harness
- **Runner (HIGH, sibling-verified):** `./dragonruby ./mygame --test tests/…` discovers `test_*(args, assert)`; assertion-free tests report *inconclusive* (treat as failure); engine exit code is always 0 and a missing suite falls through into the game loop — so `./test` owns the exit code and bounds runtime with `timeout`/`gtimeout`.
- **Domain suites that earn their keep here:** (1) **golden brews** — fixed recipe → attribute ranges; (2) **"two IPAs differ"** — assert score variance across a set of IPA-styled beers vs. one patron (encodes the design's critical constraint); (3) **solvability** — for every patron Def, ∃ a ≤3-pour sequence from ≥1 plausible tap lineup reaching 100 (and none wins on pour 1 with zero information); (4) **determinism** — same inputs, same event log; (5) **save round-trip + migration** fixtures; (6) **content validation** — `Defs.validate!` passes. The harness is only possible *because* the domain is pure.

---

## Scaling Considerations

"Scale" here is content volume and code size, not users.

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Prototype (≈10 patrons, ≈20 ingredients, ≈20 beers) | Everything in the layering above works unoptimized. Ruby-literal content files, full recompute of previews each change. |
| v1 (≈30-60 patrons, ≈100 ingredients/yeasts, 100-300 recipes/beers per long save) | Keep content files per-category and moderate in size (engine 7.16 warns when a source file nears **codegen limits** `[VERIFY threshold]`); move large text corpora (barks, dialogue, flavor text) to `data/*.json`. Save size grows past the 20k-char engine warning → another reason for own serializer. Virtualize long collection lists (draw only visible rows). |
| Post-v1 (regions as content packs, rival brewers) | Content packs = more `content/` files registered at boot; Profile gains `region_progress`. Domain unchanged — this is why "regions are content, not mechanics" holds. |

### Scaling Priorities
1. **First bottleneck: per-frame UI allocation/measurement.** Rebuilding dozens of label/sprite hashes and calling `calcstringbox` each tick for tap lists, 16-bar attribute views and ingredient grids. Fix: cache prefabs/measurements in scene state keyed by content hash; batch with `outputs.sprites << array.map {…}` per engine perf guide; use `Hash` primitives (not Arrays), `.each` over `.map` when discarding results, `reject!` after iteration not `delete` during.
2. **Second: load/validation time and source-file size** at boot as content grows (see codegen note), and save size.

---

## Anti-Patterns

### Anti-Pattern 1: Rules in scenes
**What people do:** compute satisfaction inside the encounter scene's `tick` because the data is right there.
**Why it's wrong:** no headless tests, no balance harness, animation timing entangled with logic; the explanation UI must re-derive what the scene already computed.
**Do this instead:** scene calls `Encounter.serve`; plays the returned events.

### Anti-Pattern 2: Collapsing to a single number
**What people do:** `satisfaction += beer.score` with one blended formula, or style-name matching ("likes IPA").
**Why it's wrong:** violates the design's critical constraint, destroys clue generation, kills explainability.
**Do this instead:** per-attribute components with labeled deltas; style as a *clue/bias component*, never the decider.

### Anti-Pattern 3: UI reading hidden truth
**What people do:** pass the patron Def to the encounter UI "for convenience".
**Why it's wrong:** one careless label leaks the answer; tests can't prove the boundary.
**Do this instead:** `PatronView` only; grep test that `scenes/` and `ui/` never reference `Defs.get(:patron…)[:palate]`.

### Anti-Pattern 4: Objects or Defs inside saved state
**What people do:** store the `Beer` object / the hop Def hash in the profile.
**Why it's wrong:** content edits orphan saves; shared references round-trip oddly; hot reload leaves stale copies.
**Do this instead:** ids + records of plain primitives; resolve Defs at point of use.

### Anti-Pattern 5: Reading `args.inputs` anywhere but `Input`
**Why it's wrong:** controller/remap support becomes a retrofit across every scene (explicit project constraint: input abstraction from day one).
**Do this instead:** `Intent` only; enforce with a grep test.

### Anti-Pattern 6: Hot-reload traps (both reproduced in the sibling repo)
- **Tunable freeze:** `@x ||= Tuning::X` caches the value forever; saving `tuning.rb` then does nothing, silently. Read `Tuning::` at point of use.
- **Boolean latch:** `@flag ||= true` snaps a deliberate `false` back. Use `@flag = false if @flag.nil?`.
- **`DR.reset` mid-tick** destroys state the current tick still needs → use `DR.reset_next_tick` from input handling. `DR.reset` does **not** clear globals or your constructed objects → top-level `reset` hook must nil `$game`.
- **Class reload doesn't re-run `initialize`** → new iVars are nil; either keep a `defaults!` schema method (sibling pattern) or use hash state (Pattern 1).

### Anti-Pattern 7: Label-size animation, per-frame render-target access, Array primitives
Documented engine performance traps (`docs/guides/troubleshoot-performance.md`, `outputs.md`): lerping `size_px/size_enum` explodes the glyph cache; touching `args.outputs[:rt]` every frame invalidates its texture; Array primitives are slower and deprecated (`DR.warn_array_primitives!` audits).

### Anti-Pattern 8: Premature ECS / third-party frameworks
Draco/Zif-style frameworks add a dependency and a second paradigm on top of an unfamiliar Ruby dialect. This game's "entities" are data records (beers, recipes, patrons) manipulated by pure functions; there is no per-frame entity simulation. Plain modules + hashes is the correct weight. (Same conclusion as the sibling project's research.)

### Anti-Pattern 9: Free-roam world as the default
**Why it's wrong:** tile maps, collision, camera, NPC movement are a large, non-differentiating cost for a brewing/tactics game; they also complicate controller parity.
**Do this instead:** node-map + backdrop hotspots for v1 (see World).

---

## Integration Points

### External Services / Platform

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| DragonRuby runtime | `boot/tick/reset` top-level (or `Main` module — engine-recommended as scale grows; it disables Array/OpenEntity primitives and adds `start`; **precedence is `Main.tick`, `self.tick`, `Object.tick`**) | Pick one and stick to it. Sibling proved top-level + `$game` works. Own engine copy per project; commit engine for shelf-life if repo stays private. |
| Steam | `dragonruby-publish` automates Steam upload for **Indie/Pro**; **Standard** must use Steamworks tooling directly (HIGH, `deploying-to-steam.md`) | **Confirm license tier before planning achievements/cloud/overlay** `[VERIFY]`. For Steam Auto-Cloud, confirm where `DR.write_save_data` lands vs the documented per-OS `write_file` dirs. 7.18 added Steam Big Picture fullscreen behavior (Pro). |
| itch.io | `dragonruby-publish` | Simple; do it early as a CI-style smoke test of packaging. |
| Controllers | Engine abstraction over SDL game pads; `inputs.controllers[0..3]`, `connected`, `accept/cancel` | Test with Xbox + PlayStation + Switch Pro; Steam Deck path documented (`--only-package`, Linux build). |
| Accessibility | Engine has VoiceOver/A11y emulation (macOS/iOS, 7.13); sample `09_ui_controls/04_accessiblity_for_the_blind` | Not a v1 requirement; keep widgets' text available (`UI` widgets know their label strings) so it's addable. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Scene ↔ Domain | Direct function calls with Profile slices + ids; returns `(state, events)` | Scenes never mutate Profile directly except through a domain/Progression function |
| Domain ↔ Domain | Direct calls **downward only** (Encounter→Palate→Statuses→Rules); **sideways via events** (Encounter→Progression) | Brewing never calls Encounter and vice-versa |
| Domain ↔ Defs | `Defs.get(kind, id)` at point of use | Never cache Def objects in state |
| Scene ↔ Scene | Only through `SceneStack` (`push/pop/replace(type, params)`); params are plain hashes of ids | Result scenes receive the encounter outcome, not references |
| UI ↔ Input | `Intent` + `ctx[:intent]` only | |
| Game ↔ Save | `Save.write(slot, profile)` / `Save.read(slot) → profile` | Profile must be plain data; Save owns envelope/migration |
| Content ↔ Assets | Def `art:` key → `Assets.sprite` convention; boot validation flags missing | |
| Tooling ↔ Domain | `tools/` + `tests/` run the pure domain headless (balance harness) | Domain has zero engine deps — that is the contract |

---

## Suggested Build Order (dependencies, for roadmap)

Dependency logic: **Platform shell → Data foundations → Pure domain (headless, tested) → Core-loop UI (the vertical slice) → Persistence of the loop → Collections → World → Commercial wrapper.** Prove the *matchup puzzle* before building the *world around it* (matches the design's own Phase-1 prototype intent: "Can brewing decisions create interesting beers, and can those create interesting patron-selection puzzles?").

| # | Build | Depends on | Why this position |
|---|-------|-----------|-------------------|
| 0 | **Engine setup & scaffolding:** own engine copy, `mygame/` layout, `run`/`test` wrappers with owned exit code, `boot.rb` require list, `core/` (paths, screen, log, rng, tuning), debug HUD, sample test | — | Real first task per PROJECT.md. Everything else is cheaper with test+reload loop working. |
| 1 | **Cross-cutting foundations:** `Input`→Intent (kb+mouse+pad), `UI::Focus` + `Layout` + minimal widgets, `SceneStack`, `Defs` registry + validation, attribute list, **Save envelope + serializer spike (round-trip test)** | 0 | Constraints say input abstraction and saves are cheaper early than retrofitted. Serialization format is the highest-regret early decision. |
| 2 | **Brewing engine (pure) + a few real Defs:** attribute vector, staged pipeline, ledger, derived stats, style classification, rarity; golden tests | 1 (Defs, vec) | Beer attributes are the input to everything downstream; ledger shape must be right before UI. |
| 3 | **Palate scoring + Statuses + Encounter state machine + Knowledge/Clues/PatronView (pure):** event log; ≈10 patrons; solvability + "two IPAs differ" tests; **balance harness** | 2 | The core design risk. Iterate it with no UI at all (text/console dump scenes). |
| 4 | **Core-loop scenes — the vertical slice:** Brewing scene (live preview + explanation panel), Tap lineup (6), Encounter scene with event playback, result screen; BeerGlass + AttributeView widgets; placeholder art | 1-3 | First point where "brew → serve → learn → improve" is playable end-to-end and can be playtested. |
| 5 | **Profile persistence of the loop:** Profile schema, recipes + **lineage (parent_id from day 1)**, beers snapshot, taps, knowledge, patron_stats, autosave at safe points, migrations v1 | 1(Save), 4 | Makes it a real game; lineage data must exist before lineage UI. |
| 6 | **Collections:** Codex + generic CollectionBrowser, ingredient inventory/acquisition, Yeast Bank (instances + mutation + seeded RNG), Regulars Book + stage derivation + Perks, family-tree view | 5 | All are instances of Pattern 9 on top of persisted Profile; mutation needs RNG state in saves (Pattern 11). |
| 7 | **World:** Location Defs, node-map travel, location scene with hotspots, acquisition sources, unlock gating, Progression/unlock rules, day counter | 5-6 | World content is *sources of collectibles and patrons* — needs the things they hand out to exist. |
| 8 | **Boss encounters:** rule overrides (style conformance, commonness, trend palette, adjunct penalty), boss Defs + scene dressing | 3, 7 | Reuses the encounter engine; needs style/rarity metadata from step 2. |
| 9 | **Commercial wrapper:** title/menus, onboarding/tutorial driven by Progression events, settings (volume, remap, fullscreen), save-slot UI, polish/juice, audio pass, Mac/Win/Linux builds, itch + Steam packaging | all | Cross-cutting; onboarding needs the whole loop to exist. Packaging smoke-test (itch build) should happen **early and repeatedly**, not only here. |

**Parallel tracks:** (a) *Art pipeline* — procedural/AI asset generation + post-processing to a consistent pixel grid/palette, runs from step 1 with placeholders; (b) *Content authoring* — Defs grow continuously behind `Defs.validate!`; (c) *Audio* — placeholder SFX hooks from step 4.

### Research flags for phases

| Phase | Flag |
|-------|------|
| 1 | **Spike:** save serializer round-trip (JSON writer vs engine-native; string escaping; float fidelity); `controller.key_down.accept` behavior; `Main` vs top-level entry. |
| 2-3 | **Deep design research:** scoring math, curve shapes, clue policy, status interaction balance. Not an engineering-pattern risk — a *game-design* risk; budget playtest iterations and the harness. |
| 4 | **Spike:** resolution/scale/font decision with real AI-generated assets; BeerGlass render-target caching approach. |
| 7 | **Design decision needed from user:** node-map+hotspots vs free-roam (scope lever); does brewing consume days? |
| 9 | **Verify:** license tier; Steam Cloud path vs `write_save_data` location; codegen file-size limits at content scale. |
| 5, 6, 8 | Standard patterns (versioned records, collection browsers, rule overrides) — unlikely to need separate research. |

---

## Sources

- **Engine docs and source (HIGH), local build `0d709c3` / v7.18 (2026-09-11):** `/Users/charris/src/mechtech/dragonruby-macos/docs/api/{state,runtime,inputs,outputs,layout,geometry,audio}.md`; `docs/guides/{troubleshoot-performance,starting-a-new-project,deploying-to-steam}.md`; `docs/oss/dragon/runtime/{save_state_load_state,require}.rb`, `attr_dr.rb`, `string.rb`; `CHANGELOG-CURR.txt` (7.14 `read/write_save_data`, `aspect_mode`; 7.16 codegen-limit warning; 7.18).
- **Engine samples (HIGH):** `samples/09_ui_controls/02_menu_navigation_advanced` (focus-or-hover), `09_ui_controls/06_input_remapping`, `06_save_load/01_save_load_game`, `99_genre_board_game/03_word_game` (`write_save_data`), `99_genre_jrpg/turn_based_battle` (phase-flag turn flow — shows the *minimum*, not a structure to adopt: one 168-line tick with `args.state.phase`), `99_genre_jrpg/cutscenes`.
- **Sibling project (HIGH, same author, same engine build):** `/Users/charris/src/mechtech/` — `.claude/skills/dragonruby/SKILL.md`, `.planning/phases/01-engine-foundation-debug-spine/01-LEARNINGS.md`, `mygame/app/{main,boot,input,paths,world_state,game}.rb`, `run`, `test`. Source of the hot-reload traps, mruby-dialect divergences, test-runner exit-code finding, ordered-require convention, single-file tuning rule.
- **Genre patterns (MEDIUM):** Pokémon Showdown simulator/protocol separation — https://github.com/smogon/pokemon-showdown/blob/master/sim/SIMULATOR.md ; scene/state-stack with overlay menus and `init/pause/resume/term` lifecycle — https://textbooks.cs.ksu.edu/cis580/07-game-architecture/04-game-screens , https://gamedev.net/forums/topic/337919-using-a-stack-for-the-gamestate/ ; Nystrom, *Game Programming Patterns* (State, Game Loop, Event Queue, Data Locality chapters).
- **Not verified / needs spike:** mruby string-inspect escaping, codegen-limit threshold, Steam Cloud path, license-tier-gated Steam features, `controller.key_down.accept` (all tagged `[VERIFY]` above).

---
*Architecture research for: collectible brewing RPG on DragonRuby GTK*
*Researched: 2026-10-06*
