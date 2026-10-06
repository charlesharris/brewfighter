# Stack Research

**Domain:** Commercial 2D pixel-art collection/tactics RPG with a lightweight brewing simulator (DragonRuby GTK, desktop: Steam + itch.io, Mac/Windows/Linux)
**Researched:** 2026-10-06
**Overall confidence:** MEDIUM-HIGH (engine facts read directly from the official DragonRuby source/docs mirror; art-tool and store-policy facts come from web sources and are tagged lower)

Confidence legend: HIGH = read in official engine docs/source or changelog; MEDIUM = cross-checked across multiple web sources; LOW = single web source or inference. Per the project's classify-confidence seam, unverified web search results are LOW and cross-checked web results are MEDIUM.

---

## Decisions the Roadmap Must Resolve First

1. **Which DragonRuby license tier does the user own?** This changes the Steam path. (HIGH/MEDIUM)
   - Standard ($48 one-time): desktop and web export, itch.io publishing. Can ship to Steam, but only by running the Steamworks toolchain (steamcmd/SteamPipe) by hand. No C extensions, so no Steamworks achievements or cloud API.
   - Indie ($96/yr): adds turnkey Steam publishing through `dragonruby-publish`, C extensions, and bytecode compilation (`compile_ruby`).
   - Pro ($128/yr): adds High DPI, mobile, early-access features (shader work is queued for Pro first).
   - **Recommendation:** develop on whatever is owned. Budget for Indie before the packaging phase. It automates the repetitive part of Steam release and is the only tier where Steam achievements are possible.
   - There is also a free **Jam** tier (August 2026, web export only). It is irrelevant for this project.
2. **Pin the engine version.** The newest version seen is **7.10** (contrib repo commit of 2026-06-14, docs `version.txt` shows 7.9). 7.0 was an SDL3 epoch bump with no breaking changes. Check with `./dragonruby --version` after downloading and record it in `.planning`. (HIGH for 7.x; the exact latest may be newer.)
3. **Pick the pixel grid before any art is generated.** Recommended: a 1280x720 logical screen, art authored at 1/4 scale (a 320x180 pixel canvas drawn at integer 4x). See Rendering below. (MEDIUM, this is a design decision, not a verified fact.)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| DragonRuby GTK | 7.x (latest seen 7.10) | Engine, runtime, packaging | Fixed choice. Zero dependencies, hot reload, in-game console, record/replay, one-command Win/Mac/Linux packaging. 255+ releases in 7 years with one breaking change (2021), which makes it stable for a multi-month build. | HIGH |
| DragonRuby runtime (mruby-based "Ruby") | bundled | Game and simulation code | No gems and no Bundler. Treat it as mruby, not CRuby 3.x: spike any language or stdlib feature in the console before depending on it. | HIGH |
| `module Main` entry convention | 7.4+ | Entry point | `module Main` with `boot`, `start`, `tick`, `reset`, `did_reset`, `shutdown`. `args`, `inputs`, `outputs`, `state`, `audio` are available without passing `args`. Avoids polluting `Object` with bare top-level `tick`. | HIGH |
| Scene stack (in-repo, ~100 lines) | n/a | Menus, map, brewing, encounters, modals | No maintained library fits (see Alternatives). Samples are monolithic `tick` functions. A small push/pop/replace manager with `enter/exit/update/render` is cheap and fully testable. | MEDIUM |
| Intent-based input layer (in-repo) | n/a | Mouse + keyboard + controller | Wrap `args.inputs` into semantic actions (`:confirm`, `:cancel`, `:up`, `:down`, `:tab_next`, `:pointer`). Built on `inputs.last_active`, `controller.accept/cancel`, and `inputs.key_down.*`. | HIGH |
| Built-in test runner | bundled | Unit tests for brewing/scoring/palate logic | `./dragonruby mygame --test <file>`: methods named `test_*(args, assert)`, with `assert.true!/false!/equal!/not_equal!/nil!/ok!`. Runs under `--no-tick` so it works headless. Runs the same mruby runtime as the game, so there are no CRuby-vs-mruby surprises. | HIGH |
| Ruby hash-literal content files | n/a | Beers, ingredients, yeasts, patrons, bosses, locations | Hot-reloadable, comment-friendly, symbols, no parse step, no eval. A validator test checks references and value ranges. Modding is out of scope, so "content as code" is acceptable. | MEDIUM |
| JSON save files with in-repo encoder | n/a | Save/load | `DR.serialize_state` is `Hash#to_s` and `deserialize_state` evals Ruby text, and it warns above 20,000 characters. Prefer an explicit schema-versioned JSON snapshot. Read with `DR.parse_json_file` (native). Write with a ~50-line encoder, because only `parse_json` was found in the engine source mirror. | MEDIUM |
| `dragonruby-publish` | bundled | Packaging for itch.io and Steam | `--only-package` builds Win/Mac/Linux into `./builds`. Publishes to itch.io automatically (Standard and up). Uploads to Steam through steamcmd (Indie/Pro only). | HIGH |

### Rendering and Pixel-Art Settings

| Setting | Value | Why | Confidence |
|---------|-------|-----|------------|
| Logical resolution | 1280x720 | Engine native grid. HD scaling to 1080p/1440p/4K works on all tiers since 7.x. | HIGH |
| `metadata/game_metadata.txt` `scale_quality` | `3` (pixel-art scaling, added in 7.0) | Crisp pixels at any window size or fullscreen. 0 is plain nearest-neighbor; 1/2 are linear (blurry for pixel art). Sprites and labels also accept `scale_quality_enum: 3`. | HIGH |
| Art grid | Author at 1x (e.g., 320x180 canvas), draw at integer 4x | Keeps AI output, hand cleanup, and UI on one grid so scaling stays integer. Portraits about 64x64 drawn at 256 px; beer glass about 32x48; ingredient icons 16x16 or 32x32. | MEDIUM |
| Layout | `Layout.rect(row:, col:, w:, h:)` safe-area grid | Built-in grid for menus and JRPG-style panels. See the `99_genre_jrpg` and `09_ui_controls/02_menu_navigation_advanced` samples. | HIGH |
| `highdpi` | Do not depend on it | Pro only. With `scale_quality=3` and integer art it is unnecessary. | HIGH |
| Texture atlases | Not needed | HD atlases are Pro only and give no benefit at this art scale. The texture cache holds 2048 entries (7.8). | HIGH |

### Beer Visuals: Procedural, Not Generated

Render beers by layering tinted sprites: glass outline, liquid fill tinted with `r/g/b` from an SRM-to-RGB lookup, foam-head layer (height/color from head attribute), and a small bubble animation tied to carbonation. DragonRuby sprites accept `r,g,b,a` tint and blend modes. Result: any recipe the player invents gets a unique, consistent visual with zero per-beer art. This is the highest-value use of the "procedural art" constraint. (MEDIUM, design recommendation using HIGH-confidence engine features.)

### Supporting Code to Build In-Repo (not installed)

| Module | Purpose | When Needed |
|--------|---------|-------------|
| `Sim::Rng` (seeded PRNG stored in save) | Reproducible brewing noise, yeast mutation, encounter rolls, tests, and replays | Phase 1. DragonRuby made RNG stable for replays in 7.6, but a game-owned PRNG whose state is saved is more robust for mutation lineage. |
| `Sim::Attributes` (fixed-order 16-attribute vector) | Brewing output and palate matching share one data shape | Phase 1 |
| `Content::Registry` + `Content::Validator` | Load content hashes; test that every reference resolves, every attribute is in range, every patron has 3-5 likes and 1-3 dislikes | Phase 1 |
| `Scenes::Manager` | Scene stack with transitions and modal layers | Phase 1 (before any UI) |
| `Input::Intents` + `Input::Prompts` | Semantic actions plus glyph prompts that switch on `last_active` | Phase 1 (before any UI) |
| `Ui::Focus` | One focus model: controller/keyboard move focus, mouse hover sets focus, click activates | With first menus. Hide the cursor with `DR.hide_cursor` when `last_active == :controller`. |
| `Save::Json` + `Save::Migrations` | Encode, schema version, migration chain, slots, backup | Before the first playable loop is called "done" |
| `Lineage` (flat list with `parent_id`) | Recipe ancestry as IDs, never object references | Phase 1. Keeps saves trivially serializable. |

### Asset Pipeline Tools

| Tool | Version | Purpose | Notes | Confidence |
|------|---------|---------|-------|------------|
| PixelLab | Subscription (about $12-50/mo) | Primary generator: character/patron portraits, 4/8-direction sprites, tilesets, UI; Aseprite extension plus API/MCP | Pick ONE primary generator for style coherence. A subscription can be paused once the asset library exists. Verify commercial terms on the tier you buy. | MEDIUM |
| Retro Diffusion (Aseprite extension) | $20 Lite / $65 full, one-time | Local alternative: icons, tiles, portraits. Outputs are owned by the creator. | Needs a capable GPU. Choose this if you want no subscription. | MEDIUM |
| Aseprite | about $19.99 | Manual cleanup, palette locking, slicing, animation sheets; CLI (`aseprite -b`) for batch export | The pipeline's manual finishing stage. Not installed on this machine. | MEDIUM |
| proper-pixel-art (`ppa`) | pip, MIT | Recover true pixel grid from AI output; quantize colors; transparent background | `ppa in.png -o out.png -c 32 -t`. Run in a uv-managed venv. | MEDIUM |
| unfake | 1.0.7 (Oct 2025), MIT, Python 3.10+ | Same job, with scale detection, Wu quantization, grid snapping | Pick one of `ppa` or `unfake` after a bake-off on real output. | MEDIUM |
| Fixed master palette (about 32 colors) | n/a | Force every asset onto one palette | The strongest single lever for AI-art consistency. Choose before generating. | MEDIUM |
| ffmpeg | current stable | Re-encode audio to 44.1 kHz stereo Ogg Vorbis | `dragonruby-publish` warns on bad encoding (7.6). Not installed on this machine (`brew install ffmpeg`). | HIGH |
| sfxr-family tool (e.g., ChipTone/jsfxr) or DragonRuby sound synthesis | n/a | UI blips, pour/clink sounds | `args.audio` accepts `[channels, sample_rate, float_array]` input for procedural audio. Synthesis did not work on web builds in 7.3, which is irrelevant for desktop. | HIGH |

**Art provenance manifest:** keep `art/manifest.json` recording tool, version, prompt, seed, source file, and date for every asset. It supports regeneration, store-page AI disclosure, and any later licensing question. (MEDIUM)

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| In-game console + hot reload | Fast iteration | `./dragonruby mygame`. `repl.rb` for scratch code; `DR.reset` or Ctrl+R to reset state. |
| `--record` / `--replay` | Regression and smoke tests for UI flows | `./dragonruby mygame --record`, `--replay last_replay.txt`. Pair with the seeded PRNG so replays stay deterministic. |
| `bin/test` shell wrapper | CI-friendly test run | The runner only logs a summary and the exit code on failure was not verified. Run each test file and grep for `N test(s) failed` to set a nonzero exit code. On Linux CI, use `xvfb-run` if the engine needs a display (verify on first CI run). |
| `bin/package` shell wrapper | Reproducible builds | Wraps `./dragonruby-publish --only-package`. |
| Python 3 + uv (present: Python 3.14.3, uv installed) | Art processing scripts | Keep tooling outside `mygame/`. Host Ruby (3.4.4 via rbenv) is optional for a Rakefile and must never be used to run game code (mruby is the target). |
| Git, whole DragonRuby directory committed | Reproducibility | Officially recommended for commercial games ("shelf life"). |

---

## Recommended Project Structure

```
brewfighter/                  # repo root == unzipped DragonRuby directory (binary beside mygame/)
  dragonruby, dragonruby-publish, ...   # committed in private repo
  mygame/
    app/
      main.rb                 # module Main: boot/start/tick/reset
      scenes/                 # title, world_map, brewing, tap_list, encounter, regulars_book, yeast_bank...
      sim/                    # PURE logic: brewing, attributes, scoring, status effects, patron memory, rng
      content/                # hash-literal data: hops, grains, yeasts, adjuncts, patrons, bosses, locations
      ui/                     # focus model, widgets, panels, 9-slice helper, theme
      input/                  # intents, prompts, rebinding
      save/                   # json encoder, migrations, slots
      audio/                  # sound/music manager
    tests/                    # test_*.rb (excluded from packages via ignore_directories=tests)
    sprites/ sounds/ fonts/ data/ metadata/
  art/                        # source/raw AI output, manifest.json, palette (NOT shipped)
  tools/art/                  # python scripts: process, quantize, slice, export
  bin/                        # test, run, package
  .planning/
```

Rules: `sim/` and `content/` never touch `args` or rendering. Scenes only translate intents into sim calls and draw sim results. This keeps the entire core loop (brew, serve, learn) testable without the engine's frame loop. (MEDIUM, architecture recommendation.)

**Save format sketch:** `{ "schema": 1, "rng": {...}, "inventory": {...}, "recipes": [ {id, parent_id, ...} ], "yeast_bank": [...], "regulars": {...}, "taps": [ids], "progress": {...} }`. Use IDs, not object references. Keep three files per slot (`slot_1.json`, `slot_1.json.bak`, and a write-then-verify step), because the file API has no atomic rename. Autosave after each brew and encounter.

**Steam Cloud:** Steam Auto-Cloud needs no SDK integration and supports `WinAppDataRoaming`, `MacAppSupport`, and `LinuxXdgDataHome` roots. These match DragonRuby's sandboxed write directories (Windows `AppData/Roaming/[devtitle]/[gametitle]`, Mac `~/Library/Application Support/[gametitle]`, Linux `~/.local/share/[gametitle]`). (HIGH for both halves.) **Set `devtitle`/`gametitle` in `game_metadata.txt` before the first save format ships.** Renaming later moves the save location.

---

## Installation

```bash
# DragonRuby: download the zip from https://dragonruby.itch.io/dragonruby-gtk (license holder)
# Unzip INTO the repo root so the `dragonruby` binary sits beside ./mygame, then:
./dragonruby --version          # record the version in project notes
./dragonruby mygame             # run with hot reload

# Tests (run from repo root; verify the path form on first run)
./dragonruby mygame --test tests/all_tests.rb --no-tick

# Package all desktop targets
./dragonruby-publish --only-package

# Asset tooling (host)
brew install ffmpeg
uv venv tools/art/.venv && uv pip install --python tools/art/.venv/bin/python proper-pixel-art unfake pillow
# Aseprite: purchase/install separately; CLI batch export via `aseprite -b`
```

`.gitignore` adjustments for the existing Ruby-template file: add `/logs/`, `/builds/` (artifacts are large), `/art/.cache/`, `tools/art/.venv/`. Keep `/tmp/` ignored. Keep the DragonRuby binaries, `docs/`, and `samples/` committed (private repo). Never make the repo public with the binaries. (HIGH for the DR guidance; ignoring `/builds/` is a project-level deviation from the DR default, made to avoid repo bloat.)

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Own scene stack | Draco + draco-scenes (ECS) | Not recommended: last pushed March 2021. This game is data- and UI-heavy rather than entity-heavy. |
| Own scene stack + UI | Zif (`danhealy/dragonruby-zif`, 122 stars) | Last release 2.3.1 (Aug 2023), last push March 2025. Opinionated sprite/action framework. Read for ideas and borrow patterns, but do not adopt wholesale. |
| Own scene stack | Scale (`DragonRidersUnite/scale`) | Last push May 2024. Reference only. |
| Hash-literal content | JSON content files via `DR.parse_json_file` | Choose JSON only if non-programmers must author content. It adds string-key handling and a loss of comments. |
| JSON saves (own encoder) | `DR.serialize_state` / `deserialize_state` | Fine for dev quick-save while prototyping. Not for shipped saves (eval on load, 20K-char warning, engine-defined format). |
| Built-in `--test` runner | CRuby + minitest/rspec on host | Faster tooling, but code would be tested on a different runtime than the one shipped. Revisit only if the runner becomes a bottleneck. |
| PixelLab primary | Retro Diffusion (local, one-time) | Prefer when you want zero subscription and own a suitable GPU. |
| PixelLab primary | Scenario / Layer (custom-trained style models) | Prefer if a style-consistency bake-off shows PixelLab drifting across hundreds of assets. |
| Indie tier for Steam | Standard + manual Steamworks/steamcmd | Acceptable if you accept hand-built SteamPipe uploads and no achievements. |
| Native `args.inputs` | SDL/Steam Input integration via C extension | Only if native controller handling proves inadequate on Steam Deck. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Gems / Bundler / `Gemfile` | The runtime has no gem support. | Vendor code into `mygame/app` or `lib/`. |
| Bare top-level `tick`/`boot`/`reset` | Pollutes `Object`; hard to scale | `module Main` |
| Bare instance variables outside classes for state | Pollutes global space, not cleared by `DR.reset` | Classes with an explicit `reset`, or `args.state` |
| Array primitives (`args.outputs.sprites << [..]`) | Slower and deprecated style | Hash primitives; audit with `DR.warn_array_primitives!` |
| Lerping label `size_px`/`size_enum` | Each size caches a full glyph set | Render targets for scaled text animation |
| `scale_quality` 1 or 2 | Blurs pixel art | `3` (pixel-art), or `0` for strict nearest-neighbor |
| Shipping `DR.serialize_state` output as the save format | Eval-based load, 20K-char warning, engine-owned format | Versioned JSON snapshot |
| Mixing several AI art generators without a master palette | Style drift is the dominant visual-quality failure | One primary generator, one palette, a processing pass |
| Hand-drawing every beer sprite | Unbounded asset count; recipes are player-made | Procedural layered/tinted glass rendering |
| Depending on Pro-only features (`highdpi`, atlases, shaders) | Locks the project to the top tier | Integer art + `scale_quality=3` |
| Keeping DragonRuby in a shared location | File access is sandboxed beside the binary | A clean copy committed per game |

## Stack Patterns by Variant

**If the license is Standard:** develop and ship itch.io builds with `dragonruby-publish`. For Steam, follow Valve's SteamPipe docs and use steamcmd manually. Skip achievements and plan a tier upgrade before store launch.

**If the license is Indie or Pro:** fill in `metadata/steam_metadata.txt` (`steam.publish`, `steam.appid`, per-OS depot IDs, `steam.branch=staging`) and push to a passworded staging branch on every release candidate. Promote to `default` manually in Steamworks.

**If the generator is subscription-based (PixelLab):** batch-generate for one month, run the processing pipeline, commit finished PNGs plus the manifest, then pause the subscription.

**If controller-only play must be perfect (Steam Deck):** drive all focus through `Ui::Focus`, show glyph prompts from `last_active`, and avoid hover-only affordances. Recipe naming needs a controller-friendly path (word-picker or on-screen character grid) because `args.inputs.text` expects a keyboard. (MEDIUM)

## Version Compatibility

| Item | Compatible With | Notes |
|------|-----------------|-------|
| DragonRuby 7.x | SDL3 (3.4.4 in 7.0), Emscripten 5.0.4 for web | C extensions must be recompiled when crossing 7.0. Irrelevant unless Steamworks is wrapped. |
| `scale_quality=3` | DragonRuby 7.0+ | Not available on 6.x. |
| `controller.accept/cancel`, button aliases, `Main` scoping | 7.4+ | Handles the Switch Pro A/B swap. Use cardinal aliases (`south/east/west/north`), not `a/b/x/y`. |
| `dragonruby-publish` audio warnings | 7.6+ | Re-encode audio to 44.1 kHz stereo Ogg. |
| HD mode on Standard/Indie | 7.3+ bugfix ensures `hd=true` is respected | The 7.0 changelog states HD is available at all tiers, but the docs table still labels `hd` as Pro. Test on the owned tier. |
| Steam macOS depots | Windows 64-bit, macOS Intel + Apple Silicon, Linux/SteamOS 64-bit | Per DragonRuby's Steam guide. Raspberry Pi/arm64 Linux builds cannot publish to Steam. |
| Art tools | Python 3.10+ (unfake), uv | Host has Python 3.14.3 and uv. |

## Gaps and Items Needing Phase-Level Research

- **macOS code signing/notarization and Gatekeeper behavior for Steam-delivered builds:** nothing found in DragonRuby docs. (LOW) Research during the packaging phase.
- **Steamworks achievements/cloud API via C extension:** only a sample wrapping `Init` and `GetUserName` exists (macOS build script only). Treat achievements as optional for v1.
- **Test-runner exit code and headless CI behavior:** unverified. Confirm on the first CI run.
- **Exact test file path form** (`tests/...` vs `app/...` vs repo-relative) appears inconsistently across docs and community notes. Confirm on first run.
- **Whether the shipped engine includes a JSON encoder:** none found in the contrib mirror (which omits `oss/`). Grep the downloaded zip for `to_json` before writing `Save::Json`.
- **mruby feature coverage** (`Struct` is confirmed; `Data.define`, `Set`, pattern matching are not): spike before use.
- **AI-art commercial terms and Steam disclosure:** Valve requires disclosing AI-generated pre-generated content on the store page (policy since January 2024). Read each generator's current commercial terms, and consider that purely AI-generated art may have weak copyright protection. Confirm with counsel before launch. (MEDIUM/LOW)
- **License subscription terms for Indie/Pro:** confirm what happens to shipped builds and updates if a subscription lapses.
- **Font choice:** select an OFL-licensed pixel font with full glyph coverage and verify readability at 720p and 1280x800 (Steam Deck).

## Sources

- DragonRuby contrib repository (docs, changelog, source, samples), read directly via the GitHub API: https://github.com/DragonRuby/dragonruby-game-toolkit-contrib (HIGH). Files used: `docs/changelog.txt`, `docs/guides/deploying-to-steam.md`, `docs/guides/deploying-to-itch.md`, `docs/guides/starting-a-new-project.md`, `docs/api/{inputs,audio,state,cvars,runtime,layout}.md`, `docs/misc/faq.md`, `dragon/tests.rb`, `dragon/runtime/{process_argsv,save_state_load_state}.rb`, `samples/10_advanced_debugging/03_unit_tests`, `samples/12_c_extensions/07_handcrafted_steam_extensions`.
- DragonRuby license tiers: https://dragonruby.org/toolkit/game and https://dragonruby.itch.io/dragonruby-gtk (MEDIUM, cross-checked with the Steam guide and 2023 mid-year devlog "Turnkey Steam Distribution is an Indie/Pro feature").
- DragonRuby devlogs: https://dragonruby.itch.io/dragonruby-gtk/devlog (7th-year post, April 2026; v6.0 post; Jam license, August 2026) (MEDIUM).
- Steam Auto-Cloud: https://partner.steamgames.com/doc/features/cloud (HIGH).
- Steam AI disclosure policy summaries: https://gamefromscratch.com/steam-makes-massive-update-to-ai-generation-policy/ and related search results (MEDIUM; read Valve's current Steamworks documentation before launch).
- AI pixel-art tool comparison (Sept 2026): https://app.cinevva.com/guides/ai-pixel-art-generators; PixelLab: https://www.pixellab.ai/ (pricing page not retrieved); Retro Diffusion extension listings on itch.io/Gumroad (MEDIUM/LOW).
- Pixel cleanup tools: https://github.com/KennethJAllen/proper-pixel-art (MIT) and https://pypi.org/project/unfake/ (1.0.7, MIT) (MEDIUM).
- Community libraries checked for maintenance status via the GitHub API: guitsaru/draco, guitsaru/draco-scenes, danhealy/dragonruby-zif, DragonRidersUnite/scale (HIGH for dates, which are factual repo metadata).
- Host environment check: macOS arm64, Python 3.14.3, uv present, Ruby 3.4.4 (rbenv), ffmpeg and Aseprite not installed.

---
*Stack research for: commercial DragonRuby GTK pixel-art collection/tactics RPG (Brew Fighter)*
*Researched: 2026-10-06*
