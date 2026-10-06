# Pitfalls Research

**Domain:** Collectible brewing RPG (collection + matchup deduction + crafting sim hybrid), DragonRuby GTK, solo dev, commercial Steam/itch.io release, AI-generated pixel art
**Researched:** 2026-10-06
**Confidence:** MEDIUM overall. DragonRuby, Steam and licensing facts are HIGH/MEDIUM (read from the official DragonRuby docs repo at v7.9 and Valve/DR pages). Game-design and AI-art pitfalls are MEDIUM (synthesized from genre patterns plus analysis of this project's own design doc, not from a single authoritative source). Items marked [VERIFY] must be checked in a Phase 1 spike before architecture depends on them.

**Phase labels used below** (the roadmapper may rename or renumber; the mapping is by capability, not number):

| Label | Capability |
|-------|------------|
| P1 Foundations | Engine setup, repo layout, input abstraction, UI kit, save skeleton, build/packaging smoke test, art style-lock spike |
| P2 Simulation Core | Headless, data-driven brewing model, attribute scoring, patron palettes, tuning/solvability harness |
| P3 Encounter Slice | Playable brew -> serve -> learn loop with placeholder art (rectangles + text), status effects, clue system |
| P4 Collection Systems | Ingredient/yeast/recipe collection, lineage, Regulars Book, tap lineup management |
| P5 World and Progression | City locations, acquisition, bosses, economy, onboarding curve |
| P6 Art and Presentation | Bulk art generation/integration, beer visuals, portraits, audio, juice |
| P7 Release Hardening | Settings, save migration, Steam/itch packaging, store page, Deck/Linux/Windows QA, ratings, AI disclosure |

---

## Critical Pitfalls

### Pitfall 1: Building the full game before the core loop is proven fun

**What goes wrong:**
PROJECT.md records "Full v1 game, not just Phase 1 prototype" as a key decision. The design doc's own Phase 1 exists to answer one question: "Can brewing decisions create interesting beers, and can those beers create interesting patron-selection puzzles?" If the answer is "not really," the project discovers it after UI, art, content and world systems are built on top of the wrong core.

**Why it happens:**
Solo developers want visible progress (menus, portraits, maps). Systems games feel fine on paper (16 attributes, 10 statuses, 5 relationship tiers) and only reveal dullness when played. Art and content are expensive to throw away; a bad core becomes a sunk cost that gets patched instead of fixed.

**How to avoid:**
Keep the full-v1 ambition but sequence it so the first playable is the design doc's prototype in disguise: P2+P3 produce an ugly, rectangles-and-text, controller-playable brew -> serve -> learn loop with ~10 patrons, ~20 ingredients, 6 taps. Put an explicit go/no-go gate after P3 using the design doc's seven success criteria (especially #2 "understand why a pour succeeded/failed", #6 "deduction not frustration", #7 "describe beers like RPG characters"). No bulk art, no world map, no bosses until the gate passes. Put 3-5 outside playtesters (ideally craft-beer people, not only game people) through the slice and watch them without coaching.

**Warning signs:**
Roadmap has art/world/UI-polish phases scheduled before any phase whose exit criterion is "a stranger plays the loop and explains a win/loss." Attribute list or scoring formula still changing while portraits are being generated. Nobody has lost an encounter on purpose to learn something.

**Phase to address:** P2/P3 (gate), roadmap-level sequencing.

---

### Pitfall 2: Stat soup -- 16 sensory attributes the player cannot read, compare, or act on

**What goes wrong:**
Sixteen numeric attributes (Malt, Sweetness, Dryness, Body, Bitterness, Hop Aroma, Citrus, Tropical, Herbal, Spice, Roast, Fruit, Funk, Sour, Carbonation, ABV) shown as 16 bars or a spreadsheet make the game feel like the "sterile industrial brewing simulator" the design doc says to avoid. Players cannot hold 16 dimensions in working memory, so they stop reasoning about flavor and either brute-force or ignore the numbers.

**Why it happens:**
The data model has 16 fields, so the UI shows 16 fields. Designers confuse model fidelity with player-facing fidelity. Several attributes are also correlated or mutually exclusive in reality (Dryness vs Sweetness vs Body; Citrus/Tropical/Fruit overlap; ABV is a different kind of quantity than the others), which makes sliders redundant and confusing.

**How to avoid:**
- Keep 16 in the model but present in families: e.g. Malt side (Malt, Roast, Sweetness, Body), Hop side (Bitterness, Hop Aroma, Citrus, Tropical, Herbal, Spice), Yeast side (Fruit, Funk, Sour, Dryness), Mouthfeel/Strength (Carbonation, ABV). 4-5 glanceable groups, each with a single iconographic "flavor wheel" or radar glyph; numbers only on drill-down.
- Surface "top 3 traits + 1 flaw" per beer as the primary identity (this is also what makes beers feel like characters).
- Treat ABV as a separate strength axis (it drives tolerance checks, not preference matching) rather than the 16th flavor bar.
- Patron palettes should reference families and 3-5 specific axes, never all 16.
- Run a "5-second glance test" in P3: can a tester say what a beer is good against without opening a detail screen?

**Warning signs:**
Brew screen has more than ~7 live controls visible at once. Playtesters narrate numbers ("it has 4 citrus") instead of character ("it's bright and snappy"). Two attributes are never decisive in any patron.

**Phase to address:** P2 (model grouping), P3 (display and glance test), P1 (UI kit must support glyph/radar widgets).

---

### Pitfall 3: Deduction collapses into style-matching, a guessing game, or a one-shot solved puzzle

**What goes wrong:**
This is the design doc's explicit warning ("patron likes IPA -> serve IPA"), and there are four distinct ways it fails:
1. Style leak: patron data or UI mentions styles as the preference unit; the sensory layer becomes decorative. Also happens if beers carry a player-visible style label that was chosen rather than computed.
2. Under-determined puzzle: 3 pours cannot identify a hidden preference vector over many dimensions. Players guess, lose, and feel cheated (the doc's criterion #6 fails).
3. Information leak: the example result "+22 Hop Match, +8 Dryness, -12 Excessive Bitterness" prints the scoring breakdown. Show exact weights and the puzzle is solved in one pour; show nothing and it is noise.
4. One-and-done: once the Regulars Book records a patron's palette, every later encounter is execution, not deduction, and the whole game after the first win per patron is trivial.

**Why it happens:**
Preference/score formulas are written before anyone computes how much information each pour reveals. Style names are the easiest shorthand for content authors, so they creep into patron definitions. Nobody simulates a "reasonable player" against the content.

**How to avoid:**
- Style is an output, never an input: compute a style label from the attribute profile (and show it as a clue-ish tag), and forbid patron data from referencing style IDs except for the explicit boss gimmicks the doc lists (Beer Judge, German Brewmaster), which should themselves be defined by attribute/technique rules.
- Define an information budget per pour: each pour reveals 1-2 facts at coarse resolution (Likes/Neutral/Dislikes an axis; tolerance Low/Med/High) with deterministic semantics, never exact weights. Show score breakdown as direction + magnitude buckets, not raw numbers that are invertible.
- Patron palettes: 3-5 positive axes + 1-3 dislikes + 2 tolerances + 1 hidden (matches the design doc) -- this keeps the hypothesis space small enough for 3 pours to be solvable given prior-knowledge hints (location, personality, bartender tips).
- Make a headless solvability test (see Pitfall 4 tooling): a scripted "reasonable player" that follows clues should win >=70% of encounters within the pour limit; a "style-only" strategy and a "random" strategy should win far less. Fail the build if a patron is unwinnable or trivially winnable by the best all-rounder.
- Choose the one-and-done policy deliberately: either (a) known info persists and later encounters escalate (stricter pours, status stacking, combined patrons), or (b) patron mood/context varies per visit (e.g. hunger, "had a long day" shifts one axis), keeping recipes relevant but deduction partially fresh.
- Fail-forward: losing an encounter must still write what was learned into the Regulars Book. Deduction without persistence of clues is just frustration.

**Warning signs:**
Content spreadsheet column named "Favorite style." Testers who never open the attribute screen still win. Testers who open it still lose repeatedly. A single beer (the "Crowd Pleaser") beats most patrons. A patron can be solved by pour 1.

**Phase to address:** P2 (scoring + info model + solvability harness), P3 (clue UX), P5 (escalation for repeat encounters).

---

### Pitfall 4: A dominant "max everything" beer, and no tooling to see it coming

**What goes wrong:**
If satisfaction is the sum of matches minus penalties and brewing has no real tradeoffs, the optimal beer is a balanced, inoffensive middle (the doc's "Crowd Pleaser" bonus makes this worse) or a maxed intensity beer, and the 6-tap lineup collapses to one recipe. Conversely, if tradeoffs are too steep, "creative" beers are always worse than a safe cookie-cutter. Without data you will not notice until playtesting, and by then 40 patrons are authored against the wrong formula.

**Why it happens:**
Additive scoring rewards breadth; designers tune by hand on a few examples. Content tuning without a matrix view ("every archetype beer vs every patron") is guesswork.

**How to avoid:**
- Give brewing real tradeoffs: shared attribute budget/conflicts (high attenuation raises Dryness and lowers Body/Sweetness; heavy roast masks hop aroma; high ABV increases warmth and "Hop Burn" risk). Aim for diminishing returns and penalty asymmetry (a disliked axis hurts more than a liked axis helps), so inoffensive ~ mediocre.
- Cap and condition "free bonus" abilities (Crowd Pleaser only helps while ≥N preferences unknown, and decays as knowledge grows).
- Build a pure-Ruby tuning harness in P2 (DragonRuby ships a unit-test runner; the docs include `samples/10_advanced_debugging/03_unit_tests`): generate N random/archetype recipes, score vs all patrons, print a heatmap, report (a) patrons nobody beats, (b) patrons everyone beats, (c) the best single beer's win rate, (d) how many distinct beers are best-in-class for at least one patron. Rerun on every balance change. Success target: in a 6-tap lineup at least 4 distinct beers are the unique best answer to some patron.
- Keep the simulation free of `args`/outputs so the harness can run headless.

**Warning signs:**
One recipe in everyone's tap list. Balance changes are made by editing a single patron at a time. Authors cannot answer "which patrons does the saison beat?" without playing.

**Phase to address:** P2 (model + harness), re-run at P4/P5 whenever content expands.

---

### Pitfall 5: Status effects and serving order that do not actually matter (or become homework)

**What goes wrong:**
The doc lists 9 status effects (Refreshed, Palate Fatigue, Buzzed, Stuffed, Curious, Nostalgic, Hop Burn, Pucker Shock, Wrecked Palate) in a 3-pour encounter. With only 3 pours there are barely 2 meaningful ordering decisions; if effects are invisible, stochastic, or have fuzzy triggers, order becomes noise; if all 9 are live from the start, players must hold a rules matrix in their head.

**Why it happens:**
Effects get designed as flavor lists rather than as decisions. Nobody measures "does the best order beat the worst order?"

**How to avoid:**
- Introduce 2-3 effects first (Palate Fatigue, Hop Burn, Refreshed), each tied to a single visible attribute threshold (e.g. Bitterness >= 7 applies Hop Burn for the next pour). Add others one at a time via patrons/locations/bosses that teach them.
- Always show active statuses with icon + one-line rule; effects expire on a visible counter.
- Add to the harness: for each patron, best-order vs worst-order score delta across the player's tap list; require a meaningful delta (e.g. >=15 satisfaction points) in a healthy fraction of encounters. If ordering never matters, the feature is dead weight; if it always matters, it is a tax.
- Consider 4-5 pours for bosses so ordering becomes strategic rather than a single binary choice.

**Warning signs:**
Players cannot name the current status. Winning order is identical for every patron. Testers say "I just serve the best beer first."

**Phase to address:** P2 (rules + harness), P3 (display), P5 (staged introduction).

---

### Pitfall 6: Unpredictable, unexplained brewing outcomes (black-box brewing)

**What goes wrong:**
Players choose grain bill, hop timing, yeast, fermentation temp and conditioning, then get a beer with surprising numbers. If cause and effect is not legible, brewing feels random, experiments are not learnable, "players modify recipes after learning patron preferences" (doc criterion #3) fails, and brewing accuracy ("accidentally learn real brewing concepts") is wasted.

**Why it happens:**
Many ingredient/process interactions get coded with no preview, no attribution, and no consistent rules of thumb. The pure-simulation temptation (real mash chemistry) produces opaque outputs; the pure-lookup temptation produces flat outputs.

**How to avoid:**
- Use a small number of consistent, real rules of thumb (hot mash -> fuller/sweeter; cool mash -> drier; early hops -> bitterness, late hops -> aroma; warm ferment -> esters/phenols, cool/lager -> clean; etc.) and make each ingredient contribute to 2-3 dominant attributes plus an identity trait, not 8 small modifiers.
- Provide a live "brewer's estimate" preview that updates as choices change, with a visible causal tag on the largest contributors ("Dry: yeast attenuation +2, mash 148F +1").
- Have a beer-literate reviewer sanity-check the rules table; this audience will notice wrong claims and the tone target is 70% real beer culture.
- Preserve a post-brew "batch notes" screen explaining what drove the result. This is the same text that later powers "lineage" storytelling.

**Warning signs:**
Testers say "I don't know what that did." Players default to pre-made recipes. Nobody changes fermentation temp because they cannot predict the effect.

**Phase to address:** P2 (rules table + preview API), P3 (UI), content review again at P4.

---

### Pitfall 7: Content explosion and the balance treadmill

**What goes wrong:**
Collection games are content-bound. The prototype scope (10 patrons, 8 hops, 5 grains, 5 yeasts, 3 adjuncts) is small, but v1 "one city, all systems" implies perhaps 40+ patrons, 6+ bosses, 30+ ingredients, 8 locations. Every patron needs a palette, portrait (with expressions), personality, per-attribute reaction lines, Regulars Book entry, and a balanced win path. Every new ingredient changes the reachable attribute space and invalidates earlier balancing. The dialogue matrix ("Good hops, but that's way too bitter for me") multiplies by patron voices.

**Why it happens:**
Content is treated as free once the engine exists. No fixed budget, no data-driven authoring, no review matrix, so the roadmap gets extended whenever another idea appears.

**How to avoid:**
- Set a content budget up front in the requirements (example: 12 hops, 8 grains, 8 yeasts, 6 adjuncts/conditioning options, 30 patrons, 6 bosses, 8 locations) and treat additions as scope changes.
- All content as plain data files (Ruby hashes or a simple text format) with a validator (required fields, palette size limits, no style references, attribute range checks). No content in code.
- Reaction text is generated from templates keyed by (attribute, direction, intensity) with archetype voice overrides (Finance Bro, Patio Dad, Judge) and a few handwritten signature lines per patron. Do not hand-write N x M lines.
- Reuse archetypes with parameter variation; reserve unique mechanics for bosses.
- Run the balance matrix (Pitfall 4) as a content CI step.
- Write the quest/dialogue style guide early so voice (70/30 culture/comedy) stays consistent.

**Warning signs:**
Content spreadsheet growing faster than playable slice. Each new patron requires a code change. "Just one more hop" requests. Dialogue lines are copy-pasted with minor edits.

**Phase to address:** P2 (data format + validator), P4/P5 (budgeted content), roadmap-level scope lock.

---

### Pitfall 8: Collection systems with no pull -- mutation that destroys work, RNG that gates fun, and beers with no identity

**What goes wrong:**
- Yeast "mutation across generations" silently altering a tuned recipe punishes the exact behavior the game wants (iteration and attachment).
- Pure-RNG rare drops (rare yeast hunts) feel arbitrary; collectors grind or quit.
- The Regulars Book (Seen -> Served -> Impressed -> Regular -> Friend) becomes a checklist unconnected to play.
- Beers are all "colored glass + number list," so nobody gets attached; the central "my saison is great against adventurous patrons" fantasy needs beers that read as characters.
- Completion for its own sake (bottle-cap grinding) in a game that does not need it.

**Why it happens:**
Pokemon-style structures are copied (rarity tiers, breeding, dex) without the thing that makes them work: stable identity, readable strengths/weaknesses, and discoveries that change what you do next.

**How to avoid:**
- Mutation creates a new forked strain/recipe entry in the lineage with a visible diff; the parent is never overwritten. Offer mutation as opt-in or at a clearly signposted moment.
- Make acquisition knowledge-driven: rare cultures unlocked by specific patron friendships, location discoveries, or successful serve conditions (deterministic with a few random elements, plus pity guarantees), not blind drops.
- Define Regulars Book tier criteria in terms of mechanics that already exist (Seen = met, Served = >=1 pour, Impressed = score >=X, Regular = learned all palette axes, Friend = beat with a signature recipe), so progression is a side effect of play, not a separate grind.
- Give each beer a compact identity card: generated name, top-3 traits, a procedurally composed visual (liquid tint, head, glass, tap-handle/label seeded from the recipe ID and lineage), and a one-line "tasting note" produced from its attributes. Make favorites visible. These are cheap procedural features that carry most of the "beer-as-creature" payoff.
- Cap the active tap list at 6 but give a recipe archive with sort/filter/compare; the archive UI is a real cost (see Pitfall 11).

**Warning signs:**
Players stop renaming beers. Testers refer to beers by style ("the IPA") instead of by name. A rare ingredient is strictly better than common ones and nobody keeps commons.

**Phase to address:** P4 (primary), P2 (data model for lineage), P6 (visual identity).

---

### Pitfall 9: Recipe lineage and save data that cannot survive balance changes

**What goes wrong:**
"Evolution" is ambiguous: is a beer a mutable recipe, an immutable version, or a brewed batch? If recipes are mutable, ancestry is lost; if derived attributes are stored, balance patches create beers that no longer match the rules; if derived attributes are recomputed from rules, a post-launch balance patch silently changes a player's win/loss history and tuned lineups.

**Why it happens:**
Data model decided late or ad hoc, while lineage UI is the visible feature. Balance patches after launch are almost certain in a systems game and are rarely planned for.

**How to avoid:**
- Decide in P2: Recipe = immutable value object (ingredient IDs, process params, parent_id, created_at, ruleset_version). "Edit" always creates a child. Beer instances/batches are out of scope (no inventory, aging or freshness simulation unless it is explicitly scoped later).
- Store the recipe plus the ruleset version; recompute attributes at load from the current ruleset so balance fixes propagate. Surface changes ("Your Garage Pale Ale changed after the 1.1 balance patch") rather than hiding them. Decide and document this policy.
- Use stable string IDs for ingredients, patrons, recipes and locations in saves (never array indexes or object references), so adding or reordering content never corrupts old saves.
- Store lineage from the very first brew even if the family-tree UI ships later.

**Warning signs:**
Recipe has an `update` method. Saves reference `ingredients[3]`. There is no `ruleset_version` field.

**Phase to address:** P2 (model), P1 (save schema), P7 (migration QA).

---

### Pitfall 10: Scope creep into a management sim, and an overworld nobody budgeted

**What goes wrong:**
The design doc deliberately defers management systems but leaks them in the core loop ("Improve the brewery"; regulars who visit the brewery; passive benefits like "Equipment repairs cost less," "unlocks food pairing mechanics," "unlocks unusual yeast"). Each perk implies a subsystem (equipment durability, repair costs, food pairing, a brewery that people visit). "JRPG-style" and "Explore" also invite a walkable overworld with tilemaps, collision, NPC scripting and cutscenes -- often 30-50% of a JRPG's tooling.

**Why it happens:**
Every system sounds like a small addition to a "cozy" game. Without an explicit closed list of allowed regular perks and a decision on exploration form, each design conversation reintroduces them.

**How to avoid:**
- Define a closed set of regular perk effect types that only touch existing systems (extra info reveal, ingredient/yeast unlock, shop discount, +1 pour in a specific context, tolerance hint). Cut examples that need new systems (equipment repairs, food pairing) and move them to Out of Scope.
- Make "Improve the brewery" a small fixed upgrade tree (e.g. +tap slot, +brewing option) or cut it for v1; it should not become equipment simulation.
- Choose exploration form explicitly in P1/P5: recommended is a menu/node-based city map with illustrated location scenes and short dialogue/choice interactions, not a walkable overworld. This preserves "explore -> acquire" while removing most of the tilemap/collision/scripting cost.
- Any new system proposal must name which design success criterion it improves; if none, it is v2.

**Warning signs:**
Backlog contains "inventory durability," "staff," "reputation," "events/festivals as systems." Roadmap phases for world build before the encounter gate. Art requests for tilesets.

**Phase to address:** roadmap-level, P4 (perks), P5 (world form).

---

### Pitfall 11: UI is the hidden majority of the work (no widget kit in DragonRuby)

**What goes wrong:**
This game is menu-heavy: brew screen, ingredient/yeast banks, recipe archive with lineage, tap lineup, encounter screen with clues and statuses, Regulars Book with 40+ entries, settings, save/load, tutorial. DragonRuby gives primitives (sprites, labels, solids, render targets, a layout helper), not a UI toolkit. Without scrolling lists, grids, tabs, modals, tooltips, text wrapping, 9-slice panels, focus navigation and dialogue boxes, each screen is rebuilt ad hoc, and the first controller pass breaks all of them.

**Why it happens:**
UI is treated as polish at the end of each feature; mouse-driven click hit-testing is the path of least resistance.

**How to avoid:**
- Build a small UI kit in P1 before any feature screen: focus manager/graph (every interactive element is a focusable node), list/grid with scrolling, tabs, modal stack, tooltip/help panel, 9-slice panel, text wrapper, dialogue box with typewriter and skip, toast, and prompt-glyph widget. Make it data-driven (declare screen layouts, not draw loops).
- Cache static panels in render targets; do not rebuild paragraph layouts every tick.
- Use the engine's `layout` API where it fits (check `docs/api/layout.md`); otherwise define a single grid unit and anchor system.
- Budget explicitly: expect UI to be 30-40% of total engineering effort for this genre.

**Warning signs:**
Each screen has its own input handling code. Mouse works but d-pad cannot reach a control. Text overflows panels.

**Phase to address:** P1 (kit), every later phase (consumers).

---

### Pitfall 12: Input abstraction retrofitted too late, or mouse-first UI bolted to a controller

**What goes wrong:**
PROJECT.md mandates mouse + keyboard + controller from day one, which is right, but the usual failure is a mouse-first click UI with controller "emulated" later: drag-and-drop for reordering taps, sliders for temperature, hover-only tooltips, typed text for beer names. These do not map to a focus-navigated UI, so the retrofit is a rewrite. Steam Deck Verified-style requirements add constraints (glyphs must match the active controller, no keyboard glyphs while controller is active, controller-only text entry).

**Why it happens:**
Mouse UIs are easiest to prototype. DragonRuby gives you shared `up/down/left/right` plus `key_down.*`, `accept`/`cancel` abstractions and `last_active` -- good primitives, but the game must build an intent layer on top.

**How to avoid:**
- One input layer: poll once per tick into a small set of intents (`:confirm, :cancel, :nav_up/down/left/right, :tab_prev/next, :menu, :context, :scroll`). Screens consume intents only; no raw `keyboard.key_down.x` in game code except inside the layer.
- Focus is the primary model; the mouse moves/sets focus (hover = focus, click = confirm). Do not build a separate click path.
- Use DragonRuby's `accept`/`cancel` names (they handle Switch Pro button swap) and cardinal names; avoid hardcoding `a`/`b`.
- Track `args.inputs.last_active` and render prompt glyphs for the active device; support remapping keyboard in Settings from the start (store a binding map in the save/settings file).
- Replace drag-and-drop with pick/place; sliders with steppers; hover-only info with a focus-shown help panel; typed names with generated names + an in-game controller-friendly character picker.
- Handle controller disconnect/reconnect (`connected` flag), deadzones, and menu repeat rates.
- Write input tests (replay a scripted sequence of intents through a screen).

**Warning signs:**
Any `if args.inputs.mouse.click` outside the input layer or hit-test code. Tooltips only on hover. A controller user cannot rename a beer or reach Settings.

**Phase to address:** P1 (layer + focus model), validated at every phase.

---

### Pitfall 13: Save data design -- DragonRuby serialization is not JSON and not forgiving

**What goes wrong:**
`GTK.serialize_state` / `deserialize_state` (the DragonRuby docs sample uses `$gtk.serialize_state('game_state.txt', state)`) write Ruby inspect-style text (e.g. `{:entity_id=>3, :player_one=>"test"}`), not JSON. Custom class instances must define their own `serialize`/`inspect`/`to_s` or they do not round-trip; objects holding `args`, procs, or circular references break or bloat the file (the docs mention `serializable_without` for classes that keep `@args`, and the engine's own unit tests assert a "serialization too large" flag around ~3000 state keys). Dumping all of `args.state` mixes saveable data with transient UI/view state. Symbol keys become string keys if you round-trip through `parse_json`. In development, `write_file` writes into the game directory; in production it goes to the OS sandbox (`%AppData%\Roaming\[devtitle]\[gametitle]`, `~/Library/Application Support/[gametitle]`, `~/.local/share/[gametitle]`) so save bugs hide until a production build. A crash or quit during write can corrupt the only save.

**Why it happens:**
It is tempting to serialize the whole state hash and call it a save. Hot-reload development masks serialization and path issues.

**How to avoid:**
- Separate three data layers: (1) static content (patrons, ingredients), loaded from the game directory and never saved; (2) save data, a plain nested Hash/Array/String/Integer/Float/Symbol/bool structure with ID references only; (3) transient runtime/UI state, never saved.
- Define a save schema with `save_version` and `ruleset_version`; write explicit migration functions from day one, even when only v1 exists.
- Write to a temp name, validate by deserializing, then promote; keep a rolling `.bak` and multiple slots; add a checksum or at least a sanity check on load and show a friendly recovery path instead of a crash.
- Autosave at safe points (after an encounter, after brewing), plus manual save. Test load-after-quit in a production build, not only dev.
- Test round trips automatically: create state -> save -> load -> deep-equal, in the headless test runner.
- Settings (volume, bindings, display) live in their own small file so a corrupt save never loses them.
- Steam Cloud: plan on Steam Auto-Cloud pointed at the sandbox save paths, since DragonRuby does not obviously expose Steamworks Cloud API (see Pitfall 17) [VERIFY].

**Warning signs:**
`serialize_state(args.state)` is the save function. Save contains view state (scroll positions, hover). Loading a save from yesterday's build crashes. No production-mode save test exists.

**Phase to address:** P1 (schema and IO skeleton), P2 (round-trip tests), P7 (migration QA).

---

### Pitfall 14: DragonRuby dev-mode illusions -- hot reload, global state, and mruby limits

**What goes wrong:**
- Hot reload keeps globals/classes alive: `$game ||= Game.new` survives a reload with stale state; constants redefine with warnings; code that works after a reload fails on cold boot. `args.state` is effectively a singleton, `DR.reset` only resets `args.state`, not globals or class instances unless you define a top-level `reset`. Bare `iVars` outside classes pollute global object space.
- DragonRuby embeds mruby, not CRuby: `require` of gems is not supported (`$gtk.require`/`require` of local files only), the stdlib is smaller, and pure-Ruby gems must be vendored as source [VERIFY: Set, Struct, Comparable, `format`/`%`, `String#wrap`, Time APIs before depending on them].
- Production builds differ from dev (`DR.production?` disables logging and dev tools; creating `metadata/dragonruby_production_build` simulates it).
- The docs strongly recommend an unzipped clean copy of DragonRuby per game (file access functions assume the binary lives alongside the game) and committing it all to source control.

**Why it happens:**
Fast iteration hides cold-boot bugs; Ruby habits (require, gems, Set, Marshal) do not all carry over to mruby.

**How to avoid:**
- Structure the game as classes with `attr_dr` (or explicit args passing) and a single `Game` root created in `boot`, with an explicit `reset` hook; no bare iVars; `args.state = {}` in `boot`.
- Keep the simulation as pure Ruby classes with no engine dependency (also enables headless tests).
- Maintain a cold-start smoke test: run `dragonruby` with a production-build marker file on every phase.
- Spike in P1: confirm which stdlib features you need exist; if not, write tiny local equivalents.
- Keep the engine directory inside the repo as the docs advise; confirm the DragonRuby license permits committing engine binaries to your repo visibility (keep the repo private) [VERIFY]. Add save/build output paths to `.gitignore`.
- Use lowercase snake_case file names with no spaces (the packager warns, and Linux/Steam Deck are case-sensitive while macOS usually is not).

**Warning signs:**
Bugs that vanish after pressing reload. "Works on my Mac" file path casing issues. Use of `Marshal`, `Set`, or gems in early prototypes without checking.

**Phase to address:** P1.

---

### Pitfall 15: Performance traps in a text-and-sprite-heavy DragonRuby game

**What goes wrong:**
- Array-based primitives and Array-argument geometry calls are slower; the DR performance guide says use Hashes, add outputs in bulk, avoid mutating arrays during iteration, and avoid lerping label `size_enum`/`size_px` (each size/font combination caches a glyph set, so animated text scaling floods the cache; use render targets for scaled text).
- Texture cache: the 7.8 changelog raised the max cached texture entries to 2048 and cache ejection occurs beyond that. A large set of separate portraits, ingredient icons, beer layers, UI pieces and backgrounds can exceed it and cause load hitches.
- Rebuilding large paragraph layouts and Regulars Book pages every frame at 60 ticks/sec.
- Pre-rendering every beer visual permutation (color x head x glass x label) as separate PNGs.
- Procedural effects (pour animation, foam, carbonation bubbles) with many particles.

**Why it happens:**
Games like this look static, so performance is not measured; the AI art pipeline emits one PNG per asset by default.

**How to avoid:**
- Compose beer visuals from a handful of grayscale layers tinted at runtime (DR sprites accept r/g/b/a), with head and glass as separate layers, rather than prebuilt permutations.
- Pack small assets into sprite sheets/atlases; keep distinct texture paths comfortably below ~1500; load per-location portraits lazily where reasonable.
- Cache static UI panels and text blocks in render targets and invalidate on change; use `DR.benchmark` and add an on-screen frame-time overlay in dev.
- Follow the DR performance checklist (Hashes not Arrays, bulk `<<`, `:solid` sprites instead of `solids`).
- Set a budget (e.g. sustained 60 fps on a 2018-era laptop and Steam Deck) and test on the weakest target periodically.

**Warning signs:**
Frame time spikes when opening the Regulars Book or changing locations. Frame drops on Linux/Deck only (the 7.7 changelog mentions Deck framerate fixes). Hundreds of unique PNGs in the sprites directory.

**Phase to address:** P1 (budgets and tooling), P6 (atlasing/integration).

---

### Pitfall 16: AI-generated art -- style drift, fake pixel art, and a reputational risk

**What goes wrong:**
- Style drift across batches: palette, outline weight, light direction, perspective, head-to-body ratio and detail density vary between generations or model versions, so 30+ portraits and dozens of icons do not look like one game.
- "AI pixel art" is usually not pixel art: inconsistent pixel size, anti-aliasing, off-grid, blurred edges; looks wrong when scaled with nearest-neighbor.
- Portrait expression matrix: patrons x expressions (neutral/happy/annoyed/impressed) multiplies the asset count and character identity drifts between expressions.
- Text baked into images, messy transparent backgrounds, hands/props artifacts.
- Mixed pixel densities between UI, portraits and backgrounds (e.g. portrait at 2x, UI at 4x) look amateur.
- A later style change requires regenerating everything.
- Audience risk: cozy/indie/craft communities can react strongly to AI art; Steam requires disclosure of AI-generated content on the store page (verified in Valve's policy coverage), and itch.io has its own AI tagging. Tool terms of service and training-data/copyright questions need documentation.

**Why it happens:**
Generating assets one at a time is easy; enforcing consistency is a pipeline problem, and early prototypes never face the 100-asset test.

**How to avoid:**
- P1 "style lock" spike: pick the rendering target now (recommended: authored at a low native resolution such as 320x180 or 480x270 and scaled by integer factors to 1280x720, or a fixed pixel scale per asset class). Generate 10-12 test assets across all categories (portrait, ingredient, location, UI frame, glass) and only proceed if they cohere.
- Write a style bible: fixed palette (e.g. 32 colors), outline rules, light direction, canvas sizes per asset class, naming scheme.
- Build a deterministic post-process script: downscale to the true pixel grid with nearest-neighbor, quantize to the locked palette, enforce exact canvas sizes, strip anti-aliasing, trim/pad, export to lowercase file names. Every asset passes it.
- Record a manifest per asset (prompt, model/version, seed, source file, post-process version) so assets are reproducible and replaceable.
- Use procedural/layered generation where AI is weak: beer visuals, glasses, tap handles, ingredient icons (tintable templates), UI frames, and expression variation (shared face base with overlay eyes/mouth layers) rather than 4 independent generations per patron.
- Reference all art through logical IDs in a manifest so the entire set can be swapped later (including for commissioned art if the game succeeds).
- Never rely on AI for in-image text; use game fonts.
- Handle disclosure early: mark AI use in the Steam content survey, state it plainly on the store page, and keep generation-tool licensing records. Plan manual cleanup time per asset (budget ~10-20 minutes each) and assign an art-direction review gate.

**Warning signs:**
Palette color count balloons. Two portraits appear to come from different games. A single asset takes multiple regeneration attempts. Sprites look soft when scaled.

**Phase to address:** P1 (style-lock spike and pipeline scripts), P6 (bulk), P7 (disclosure).

---

### Pitfall 17: Licensing/tier and Steam assumptions made at the end

**What goes wrong:**
From the official pages: DragonRuby Standard ($48 one-time) excludes streamlined Steam publishing, C extensions and bytecode compilation; Indie ($96/yr) and Pro ($128/yr) include `dragonruby-publish` Steam upload and C extensions; Standard can still publish to Steam manually through the Steamworks toolchain (steamcmd). PROJECT.md says the user "owns a license" without stating the tier. Steam features beyond upload (achievements, Cloud API, Steam Input integration) were not found in the docs I reviewed [LOW confidence: treat as not provided out of the box and verify what C extensions or Auto-Cloud can cover]. Other end-of-project Steam surprises: store page must exist well before launch (Valve requires a "Coming soon" page live for at least two weeks before release [MEDIUM, from Steamworks guidance, re-verify]), app fee and identity/tax verification, depot/launch option setup, content survey/age-rating questions (alcohol references), capsule/trailer assets, review turnaround, and macOS/Windows/Linux builds that each need real hardware tests.

**Why it happens:**
Store setup looks like release-week administration; engine tier choice looks like a price question.

**How to avoid:**
- P1: confirm license tier; if Standard, decide now whether achievements/cloud/CI automation are worth moving to Indie, or plan manual Steamworks packaging.
- P1: do a throwaway end-to-end Steam test (a hello-world build uploaded to a private/beta branch through steamcmd or `dragonruby-publish`) so depots, launch options (Windows, macOS app, Linux), and 64-bit settings are proven early. Follow `docs/steam-publishing.md` and `docs/guides/deploying-to-steam.md`.
- Start the store page, capsule art, and wishlist funnel around the first externally playable slice (P3 gate or P5), not after P7. Plan a demo build; Steam Next Fest/itch demo is a realistic marketing path for a solo cozy game.
- Treat achievements, trading cards, and cloud as optional stretch; do not promise them in scope until verified.
- Test on Steam Deck/Linux: DR's Steam guide documents building with `dragonruby-publish --only-package` and copying the Linux build to the Deck.
- Content/age rating: the game centers on alcohol; complete Steam's content survey honestly, avoid depicting intoxication as aspirational ("Buzzed"/"Wrecked" statuses are palate/comedy states, not drunk-driving jokes), and note regional alcohol-related store restrictions.

**Warning signs:**
No Steam App ID until late. No one has launched a packaged build on Windows or Linux. A requirement mentions achievements or cloud saves without a technical path.

**Phase to address:** P1 (decision + hello-world publish), P5/P7 (store page, QA, disclosures).

---

### Pitfall 18: Onboarding a 16-attribute deduction game, and last-minute settings/menus

**What goes wrong:**
Players must learn brewing choices, attribute families, clue reading, status effects, and the lineage/collection layer. A text-dump tutorial or a final "tutorial level" bolted on in P7 will not do it. Meanwhile settings (display mode, resolution, volume channels, text speed, key/button remap, accessibility), pause/quit-to-title, save slots, credits, and error handling are routinely left until the end, then rushed.

**How to avoid:**
- Design the first hour as a staged curriculum: first patron = 1 axis (taught by dialogue), then tolerance, then a status, then lineage. Each new concept is introduced by content, not by a popup wall.
- Make the Regulars Book and clue log the persistent "what do I know?" memory aid; require it before shipping the slice.
- Build the settings screen and pause menu in P1 with the UI kit; add settings as features arrive: text speed, skip/fast-forward for dialogue and pour animations (encounters repeat hundreds of times), color-blind-safe icons plus color (beer tints are color-coded), UI scale, and controller remapping.
- Add an in-game glossary ("What is attenuation?") reached from any attribute, reusing the 70% beer-culture content.

**Warning signs:**
First-time testers do not know what to do after the first pour. No pause menu in the slice. Animations cannot be skipped.

**Phase to address:** P1 (menus/settings scaffolding), P3/P5 (curriculum), P7 (QA).

---

## Moderate Pitfalls

### Pitfall A: Hidden randomness undermines deduction and fairness
**What goes wrong:** Per-pour random variance in scoring means clues become unreliable; RNG reseeds on `DR.reset` and is seeded from start time, so replays differ.
**Prevention:** Make encounter scoring fully deterministic; if variation is wanted, derive it from a seed stored in the save (patron_id + visit_count) and keep it outside the clue channel. Use `DR.reset seed:` in tests.

### Pitfall B: Brewing accuracy gaffes in front of a beer-literate audience
**What goes wrong:** Wrong facts (e.g. temperatures, hop timing, yeast behaviors) get called out on forums and in reviews, undermining the 70% culture promise. Over-correction produces simulation bloat.
**Prevention:** Maintain a "rules of thumb" reference doc, review with a homebrewer/BJCP-style reader, favor simplifications that are directionally true, and mark intentionally gamey rules in the UI copy.

### Pitfall C: Trademarked names in content
**What goes wrong:** The design doc uses "Citra," "Nelson," "Untappd Guy," and "Pokemon-style" references. Some hop names are registered trademarks of breeding programs; "Untappd" is a company brand; "Pokemon" in store copy invites takedown.
**Prevention:** Use fictionalized hop/yeast names or generic variety names where marks are claimed, rename the Untappd parody (e.g. a "check-in" app), and avoid brand/IP references in store tags and marketing copy. [MEDIUM, verify before shipping.]

### Pitfall D: Encounter pacing fatigue
**What goes wrong:** A 3-pour encounter repeated hundreds of times becomes tedious if each pour has long animations and dialogue.
**Prevention:** Fast-forward/skip, quick-repeat on losses, short feedback (one line + one icon change), and animation budgets per pour (~2 seconds).

### Pitfall E: Pixel-perfect scaling and resolution
**What goes wrong:** Non-integer scaling blurs pixel art; high-DPI mode is Pro-only per the DR tier list; fullscreen/aspect-ratio behavior on ultrawide and Steam Deck (1280x800) differs from 16:9.
**Prevention:** Lock a logical resolution (DR defaults to 1280x720 logical), design for integer art scales, test letterboxing on 16:10 and ultrawide, and expose fullscreen/borderless/window options in Settings. [VERIFY scale-quality settings in `game_metadata.txt`.]

### Pitfall F: Failure states that punish learning
**What goes wrong:** Losing an encounter costs resources/time, so players avoid experimenting, which is the whole deduction loop.
**Prevention:** Loss = no cost beyond a cooldown or an easy retry; always bank clues; reward partial success.

### Pitfall G: Build/test matrix neglect
**What goes wrong:** Developing on macOS only; Windows path and Linux case-sensitivity bugs, audio encoding warnings, and controller differences appear at release.
**Prevention:** Package all three platforms each phase (DR packages from one machine); keep a Windows machine/VM and a Linux or Steam Deck test target; honor the packager warnings (file names with spaces/capitals, audio encoding).

---

## Minor Pitfalls

### Pitfall a: Hardcoded strings and magic numbers
**What goes wrong:** Dialogue and labels buried in code block future localization and make editing painful.
**Prevention:** Keep text in content data keyed by ID; centralize tuning constants.

### Pitfall b: Naming/typing UX
**What goes wrong:** Beer naming needs text input, which needs a controller path.
**Prevention:** Generated names with re-roll plus an optional on-screen character picker; `DR.start_text_input` for keyboard users.

### Pitfall c: Audio left for last
**What goes wrong:** No sound design until late; pour/clink/cheer feedback is a big part of "juice." The packager warns on incorrectly encoded audio.
**Prevention:** Placeholder SFX in P3; decide audio sourcing (licensed packs, procedural) in P1.

### Pitfall d: API keys and generation tooling in the repo
**What goes wrong:** AI-image service keys or cloud credentials committed accidentally; huge raw generation dumps bloat git.
**Prevention:** Keep keys in env vars; store only curated finals plus the manifest in git; keep raw generations outside the repo.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Serialize all of `args.state` as the save | Save in 5 minutes | Un-migratable saves, UI state in saves, size blowups | Never for the shipped save; ok for a debug quicksave |
| Mouse-only UI, controller "later" | Faster first screens | Rewrite of every screen | Never (violates the stated constraint) |
| Hardcode patron data in Ruby classes | No parser/validator | Cannot run balance matrix; content edits need code | Only the first 3 patrons in P2, migrate by P3 |
| Store derived attributes in saves only | No recompute logic | Balance patches orphan old beers | Never without ruleset_version |
| Style names in patron definitions | Easy authoring | Violates core design constraint; deduction dies | Only for boss gimmicks defined via attribute rules |
| One PNG per asset and per beer permutation | Simple pipeline | Texture cache pressure, huge asset count | Early placeholders only |
| AI assets without manifest/post-process | Fast first batch | Impossible to regenerate/replace consistently | Never beyond the P1 style-lock spike |
| Global `$game` + bare iVars | Quick prototype | Hot-reload stale state, reset bugs | P2 spike only |
| Skip headless tests of simulation | Saves setup time | No solvability/balance verification | Never |
| Add Steam later | More time on gameplay | Depot/launch/tier surprises at ship | Never; do a hello-world publish early |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| DragonRuby file IO | Assuming dev write paths equal production; shared DR install location | Test saves in a production build (`metadata/dragonruby_production_build`); one clean DR copy per game inside the repo |
| Steam (`dragonruby-publish`) | Assuming Standard tier includes it; forgetting depots/launch options per OS; Steam Guard in automation | Confirm tier (Indie/Pro for streamlined publish), follow `steam_metadata.txt` setup, do a hello-world upload early, use steamcmd auth tokens |
| Steam Cloud/achievements | Planning them without an engine path | Verify C-extension/Auto-Cloud routes; treat as optional |
| Steam Deck | Keyboard glyphs while controller active, no text-entry path, small text | Active-device glyphs, controller-only text entry, legible font sizes, test via `--only-package` Linux build on a Deck |
| itch.io | Wrong viewport/embed settings for web, missing AI disclosure | Follow DR itch guide (1280x720 viewport); apply AI tags |
| AI image generators | Mixing models/versions mid-project; no seeds saved | Pin tool+version, store prompts/seeds in manifest, deterministic post-process |
| Controller hardware | Assuming Xbox layout | Use `accept`/`cancel` and cardinal names; test an Xbox, PlayStation, Switch Pro and the Deck |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Array primitives, per-tick object churn | Frame time creep | Hash primitives, bulk `<<`, class-level `Array.map` helpers per DR guide | Thousands of primitives per frame |
| Animated label `size_px`/`size_enum` | Glyph cache growth, hitches | Render-target scaling for text | Any scaling animation across many sizes |
| Too many distinct textures | Load hitches when entering screens | Atlas/sprite sheets, tinted layers, lazy loading | Past roughly 2048 cached textures (7.8 changelog) |
| Rebuilding text layout every tick | CPU spikes in Regulars Book/recipe list | Cache in render targets, invalidate on change | Lists of 30-50+ entries with wrapped text |
| Brute-force scoring in UI thread | Lag when previewing every beer vs every patron | Memoize attribute vectors per recipe, precompute heatmaps offline | 100+ recipes x 40+ patrons if computed live |
| Large save state | Slow autosave stutter or "too large" serialization | Save only the minimal data layer, autosave off the hot path | Thousands of keys (engine tests flag ~3000) |
| Particle-heavy pour effects | Steam Deck frame drops | Budget particles, prefer sprite animation | Low-power Linux targets |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Committing Steam credentials or AI service keys | Account compromise | Env vars; steamcmd handles auth (DR never sees credentials) |
| Treating the save file as trusted | Crash/corruption on load; modders produce invalid state | Validate on load (schema, ID existence, ranges), fail gracefully |
| Leaving the in-game HTTP server/dev tools enabled in production | Exposed dev surface | Check `DR.production?` gates; build with production marker |
| Distributing the DragonRuby engine in a public repo | License violation | Keep repo private [VERIFY license terms] |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| 16 numbers on every screen | Cognitive overload, spreadsheet feel | Families, top-3 traits, radar glyph; drill-down for numbers |
| Exact score breakdowns after each pour | Puzzle solved instantly | Bucketed clues, one or two facts per pour |
| No visible knowledge log | Players forget what they learned and give up | Regulars Book with confirmed/inferred clues, always accessible |
| Hover-only tooltips | Controller users blind | Focus-driven help panel |
| Unskippable animations/dialogue | Fatigue during repeated encounters | Skip/fast-forward, text speed |
| Color-only status/beer differentiation | Inaccessible | Icons + labels + color |
| Failure that costs progress | Players stop experimenting | Fail-forward with banked clues |
| Overwhelming recipe archive | Cannot find beers | Favorites, tags, sort/filter, lineage view, compare screen |

## "Looks Done But Isn't" Checklist

- [ ] **Encounter system:** Often missing win/loss clue persistence -- verify losing still updates the Regulars Book.
- [ ] **Brewing system:** Often missing preview/attribution -- verify a player can predict the effect of changing yeast or mash temp.
- [ ] **Patron content:** Often missing solvability proof -- verify the headless harness shows each patron is beatable via clues in the pour limit and not by style-only play.
- [ ] **Status effects:** Often missing visibility and expiry rules -- verify icon, rule text and counters exist.
- [ ] **Save system:** Often only tested in dev -- verify save/quit/relaunch/load in a production build on all three OSes, plus corrupt-save recovery and version migration.
- [ ] **Controller support:** Often missing text entry, tooltips, scroll lists -- verify every screen is completable with a gamepad only and with keyboard only.
- [ ] **Settings:** Often missing remap/persistence -- verify settings survive restart and corrupted saves.
- [ ] **Lineage:** Often missing parent link on the very first brew -- verify ancestry is written for every recipe including edited ones.
- [ ] **Art:** Often inconsistent in palette/pixel scale -- verify all assets pass the post-process script and appear coherent in a contact-sheet review.
- [ ] **Packaging:** Often unverified on Windows/Linux/Deck -- verify clean-machine launch, file-name case, audio, and resolution behavior.
- [ ] **Steam:** Often missing store page time, depots, content survey, AI disclosure -- verify the release checklist is complete weeks before launch.
- [ ] **Balance:** Often unmeasured -- verify the matrix report shows distinct best-in-class beers and no dominant recipe.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Core loop not fun after gate | HIGH | Stop content work; iterate the scoring/clue model with the harness; cut features; re-gate |
| Stat soup UI | MEDIUM | Introduce attribute families and glyphs; re-skin screens using the UI kit |
| Style-matching deduction | MEDIUM-HIGH | Remove style references from patron data; rebuild palettes by axes; re-run solvability harness |
| Dominant recipe | MEDIUM | Add budget/penalty asymmetry; retune with the matrix; patch Crowd Pleaser |
| Mouse-first UI needing controller | HIGH | Introduce the intent layer and focus manager; rewrite screens screen by screen; slow but doable if UI kit exists |
| Save format without versioning | HIGH | Introduce `save_version`; write a one-time migration for the existing format; ship before launch |
| Recipes mutable / no lineage | HIGH | Add parent IDs retroactively (lineage lost for existing data); migrate saves |
| AI art style drift | MEDIUM-HIGH | Lock a palette and post-process, regenerate the outliers; accept consistent "simple" over inconsistent "detailed"; swap via manifest |
| Texture/perf issues | MEDIUM | Atlas assets, tint layers, render-target caching |
| Steam/tier surprise | MEDIUM | Upgrade license tier or switch to manual steamcmd; start store page immediately |
| Scope creep into management | MEDIUM | Reaffirm Out of Scope list; remove subsystems; keep perk types closed |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| 1. Full game before core proven | Roadmap, P3 gate | Outsider playtest meets the design doc's success criteria before P4+ begins |
| 2. Stat soup | P2, P3 | 5-second glance test passes; brew screen <=7 live controls |
| 3. Deduction failure modes | P2, P3, P5 | Solvability harness thresholds; no style IDs in patron data; clues persist after loss |
| 4. Dominant beer / no tooling | P2 | Matrix report: >=4 distinct best-in-class beers in a 6-tap lineup |
| 5. Status effects | P2, P3, P5 | Order-delta metric; icon+rule visible; staged introduction |
| 6. Black-box brewing | P2, P3 | Testers predict outcomes of changes; causal tags shown |
| 7. Content explosion | P2 (format), P4/P5 | Content budget locked; validator in CI; template dialogue in use |
| 8. Collection with no pull | P4, P6 | Mutation forks; Regulars tiers derived from play; beer identity cards |
| 9. Lineage/save evolvability | P1, P2, P7 | Immutable recipes, stable IDs, ruleset_version, migration test |
| 10. Management scope creep | Roadmap, P4, P5 | Closed perk-type list; exploration form decision recorded |
| 11. UI kit | P1 | Kit supports focus, lists, grids, modals, wrap before first feature screen |
| 12. Input abstraction | P1 and continuous | Gamepad-only and keyboard-only completion test each phase |
| 13. Save design | P1, P2, P7 | Round-trip tests, production-build save test, corrupt-save recovery |
| 14. Dev-mode illusions/mruby | P1 | Cold-start smoke test; stdlib spike results documented |
| 15. Performance | P1, P6 | Frame-time budget; asset atlas plan; Deck test |
| 16. AI art consistency | P1, P6, P7 | Style-lock gate; post-process script; manifest; disclosure complete |
| 17. License/Steam assumptions | P1, P5, P7 | Hello-world Steam upload; store page timing; tier decision |
| 18. Onboarding/settings | P1, P3, P5, P7 | Fresh-player test; settings persisted; skip/fast-forward present |

## Sources

- DragonRuby docs repo (v7.9): `docs/guides/troubleshoot-performance.md`, `docs/api/state.md`, `docs/api/inputs.md`, `docs/api/runtime.md`, `docs/steam-publishing.md`, `docs/guides/deploying-to-steam.md`, `docs/changelog.txt` (texture cache limit in 7.8, Deck framerate fix in 7.7, packager warnings in 7.6). https://github.com/DragonRuby/dragonruby-game-toolkit-contrib -- HIGH
- DragonRuby docs `index.txt` (older bundled docs): serialization samples (`serialize_state`/`deserialize_state`, `serialize`/`inspect`/`to_s` on classes, large-state test) -- MEDIUM (older doc version; re-verify in the installed version)
- DragonRuby license tiers and pricing: https://dragonruby.org/toolkit/game -- HIGH (as of fetch date)
- DragonRuby devlog on Steam distribution: https://dragonruby.itch.io/dragonruby-gtk/devlog/542709/mid-year-update-quacks-steam-distribution-sound-synthesis-and-pixel-arrays -- MEDIUM
- DragonRuby community notes on mruby limits (no gems/require): itch.io forum threads surfaced by search -- LOW-MEDIUM
- Steam AI content disclosure policy (pre-generated vs live-generated, shown on store page): coverage at https://www.theregister.com/2024/01/10/developers_steam_ai/ and https://www.pcgamesn.com/steam/ai-content-reporting -- MEDIUM
- Steam Deck Verified requirements (glyphs, controller-only text entry, default config, legibility): https://partner.steamgames.com/doc/steamdeck/compat -- MEDIUM
- Genre/design pitfalls (stat soup, deduction information budgets, dominant strategies, content treadmills, collection-system attachment, solo-dev scope): synthesis from the project design doc `brewfighter-design-v1.md` and general genre knowledge -- MEDIUM; not independently sourced
- Steam "coming soon" page lead time, app fee, content survey process: Steamworks guidance recalled from prior knowledge -- MEDIUM, re-verify before launch planning

---
*Pitfalls research for: collectible brewing RPG in DragonRuby GTK (commercial solo release)*
*Researched: 2026-10-06*
