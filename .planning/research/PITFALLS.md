# Domain Pitfalls

**Domain:** Collectible brewing RPG (collection + matchup deduction + crafting sim), native Swift/SwiftUI, iPhone portrait, solo dev, commercial App Store release, AI-generated flat/cartoon art, alcohol-themed
**Researched:** 2026-10-08 (replaces the obsolete 2026-10-06 DragonRuby/Steam version; game-design pitfalls carried forward and re-expressed for iOS)
**Overall confidence:** MEDIUM-HIGH. App Review, age-rating, TestFlight and SDK-deadline facts were read from Apple's own pages this session (see Sources). Note: the pages were fetched through a summarizing tool, so the seam rates that provider LOW by default. I upgraded to MEDIUM only where the extracted text matched Apple's guideline wording and a second source. Re-read the guideline text itself at submission time. Items tagged [VERIFY] could not be confirmed and must be checked in the phase named.

**Confidence tags used below:** [HIGH] Apple primary doc, matches second source. [MED] Apple doc via summarizer, or credible secondary source. [LOW] Community report or inference. [VERIFY] Unresolved, check before depending on it.

**Phase labels used below** (capability-based, because ROADMAP.md is still the obsolete DragonRuby version and will be regenerated; map by capability, not number):

| Label | Capability |
|-------|------------|
| P1 Foundations | Xcode project, Apple Developer enrollment, app record + name reservation, domain core as a pure Swift package, save envelope, TestFlight pipeline, SwiftUI shell + UI kit, art style-lock spike |
| P2 Deduction Core | Headless scoring/clue/status model, balance + solvability harness, attribute families |
| P3 Slice + Gate | Recipe iteration, saves, live preview, lineage, **TestFlight outside-playtest fun-gate** |
| P4 Collections | Ingredients, yeast bank, mutation, family tree, beer cards |
| P5 City + Economy | Node map, regulars, bosses, **monetization decision executed (economy)** |
| P6 Art + Polish | Bulk art, audio, haptics, onboarding, accessibility pass, settings |
| P7 Release | Privacy/metadata, age rating, screenshots, App Review cycles, launch |

---

## Critical Pitfalls

### Pitfall 1: The age rating is treated as end-of-project paperwork, but it shapes design, reach, and rejection risk

**What goes wrong:** Alcohol is the *core loop* here (brew it, serve it, ABV is an attribute, statuses include "Buzzed"). The App Store age-rating questionnaire asks about "Alcohol, Tobacco, or Drug Use or References" at None / Infrequent / Frequent. Per Apple's definitions, Infrequent maps to **13+** and Frequent maps to **18+** [HIGH]. Apple's own descriptor definition explicitly includes "drunken behavior." Developers either (a) answer "Infrequent" to land at 13+ (one real brewery game, Brewery Boss, shows 13+ with "Infrequent" [MED]) and then ship a game whose entire premise contradicts the answer, or (b) discover 18+ consequences late.

**Why it happens:** The old 12+/17+ scheme was replaced by 4+/9+/13+/16+/18+ in the iOS 26 generation. Developers had to re-answer the questionnaire by 2026-01-31 or be blocked from submitting updates [HIGH]. People remember "17+" and don't re-check. Also guideline 2.3.6 requires honest answers and warns a mis-rated app "could trigger an inquiry from government regulators" [HIGH].

**Consequences of 18+ you must plan for (not reasons to dodge it):**
- Since 2026-02-24, unverified users in **Brazil, Australia and Singapore** cannot download 18+ apps; Utah (2026-05-06) and Louisiana (2026-07-01) began age-signal sharing for new accounts [MED].
- Texas SB2420 (app store age assurance) was enjoined, then the Fifth Circuit administratively stayed the injunction on 2026-05-28, so the law is in an unstable enforcement state [MED]. Whether an 18+ app must call the Declared Age Range API to be compliant is unclear; developers are reading the law both ways [LOW]. [VERIFY at P7 with a lawyer or Apple's developer-forum guidance; integrating the API is a small spike].
- Regional rating systems differ (Australia, Brazil, Korea GRAC). Check the per-storefront ratings shown on App Information after you save [HIGH that they exist; specifics VERIFY].
- A 13+ answer purely to widen reach would put "serve beer to bar patrons, ABV, Buzzed" in front of 13-year-olds and invites 1.4.3 ("apps that encourage minors to consume any of these substances will be rejected") [HIGH on the quote].

**Prevention:**
- Make the rating a **P1 decision**, recorded in PROJECT.md Key Decisions. Recommended: **plan for 18+**, honestly answered. The audience is adult craft-beer enthusiasts; the reach loss is small and the rejection/regulatory risk is the real cost.
- If someone argues for 13+, treat it as a design constraint with teeth: no depiction of consumption, no intoxication states, ABV shown only as a flavor/strength descriptor. That contradicts the design doc's "Buzzed"/"Wrecked", so it is a different game. Don't straddle.
- Fill in the questionnaire in App Store Connect during P1 against the *design doc* and revisit at every phase transition. It is free and shows what the design implies.
- Add an "Age Suitability URL" if useful [MED].

**Detection:** Nobody on the team can say the current planned rating. The store description sells "learn to brew" to a broad audience while the rating answer says Infrequent.

**Phase:** P1 (decision), P5 (re-check after statuses/bosses are final), P7 (submission, age-assurance spike).

---

### Pitfall 2: Mechanics and copy that read as *encouraging* excessive drinking (Guideline 1.4.3)

**What goes wrong:** Guideline 1.4.3: "Apps that encourage consumption of tobacco and vape products, illegal drugs, or excessive amounts of alcohol are not permitted. Apps that encourage minors to consume any of these substances will be rejected." [HIGH, verbatim]. Real rejection examples are all drinking-game apps: "primary purpose of encouraging excessive alcohol consumption" and 4.3 spam for duplicating other drinking games [MED, Apple Developer Forums]. Apple's enforcement on alcohol-adjacent apps is also inconsistent: a BAC-calculator app got six identical 1.4 rejections while "dozens" of similar apps stay live [MED, forum thread, one developer's account].

Brew Fighter is nowhere near a drinking game, but three design-doc elements are exactly what a reviewer skims for:
- **"Buzzed"** status: "Some patron preferences become less strict." That is a reward for getting patrons drunk.
- **Alcohol tolerance** + **"Wrecked Palate"** language next to high-ABV beers.
- Boss/patron comedy ("The Dive Bar Regular", "Level 34 Finance Bro") can drift into drunk-person jokes or "chug" copy.

**Prevention:**
- Define the rule now: **the player is a brewer/server; more alcohol never means more reward.** Buzzed should be a *mellow/relaxed* effect with a cost (e.g., delicate beers score worse; patron stops after N pours), capped, and never the winning strategy. Consider renaming to "Mellow" or "Loosened Up."
- No "chug", "get them drunk", shots, drinking-speed or intoxication-escalation mechanics. Pours are small tasting pours; keep the vocabulary of tasting and service.
- Put a short, adult, non-preachy "Drink responsibly / 18+ (21+ in the US)" note in Settings > About and the store description. It will not save a bad app but signals intent.
- Write **Notes for Review** (2.3.1 requires specific notes) explaining: brewing/tasting game, no real alcohol sales, no consumption encouragement, age-rated 18+. Include a short screen recording [MED].
- Keep the app account-free (see 5.1.1(v), Pitfall 12) so the reviewer isn't blocked.
- **Use external TestFlight as an App Review canary**: Apple's guideline 2.2 says TestFlight builds "should comply with the App Review Guidelines," and the first external build goes through Beta App Review [HIGH]. An alcohol-themed concern will surface there, months before launch, with no launch risk.

**Detection:** Playtesters describe Buzzed as "get them drunk to win." The best strategy in the harness is high ABV chaining. Store copy uses "get wasted", "drink", "chug."

**Phase:** P2 (status design), P3 (first external TestFlight = canary), P6 (copy), P7 (review notes).

---

### Pitfall 3: Marketing metadata, names and ads collide with 4+ rules, trademarks, and ad-network alcohol policy

**What goes wrong:**
- **Guideline 2.3.8:** "make sure your app and in-app purchase icons, screenshots, and previews adhere to a 4+ age rating even if your app is rated higher" [HIGH]. Screenshots showing a patron visibly drunk, "Wrecked", people mid-chug, or a beer-forward icon with suggestive copy can be rejected even though the app is 18+.
- **Trademarks (5.2.1, 2.3.7):** the design doc names "Untappd" (a company brand), uses "Pokémon-style" as shorthand, and uses hop names like "Citra" and "Nelson." Several hop varieties are registered/branded names [MED, VERIFY each]. Don't pack store metadata with trademarked terms (2.3.7), and 4.1(c) forbids using another product's name in your icon/name.
- **Name collision:** "Brew Fighter" and similar names may already be taken on the App Store; names are limited to 30 characters (2.3.7).
- **AI art can generate real beer-brand logos or lookalikes** (a Guinness harp, a Pabst ribbon) and Pokémon/AdCap-looking characters. Guideline 5.2.1 puts trademark liability on you.
- **Paid acquisition:** Apple Ads requires alcohol ads to be age-targeted, show no consumption of the product, and respect per-country law [MED]; Google and AppLovin have their own alcohol restrictions [MED]. A solo-dev budget will mostly be organic anyway (homebrewing, craft-beer, cozy-game communities), but plan for it.

**Prevention:**
- Create the App Store Connect **app record in P1** to reserve the name; settle the final name before art (icon, logo) is generated.
- Rename "The Untappd Guy" to a generic check-in-app parody; use fictionalized hop/yeast names or generic variety names where marks apply. Keep a `names-cleared.md` log.
- Screenshots/preview: use brewing screen, tap list, deduction clue UI, beer cards, family tree, cute patron portraits reacting, never intoxication visuals. Review the whole set against "would this be OK on a 4+ app?"
- Add a negative-prompt/QA step to the art pipeline: no logos, no real brands, no readable text.
- Don't mention Pokémon, Adventure Capitalist, or Untappd in metadata or keywords.

**Phase:** P1 (name reservation + naming rules), P5 (final patron/boss names), P6 (art QA), P7 (screenshots/keywords).

---

### Pitfall 4: Premium-vs-F2P is deferred until the economy is built, so the economy encodes the wrong assumptions

**What goes wrong:** PROJECT.md defers the decision to "before the economy phase." The failure mode is that systems built *before* that decision (acquisition, day counter, rare yeast, brewing time) quietly assume one model. Typical contamination:
- **F2P assumptions:** brew timers, energy/pour limits, "rare yeast hunts" as random drops, soft/hard currency. These directly fight the design doc's core loop and the fun-gate, which depends on instant retry and on learning from losses.
- **Premium assumptions:** flat content gating, no sinks, no re-engagement. Adding IAP later means retrofitting a currency and a store.
- **Randomized paid items:** Guideline 3.1.1 requires "apps offering 'loot boxes' or other mechanisms that provide randomized virtual items for purchase must disclose the odds of receiving each type of item to customers prior to purchase" [HIGH]. The doc's "Mutation Chance" yeast and rare culture drops are exactly the item type that would be sold. Paid randomness in an 18+ alcohol game also invites regulator attention [LOW].
- Australia: loot boxes raise the minimum rating to 16+ [HIGH]; moot at 18+.

**What Apple actually allows** [HIGH]: any digital unlock must use IAP; "unlocking a full version" via IAP is explicitly permitted, so **free download + one-time non-consumable "Full Game" unlock** is a legitimate try-before-buy path. Separate demo/lite apps are not (Guideline 2.2: "Demos, betas, and trial versions of your app don't belong on the App Store - use TestFlight"). Purchased currencies cannot expire and a restore mechanism is required.

**Prevention:**
- **Make the decision at the P3 gate, not at P5.** The fun-gate result tells you if the game is a premium-shaped puzzle-collection or a long-tail one. Write it to Key Decisions before P4 starts so collections are designed against it.
- **Recommended default: premium-shaped.** One-time price or free-with-one-time-unlock; no energy, no timers, no consumable currencies; progression gated by *knowledge* (deduction, regulars) not by time or money; no paid randomness; no ad SDKs (they conflict with the tone, alcohol ad policy, the 18+ privacy posture, and the 2-5 minute session feel). This is also what keeps the design doc's "learn people's tastes" loop honest.
- Until the decision: keep the day counter a **game-turn counter** (the roadmap already says brewing advances the day counter, never real time), keep rewards authored/deterministic with optional pity, and keep "currency" as a single abstract `Gold` value in one `Economy` module so a sink/IAP can be bolted on.
- If F2P is chosen anyway: odds disclosure UI (3.1.1), restore purchases button, StoreKit 2, IAP items complete and visible to the reviewer (2.1(b)), 18+ adult-only ad creative review, and a budget for live-ops that a solo dev usually does not have.
- Apple Small Business Program (15% commission under the revenue threshold) and Family Sharing for non-consumables are cheap to enable; check eligibility at P7 [MED, VERIFY].

**Detection:** The word "timer", "energy", or "premium currency" appears in a plan before the decision exists. Rare yeast is described as a "drop rate."

**Phase:** P3 (decision), P4/P5 (collection + economy design), P7 (StoreKit + review).

---

### Pitfall 5: Save data that can't survive reinstall, schema change, backgrounding, or tester builds

**What goes wrong:**
1. **Delete-and-reinstall wipes the app container.** Local-only saves vanish; an old iCloud *device backup* may or may not hold them (a new backup overwrites the old one) [MED]. For a collection game where recipes are emotional investment, this becomes the 1-star review.
2. **SwiftData is a trap for this app.** CloudKit sync requires: no `@Attribute(.unique)`, every attribute optional or defaulted, every relationship optional with an inverse [MED]. Recipe lineage (parent links), regulars and collections are exactly relationship-heavy. Migration is worse: if you ship the first version **without** a `VersionedSchema`, later `MigrationPlan`s fail with "Cannot use staged migration with an unknown model version," and several developers report migration crashes on first launch only in TestFlight/App Store builds, not in Xcode [MED, forum + blog reports].
3. **Dumping the whole app state** (UI state, scroll positions, derived attributes) into one blob makes saves unmigratable.
4. **iOS can kill you any time** (backgrounded, memory pressure, phone call). A save written only at "end of encounter" loses a half-finished pour sequence.
5. **TestFlight builds expire (90 days) and every new build must load the previous build's saves,** or your playtesters lose their progress each update and stop testing.
6. **Derived attributes stored in saves** means a balance patch orphans every beer (old issue, still true).

**Prevention (opinionated):**
- **Do not use SwiftData for the game state.** Use `Codable` value types in a pure-Swift domain package, stored as a **versioned JSON envelope** (`saveVersion`, `rulesetVersion`, content refs by stable string ID) in Application Support, written **atomically** (write temp, validate by decoding, replace; keep a rolling `.bak`). Application Support is included in standard device backups so restore-to-new-phone works [MED].
- Domain model: recipes are **immutable values** with `parentID` from the first brew; edit = new child. Store the recipe + `rulesetVersion`; recompute attributes at load from the current ruleset and surface changes ("your Garage Pale Ale changed in 1.1"). Content references use stable string IDs, never indices.
- Write explicit migration functions from day one, even when only v1 exists, with fixture saves from every shipped/TestFlight build checked into the repo and a round-trip test per fixture.
- Three layers: static content (bundle, never saved), save data (IDs only), transient UI state (never saved). Settings in their own file.
- **Autosave at every pour and every brew confirmation, restore to the exact encounter state** (store the encounter seed, pours used, revealed clues, status counters). See Pitfall 7.
- **Cloud decision by P4, not P7.** Options in order of effort: (1) local-only + user-facing **Export/Import save file** via the share sheet (cheap safety net, ship it in P3); (2) `GKSavedGame` or CloudKit private database via `CKSyncEngine` with last-writer-wins plus a "pick which save" conflict UI [MED]; (3) iCloud Drive document with file coordination. Pick one, scope it, and test two-device conflict + reinstall restore. If skipped for v1, say so in the store description ("progress stored on device; use iCloud Backup") so it is an informed choice.
- `ITSAppUsesNonExemptEncryption`, privacy manifest entries for `UserDefaults`/file timestamp APIs (required-reason APIs have been enforced since 2024-05-01 [HIGH]) get set in P1 so the first TestFlight upload doesn't stall.

**Detection:** `@Model` appears in domain code. There is no `saveVersion`. The first TestFlight update shows testers an empty game. Killing the app mid-pour loses the pour.

**Phase:** P1 (envelope + IDs + immutable recipe), P2 (round-trip tests), P3 (autosave, export/import, fixtures), P4 (cloud decision), P7 (migration QA on real devices).

---

### Pitfall 6: Session-length mismatch and the interruption-driven lifecycle

**What goes wrong:** Mobile sessions are 2-5 minutes and interruptible (notification, call, lock screen, app switch). The design doc's loop is a 12-step "Explore, Acquire, Brew, Serve, Learn, Improve, Expand" with a 5-input brew (grain bill, hop choice + timing, yeast, fermentation temp, conditioning) and 3-pour encounters. Common mistakes:
- Brew screen takes 5+ minutes to reach a "brew" tap, so players never reach the fun part.
- An encounter can't be resumed after the OS kills the app; players lose a clue-heavy sequence.
- Long pour animations/dialogue multiply by hundreds of encounters.
- The AdCap reference tempts offline-progress timers and "your beer is ready" push notifications. The project explicitly rejected real idle mechanics; push notifications also may not be *required* to use the app (5.1.2(i)).
- Hub navigation requires 4+ taps to get from launch to a fight.

**Prevention:**
- **Budgets as acceptance criteria:** launch to first pour <= 20 seconds for a returning player; one encounter (3 pours) 60-120 seconds including clue reading; a "tweak and rebrew" <= 30 seconds. Brewing from a previous recipe is **one tap** (roadmap already requires "rebrew in one action"); new recipes use presets/templates and progressive disclosure (3-4 choices on the first brew, as the roadmap plans).
- Encounter state machine is **serializable** and autosaved on every transition; test with "kill app at every state, relaunch, continue."
- Skip/fast-forward and a per-pour animation budget (~1.5-2 s); one-line feedback plus one icon change.
- No real-time waits, no required notifications. If you add a notification, it is optional and asked in context, never on first launch.
- Respond to `scenePhase` changes: pause animations, flush the save, stop haptics/audio appropriately.

**Detection:** Playtesters stop to ask "can I leave now?" Median session time on TestFlight analytics is >8 minutes with no natural stopping point. Encounter completion rate drops after backgrounding.

**Phase:** P1 (state machine design + budgets), P3 (measured in playtest), P6 (animation/skip polish).

---

### Pitfall 7: SwiftUI performance traps in a game-like, animation-heavy, data-heavy UI

**What goes wrong:** SwiftUI is the right call for this menu-heavy game, but "juice" and 16-attribute screens expose its sharp edges. Apple's WWDC25 performance session names the two root causes: **long view body updates** (heavy work in `body`) and **unnecessary view updates** (broad dependencies, e.g., a view that reads a whole array so every row updates when one item changes) and recommends the new SwiftUI Instrument with the Cause & Effect Graph [HIGH, session 306]. Applied to this app:
- **One god `@Observable GameState`** read by every screen. Any change in tap list, regulars, or clue log invalidates dozens of views. Instead use narrow observable objects/slices per screen and per row view-models.
- **Scoring/preview computed in `body`.** The live attribute preview (roadmap P3) recomputes 16 attributes from many ingredients on every slider tick. Memoize per recipe, compute off the main actor, or debounce; never construct formatters (`NumberFormatter`, `MeasurementFormatter`) in `body` (Apple's own example).
- **`TimelineView(.animation)` for ambient bubbles/foam** keeps the whole subtree redrawing every frame (battery, thermals, Low Power Mode). Pause when off screen; cap particle counts; prefer a short `keyframeAnimator`/`PhaseAnimator` over a perpetual timeline.
- **`Canvas`** is fast for the procedural glass/liquid/bubbles, but its contents are **invisible to VoiceOver** and have no per-element identity or built-in hit-testing/animation. Use it for decoration, put interactive/semantic elements in real views, add accessibility labels (Pitfall 10).
- **`drawingGroup()`** rasterizes the subtree into an offscreen Metal texture; helpful for many shapes, but can blur text and hurt small views. Measure before and after.
- **`LazyVStack`/`List` with unstable IDs** (`UUID()` created in `body`, or `id: \.self` on mutable values) destroys and recreates rows; recipe journal and Regulars Book (40+ entries) will hitch.
- **Matched-geometry and broad `.animation(_:value:)` on containers** animate things you didn't intend. Scope animations with `withAnimation` or `transaction`.
- **Image memory.** A 2048x2048 RGBA image decodes to ~16 MB (2048 x 2048 x 4 bytes). 40 AI portraits at that size is ~640 MB if they are all resident, a jetsam-kill risk. Export art at ~3x its on-screen size, use asset catalogs, downsample large images with ImageIO, and don't pre-render beer permutations as PNGs; **compose glass + liquid tint + head + label in code** (the roadmap already says "procedural beer glasses").
- **Testing only on the Simulator or a Pro-model phone.** ProMotion hides hitches that a 60 Hz or older device shows; Simulator timing is meaningless.

**Prevention:** Set a perf budget in P1 (steady 60 fps on the oldest supported device, no hitch > 100 ms in brewing/encounter flows). Run the SwiftUI Instrument + Hangs/Hitches on a real device at the end of every phase. Keep the domain in a pure Swift package with `Sendable` value types so the heavy math is testable and movable off the main actor. Pick a deployment target of **iOS 17+** (Observation framework, `@Observable`; iOS 18 if you want newer SwiftUI APIs) and record the oldest test device in the plan.

**Detection:** Opening the Regulars Book or dragging a temperature slider hitches. The Cause & Effect Graph shows one state change triggering a screen's worth of body updates. Memory graph shows hundreds of MB in image buffers. Device gets warm during idle screens.

**Phase:** P1 (architecture + budgets), P3 (preview perf), P4/P5 (long lists), P6 (art memory + juice).

---

### Pitfall 8: The OS/SDK treadmill and Liquid Glass versus a custom chunky AdCap UI

**What goes wrong (dates matter, today is 2026-10-08):**
- iOS 27 shipped 2026-09-14. **Xcode 27 ignores the `UIDesignRequiresCompatibility` Info.plist opt-out** that let Xcode 26 builds keep the pre-Liquid Glass look; standard controls adopt Liquid Glass automatically and are noticeably larger [MED, Apple Developer Forums thread 839061 + secondary sources].
- Apple announced (2026-09-09) that **from April 2027 every iOS submission must be built with the iOS 27 SDK or later** [MED]. (The earlier rule, Xcode 26/iOS 26 SDK from 2026-04-28, is already in force [HIGH].) A release target spanning that date cannot stay on Xcode 26.
- Your design is "bright, chunky, button-heavy" custom UI. Any *system* chrome you use (`NavigationStack` bars, `TabView`, sheets, toolbars, `Menu`, alerts, pickers, `Toggle`) will look like Liquid Glass next to your custom flat art. The mixed result looks unfinished.

**Prevention:**
- Build and test on **Xcode 27 / iOS 27 from the first commit**. Don't develop on Xcode 26 and "migrate later."
- Decide in P1: **custom chrome end to end** (own nav, own buttons, own sheets via `ZStack`/custom transitions) vs **system chrome for utility screens** (Settings, About, Journal) with the glass look accepted. Recommended hybrid: custom for the game surfaces (brew, encounter, taplist), system for Settings/utility, and one UI-kit file that wraps both so a swap is a one-file change.
- Wrap buttons in your own `ButtonStyle` with explicit minimum 44x44 pt hit targets (Apple HIG) so system size changes don't alter layout.
- Support the oldest iOS you chose, but test the newest *and* oldest: Liquid Glass vs pre-glass rendering both exist in the wild for the first release.
- Re-check the SDK deadline text at P7; it may change.

**Detection:** A screenshot mixes translucent system bars with flat sticker art. A new Xcode drop changes spacing everywhere. TestFlight upload rejected "built with an unsupported SDK."

**Phase:** P1.

---

### Pitfall 9: Portrait, one-handed reachability and gesture conflicts

**What goes wrong:** On 6.1-6.9" phones the top third is out of one-handed thumb reach. Games port desktop/tablet instincts: top-right close buttons, top nav bars, drag-and-drop lineup reordering, tiny stat toggles, hover-style tooltips. Specific traps:
- Primary actions (Serve, Brew, Confirm) placed at the top or middle; destructive or irreversible ones placed right next to the home-indicator swipe zone.
- **Custom horizontal drags/carousels vs system edge-swipe-back** and sheet drag-to-dismiss: gestures fight; the player accidentally leaves an encounter.
- Drag-and-drop to arrange 6 taps: fiddly on glass, inaccessible with VoiceOver/Switch Control.
- Tap targets under 44 pt when 16 attributes are packed in rows.
- Safe areas: Dynamic Island, rounded corners, home indicator; content hidden or unreachable.
- iPad runs your iPhone-only app in compatibility mode (PROJECT.md accepts this); also available as "iPhone app on Apple silicon Mac" unless you opt out [MED, VERIFY the exact App Store Connect toggle and any iPad screenshot requirement at P7].

**Prevention:**
- **Bottom-anchored action bar** for the core verbs on every game screen; contextual info and headers up top. Lay out screens as "read at top, act at bottom."
- Use `.presentationDetents` for half-height sheets so the sheet content stays within the thumb zone.
- Tap-to-select / tap-to-place as the **primary** lineup mechanism; drag-to-reorder as an enhancement. Provide `accessibilityAction`s for reorder.
- Disable interactive-dismiss on encounter screens; require explicit "Leave encounter?" confirm.
- Define a single spacing/hit-target token set in the UI kit and a lint test that finds buttons under 44 pt.
- Run a one-handed test (right thumb, left thumb) on a real large phone and a small one (iPhone SE-class or mini-class if you support them) at the end of each UI phase.

**Detection:** Testers re-grip the phone to press a button. Accidental encounter exits. VoiceOver can't reorder taps.

**Phase:** P1 (UI kit + tokens), every UI phase (verify), P6 (accessibility pass).

---

### Pitfall 10: Dynamic Type and accessibility retrofit, plus color-only encoding

**What goes wrong:** Chunky AdCap-style buttons are typically fixed-size with fixed-size text. Retrofitting Dynamic Type later means touching every screen. The roadmap's own "text scale factor" idea (inherited from the desktop plan) is not the iOS mechanism: use the system.
- Fixed `.font(.system(size: 14))` doesn't scale. Custom fonts need `Font.custom(_:size:relativeTo:)`; icon sizes need `@ScaledMetric`.
- Fixed-height rows truncate at accessibility sizes (AX1-AX5); the 16-attribute display is the worst offender.
- `Canvas` and custom-drawn glasses/bubbles are invisible to VoiceOver unless you add labels/`accessibilityChildren`.
- Color-only encoding: beer tint, rarity, status effects, "known/suspected/unknown" clue states.
- Reduce Motion ignored by juice animations (shakes, screen bounces, bubbles).
- Apple's **Accessibility Nutrition Labels** on the product page are voluntary now and are stated to become required for new apps and updates later [MED]; accessibility gaps will eventually be visible and gating.

**Prevention:**
- P1 UI kit: all text via semantic styles or `relativeTo` custom fonts; layouts built with `ViewThatFits` / `AnyLayout` (horizontal at normal size, vertical at accessibility size); chunky buttons are *min-height*, not fixed height.
- Standing rule: every status, rarity and clue-state uses **icon + label + color**, never color alone (the roadmap already requires this for Phase 2; extend it to Dynamic Type and VoiceOver).
- Accessibility Inspector audit at the end of **P2 and P3**, not P6. Test at default, XXL, and AX3.
- `@Environment(\.accessibilityReduceMotion)` gate on every non-essential animation; haptics respect system settings.
- Provide `accessibilityLabel`/`accessibilityValue` for beer visuals ("West Coast IPA, golden, bitterness high, citrus medium").
- Decide which Nutrition Label claims you will make and test those specific features.

**Detection:** Text clipped at XXL. Accessibility Inspector reports unlabeled elements in the encounter screen. Reduce Motion on, game still shakes.

**Phase:** P1 (kit), P2/P3 (audits), P6 (final pass), P7 (label claims).

---

### Pitfall 11: AI flat/cartoon art, consistency across a large asset set, and rights

**What goes wrong:** (Carried forward from the pixel-art version; the failure modes change with flat vector-like style.)
- **Style drift:** outline weight, palette, light direction, head-to-body ratio, and detail density differ across batches and model versions; 40+ patrons + 25+ ingredients + 8 yeast + bosses + locations do not look like one game.
- **Expression matrix:** patrons x (neutral, pleased, sour, delighted) = 160+ images where character identity drifts between expressions.
- **Edge halos and fringing:** background-removed AI PNGs show light halos on colored UI panels; common in flat-art UIs on saturated backgrounds.
- **Resolution/format:** AI output is raster, not clean vector; upscaling later blurs. Export at 3x of the largest on-screen use.
- **Text baked into images** (labels, signs) is wrong, unlocalizable, and sometimes real-brand-like.
- **Rights:** the US Copyright Office position is that purely AI-generated images aren't copyrightable without sufficient human authorship [MED]; competitors can copy your art. Tool terms of service vary on commercial use. Generated likenesses of real brands/characters create 5.2 exposure (Pitfall 3).
- **Apple policy:** guideline 5.1.2(i) governs sending personal data to third-party AI; pre-generated art shipped in the bundle does not trigger runtime-AI disclosure [MED, VERIFY if any generative features are ever added at runtime]. Unlike Steam, no AI-art disclosure field exists in the App Store Connect flow that I found [LOW]. Community reaction to AI art in cozy/indie spaces is still a reputational risk [LOW].

**Prevention:**
- **Style-lock spike in P1:** generate 10-12 assets across every category (patron, ingredient, yeast, location, UI frame, boss, icon) with one pinned tool + version; proceed only if the contact sheet coheres. The roadmap already schedules this spike.
- **Style bible:** palette (fixed, ~24-32 colors plus tints), outline weight, light direction, canvas sizes per asset class, naming scheme.
- **Deterministic post-process script** (Python/Swift CLI): trim/pad to exact canvas, remove fringe (matte or decontaminate edges), palette-snap or color-grade, export 1x/2x/3x or a 3x master, write a **manifest** (prompt, tool+version, seed, source file, post-process version).
- **Procedural where AI is weak:** the beer glass/liquid/head/label (already planned), UI frames, rarity badges, and **expressions via shared face base + overlay eyes/mouth layers** rather than 4 independent portrait generations.
- Reference art through logical IDs in an asset catalog so the whole set can be swapped later (commissioned or licensed art if the game succeeds).
- Keep API keys and raw dumps out of git; commit only curated finals + manifest.
- Budget 10-20 minutes of manual cleanup per asset and an art-direction review gate before P6 bulk generation. Do not start bulk art before the P3 gate (the roadmap already enforces this).
- Legal housekeeping in P1: save the tool's commercial-use terms (screenshot + date) and note that the art itself is likely unprotectable; protect the *game design, code, names and procedural renderer* instead.
- Hold an opinion on disclosure: state AI-assisted art plainly on the website/press kit; do not hide it.

**Detection:** Palette color count balloons. Two portraits look like different games. A single asset needs many regenerations. Thin white edges on colored buttons.

**Phase:** P1 (style lock + pipeline), P6 (bulk), P7 (rights + disclosure copy).

---

### Pitfall 12: Solo-dev App Store logistics left to the end

**What goes wrong:** Release week becomes a pile of administration and 2-3 unplanned review cycles.
- **Apple Developer Program enrollment** (paid annual) can take days; an *individual* account shows your personal legal name as the seller; an *organization* account needs a D-U-N-S number and takes longer [MED].
- **EU Digital Services Act trader status:** if you sell commercially (paid app or IAP), you must declare trader status and provide legal name, address, phone and email, which Apple **displays publicly** on EU product pages; apps without it are removed from EU storefronts [MED; Apple lists this as in force since 2025-02-17].
- **Privacy:** a privacy-policy URL in metadata *and* reachable in-app (5.1.1(i)); App Privacy ("nutrition") labels; privacy manifest including required-reason APIs for you and any SDKs [HIGH]. Every analytics/ads SDK complicates this; for this game, add none.
- **Guideline 2.1(a):** "Submissions ... should be final versions with all necessary metadata and fully functional URLs included; placeholder text, empty websites, and other temporary content should be scrubbed" [HIGH]. Apple reports 40%+ of rejections relate to 2.1 App Completeness (crashes, placeholders, broken links) [HIGH]. AI-art placeholders and "TODO patron" entries are classic triggers.
- **IAP completeness** (2.1(b)): every IAP configured must be visible and functional to the reviewer or explained in review notes.
- **No login:** 5.1.1(v) says apps without significant account-based features should work without login. Don't invent accounts. Game Center is optional.
- **Screenshots:** at least one set for the required iPhone size class, up to 10 per size, no alpha/transparency, must show the app in use rather than title art (2.3.3) [HIGH on rules; the *exact* required pixel sizes changed historically, VERIFY current sizes in App Store Connect at P6].
- **Review timing:** 50% reviewed under 24 h, 90% under 48 h [HIGH], but that is for clean submissions. First submission of an alcohol-themed game can bounce.
- **App name** availability (Pitfall 3) and **age rating** (Pitfall 1).
- **Tooling/signing:** provisioning, capabilities (iCloud, push) added late break CI/TestFlight uploads.

**Prevention:**
- **P1 checklist:** enroll; create app record (reserves name); set bundle ID and capabilities; first TestFlight upload of a hello-world build; draft privacy policy + support page (a simple static site); decide trader status/address; decide the seller identity (individual vs org); complete the age questionnaire.
- **Metadata from P3 on:** keep a `store/` folder with the description, keywords, privacy answers, screenshot shot-list, review notes. Update at each phase gate. Capture screenshots every phase from real builds so the final set isn't a scramble.
- Schedule P7 with **three review cycles of buffer** (plan 2-3 weeks) and no hard marketing date until approval; use **phased release / manual release** after approval.
- Use **App Review appointments** (30-minute call) and the one-appeal-per-rejection path if the alcohol theme is misread [HIGH].
- Ship with `UIRequiredDeviceCapabilities` and device family that reflect what you tested.

**Detection:** No app record exists past P2. Privacy policy URL points at a placeholder. Screenshots all use debug UI.

**Phase:** P1 (enrollment + app record + hello-world TestFlight), P3 (store folder), P6 (screenshots), P7 (submission).

---

### Pitfall 13: TestFlight playtest logistics for the fun-gate fail, producing a false pass or an unreadable result

**What goes wrong:** The roadmap's P3 gate ("at least 3 outside playtesters demonstrate design criteria #2, #6 and #7") is the project's most important decision, and its logistics are non-trivial on iOS.
- **External testers need Beta App Review** for the first build of each version train (and builds are reviewed automatically once added to an external group) [HIGH]. Plan a 1-3 day delay and keep alcohol-related review notes ready (Pitfall 2).
- Limits: 100 internal testers (team members only), **10,000 external**, 30 devices per tester, public links with criteria [HIGH]. **Builds expire after 90 days** [MED, standard TestFlight behavior; Apple's page excerpt did not restate it].
- **Compensation:** Guideline 2.2: "apps using TestFlight cannot be distributed to testers in exchange for compensation of any kind, including as a reward for crowd-sourced funding" [HIGH]. Don't sell/gift TestFlight access as a perk. Paying testers for *their time and feedback* is different from selling access, but keep it clearly separate and don't advertise it as a beta reward [LOW, interpretation].
- **Wrong testers:** recruiting only friends or fellow developers produces polite approval. The design doc's audience includes craft-beer enthusiasts who will notice wrong brewing facts and judge criterion #7. Testers must be adults (18+; 21+ in the US) given the content [MED].
- **No signal:** TestFlight gives crash reports and screenshot feedback, not "why they lost." Without instrumentation and observation you can't verify criteria #2/#6.
- **Third-party analytics SDK** to fix that adds privacy-manifest work and a "data collected" label.
- **Save compat across builds** wipes testers (Pitfall 5).
- **Coaching bias:** the developer helps in a live session; the result is invalid.

**Prevention:**
- Run the gate as a **written protocol** (the roadmap flags this): 5-8 recruits (craft-beer people, homebrewers, plus 2 non-beer gamers) so that 3+ complete it; no coaching; a fixed task script ("play until you've beaten or given up on 3 patrons, then describe your tap list to me"); a post-session interview mapped line-by-line to criteria #2, #6, #7; screen recording with consent, or remote observation via screen share.
- **Local, privacy-simple instrumentation:** a bounded on-device event log (encounter start/win/lose, pours used, clues revealed, time per screen, brew-screen abandonment) with an **export button** testers can share. No network, no third-party SDK, no account.
- A **tester build flag** to reset the save and to skip tutorial steps for repeat sessions.
- Stagger rounds: internal TestFlight in P1-P2 (yourself on real hardware weekly), first external build at the **end of P2** to burn in Beta App Review and the alcohol canary (Pitfall 2) *before* the real gate.
- Keep a build cadence under the 90-day expiry, with release notes that tell testers what to look at.
- Pre-register what counts as pass/fail for the gate (e.g., 2 of 3 testers can explain a failed pour without help; 0 of 3 call it a guessing game).

**Detection:** Gate plan lacks a recruiting source. All "playtesters" are people who know you. The first external build was submitted the week of the gate.

**Phase:** P1 (TestFlight pipeline, hello-world), P2 (first external build), P3 (gate).

---

### Pitfall 14: Building the entire game before the core loop is proven fun

**What goes wrong:** PROJECT.md records "Full v1 game, not just Phase 1 prototype" as a decision. The design doc's own prototype exists to answer one question: "Can brewing decisions create interesting beers, and can those beers create interesting patron-selection puzzles?" If not, UI, art and world systems have already been built on the wrong core. Solo devs want visible progress (portraits, maps), and systems games read fine on paper (16 attributes, 9 statuses, 5 relationship tiers) and only reveal dullness in play.

**Prevention:** Keep the full-v1 ambition but sequence it as the roadmap already does: P1-P3 are an ugly, rectangles-and-text, procedural-glass iPhone build with ~10 patrons, 6 taps, ~20 ingredients; **no bulk art, no city, no bosses until the P3 TestFlight gate passes**. Protect the gate by making the post-gate phases depend on it in ROADMAP.md (already done) and by refusing "just one more" visual work before it.

**Warning signs:** Art generation prompts for 30 patrons before any outside player has lost an encounter. The scoring formula is still changing while portraits are generated.

**Phase:** Roadmap-level; P3 gate.

---

### Pitfall 15: Stat soup, now on a 6-inch screen

**What goes wrong:** 16 sensory attributes (Malt, Sweetness, Dryness, Body, Bitterness, Hop Aroma, Citrus, Tropical, Herbal, Spice, Roast, Fruit, Funk, Sour, Carbonation, ABV) as 16 bars or rows is illegible in portrait; players stop reasoning about flavor and brute-force numbers. Several attributes correlate (Dryness/Sweetness/Body; Citrus/Tropical/Fruit) and ABV is a different kind of quantity (strength/tolerance, not preference).

**Prevention:**
- Keep 16 in the model, present in **families** (malt, hop, yeast, mouthfeel/strength) with glyphs or a radar/flavor-wheel; numbers on drill-down (the roadmap already specifies families + glyphs).
- Primary beer identity = **top 3 traits + 1 flaw** + generated name + tasting note + glass visual.
- Treat ABV as a separate strength axis.
- Patron palettes reference families and 3-5 specific axes, never all 16.
- **Five-second glance test** in P3 on an actual phone: can a tester say what a beer is good against without opening detail?
- Brew screen: <= 7 live controls visible at once; use steppers/segmented controls rather than 5 sliders (also better for one-handed use and accessibility).

**Warning signs:** Testers narrate numbers ("it has 4 citrus") instead of character ("it's bright and snappy"). Detail screens are opened on every pour.

**Phase:** P2 (families), P3 (glance test), P1 (UI kit supports glyph widgets).

---

### Pitfall 16: Deduction collapses into style-matching, a guessing game, or a solved puzzle

**What goes wrong:** (Carried forward, unchanged in substance.) Four failure modes: (1) *Style leak*: patron data references styles, so the sensory layer is decorative (violates the design doc's "Important Design Constraint"). (2) *Under-determined puzzle*: three pours cannot identify a hidden preference vector over many dimensions, so players guess and lose. (3) *Information leak*: the doc's sample "+22 Hop Match, +8 Dryness, -12 Excessive Bitterness" printed with exact numbers solves the patron in one pour; printing nothing is noise. (4) *One-and-done*: once a patron's palette is in the Regulars Book, every later encounter is execution.

**Prevention:**
- Style is an **output** (computed label), never an input; boss gimmicks (Beer Judge, German Brewmaster) are defined by attribute/technique rules, not style IDs.
- **Information budget per pour:** 1-2 coarse facts (Likes/Neutral/Dislikes an axis; tolerance Low/Med/High); score breakdown in direction + magnitude buckets, not invertible raw weights. The roadmap's "itemized +/- per-attribute breakdown" in Phase 1 should be checked against this: show it in the slice only if the harness shows it doesn't trivialize patrons, or bucket it.
- Palette size per patron: 3-5 positives, 1-3 dislikes, 2 tolerances, 1 hidden.
- **Headless solvability test** (Pitfall 17): a scripted "reasonable player" following clues wins >= 70% within the pour limit; "style-only" and "random" strategies win far less.
- Choose the one-and-done policy deliberately: escalate later encounters (stacked statuses, fewer pours), or vary per-visit mood/context shifting one axis, and always **bank clues on a loss** (fail-forward).

**Warning signs:** A content column named "Favorite style." Testers win without opening the attribute view. One "Crowd Pleaser" beer beats most patrons.

**Phase:** P2 (info model + harness), P3 (clue UX), P5 (escalation).

---

### Pitfall 17: A dominant "max everything" beer, and no tooling to see it coming

**What goes wrong:** Additive scoring rewards breadth, so a balanced inoffensive beer (the doc's "Crowd Pleaser") or a maxed-intensity beer wins everywhere; the 6-tap lineup collapses to one recipe. Too-steep tradeoffs do the opposite.

**Prevention:**
- Real brewing tradeoffs: high attenuation raises Dryness and lowers Body/Sweetness; heavy roast masks hop aroma; high ABV raises warmth and Hop Burn risk. Diminishing returns and penalty asymmetry (a disliked axis hurts more than a liked axis helps), so inoffensive means mediocre. Cap/decay "free bonus" abilities.
- **Swift-native harness:** domain package with no UIKit/SwiftUI dependency; a Swift Testing/XCTest target plus a small CLI executable target that generates N archetype and random recipes, scores vs all patrons, prints a heatmap, and reports (a) unbeatable patrons, (b) trivial patrons, (c) best single beer's win rate, (d) count of distinct best-in-class beers. Gate in CI (Xcode Cloud or a local script): >= 4 distinct best-in-class beers in a 6-tap lineup; >= 70% solvability; best-order vs worst-order delta >= 15 satisfaction points in a healthy fraction of encounters.
- Keep scoring deterministic; seeded randomness stored in the save (patron ID + visit count) and kept out of the clue channel.

**Warning signs:** One recipe on everyone's tap list. Balance edits are made one patron at a time. Nobody can answer "which patrons does the saison beat?" without playing.

**Phase:** P2 (model + harness), re-run at P4/P5 on every content change.

---

### Pitfall 18: Status effects that don't matter, or become homework

**What goes wrong:** Nine listed statuses in a 3-pour encounter yield barely two ordering decisions. Invisible or fuzzy triggers make order noise; all nine live at once forces a rules matrix in the player's head.

**Prevention:** Start with 2-3 (Palate Fatigue, Hop Burn, Refreshed), each tied to a visible attribute threshold; introduce others one at a time through patrons/locations/bosses. Always show active statuses with icon + one-line rule + visible expiry counter. Add best-order vs worst-order delta to the harness. Consider 4-5 pours for bosses. (The roadmap's "6-8 effects in P2" is on the high side: ship the minimum set that passes the order-delta test.) Re-read Pitfall 2 when finalizing "Buzzed."

**Phase:** P2 (rules + harness), P3 (display), P5 (staged introduction).

---

### Pitfall 19: Black-box brewing (outcomes the player can't predict or learn from)

**What goes wrong:** Players pick grain bill, hop timing, yeast, temperature and conditioning, then get surprising numbers. Without legibility, experiments aren't learnable, criterion #3 ("modify recipes after learning patron preferences") fails, and the "accidentally learn real brewing" promise is wasted.

**Prevention:** A small set of consistent, real rules of thumb (hot mash means fuller/sweeter; early hops bitterness, late hops aroma; warm ferment esters/phenols, cool/lager clean). Each ingredient contributes to 2-3 dominant attributes plus one identity trait. **Live preview with causal tags** ("Dry: yeast attenuation +2, mash 148F +1"), and "?" for undiscovered ingredient traits (roadmap P3). A post-brew "batch notes" screen. Have a homebrewer/BJCP-literate reader check the rules table; this audience will call out wrong facts (carried-forward "accuracy gaffes" risk).

**Phase:** P1 (attribution data), P2 (rules table), P3 (preview UI), content review at P4.

---

### Pitfall 20: Content explosion and the balance treadmill

**What goes wrong:** v1 means 40+ patrons, 8 bosses, 25+ ingredients, 8+ yeast, 5-8 locations. Every patron needs a palette, portrait, expressions, voice lines, Regulars entry, and a balanced win path; every new ingredient reshapes reachable attribute space and invalidates earlier balancing.

**Prevention:** Fix a content budget in requirements and treat additions as scope changes. All content as **bundled JSON (or Swift literal tables) with a validator** in the test suite (required fields, palette size limits, no style references, ranges, unique stable IDs). Reaction text from templates keyed by (attribute, direction, intensity) with archetype voice overrides and a few handwritten signature lines per patron. Use **String Catalogs** from day one (English-only v1 is fine; externalized strings keep content out of code). Run the balance matrix (Pitfall 17) as a content CI step.

**Phase:** P2 (format + validator), P4/P5 (budgeted content).

---

### Pitfall 21: Collection systems with no pull; mutation that destroys work

**What goes wrong:** Silent yeast mutation overwriting a tuned recipe punishes the iteration the game wants; blind-RNG rare drops feel arbitrary; the Regulars Book becomes a checklist; every beer is "colored glass + number list" so no attachment forms.

**Prevention:** Mutation creates a **new forked culture** with a visible trait diff and never overwrites (the roadmap already specifies this). Make rare acquisition knowledge-driven (patron friendship, location discovery, conditions) with pity guarantees (also keeps Pitfall 4 clean). Regulars tiers derived from existing mechanics (Seen = met, Served = >= 1 pour, Impressed = score >= X, Regular = learned all axes, Friend = beat with a signature recipe). Beer identity card: generated name, top-3 traits + flaw, procedural glass, tasting note, favorites, shareable image card (P4). Cap taps at 6 but give the archive sort/filter/compare.

**Phase:** P4.

---

### Pitfall 22: Scope creep into a management sim, an idle game, or a walkable world

**What goes wrong:** Design-doc perks need subsystems (equipment repairs, food pairing, a visited brewery). "Adventure Capitalist" invites idle/offline progress and ad boosts; "Pokémon-style" invites an overworld. Each sounds small in a cozy game.

**Prevention:** Closed set of regular-perk effect types that only touch existing systems (discounts, unlocks, hints, pour bonuses; roadmap P5). Keep the node-based city map (roadmap) as the exploration form. Treat AdCap as a *UI/feel* reference only (PROJECT.md already says so): no offline earnings, no timers, no ads. Any new system must name the design success criterion it improves; otherwise it is v2.

**Phase:** Roadmap-level, P4, P5.

---

### Pitfall 23: Onboarding and settings left to the end, and iOS-specific polish forgotten

**What goes wrong:** A 16-attribute deduction game needs a staged first hour. In the first 5 minutes mobile players decide. iOS-specific items missed: respecting the **silent switch** (audio category `.ambient` unless you intentionally play over it) and audio interruptions; haptic overuse (and not respecting system haptics setting); Restore Purchases button (if any IAP; required by 3.1.1 for restorable items); permission prompts on first launch; dark-mode/forced appearance decisions; localization of numbers/units (ABV, temperature F/C: brewers use both; offer a setting).

**Prevention:** Design the first hour as a curriculum: first patron = 1 axis, then tolerance, then a status, then lineage. Build Settings in P1 (sound, music, haptics, text speed, reduce motion, units F/C, reset tutorial, About with privacy policy link and age note) and extend per phase. Provide skip/fast-forward for dialogue and pours. In-game glossary ("What is attenuation?") reusing the 70% culture content. Test with audio on silent and on a call interruption.

**Phase:** P1 (settings scaffold), P3/P5 (curriculum), P6 (polish), P7 (QA).

---

## Moderate Pitfalls

### Pitfall A: Hidden randomness undermines deduction and fairness
**What goes wrong:** Per-pour random variance makes clues unreliable.
**Prevention:** Deterministic scoring; seeded variation stored in the save and outside the clue channel; seeded RNG injected into the domain package for tests.

### Pitfall B: Brewing-accuracy gaffes in front of a beer-literate audience
**What goes wrong:** Wrong temperatures/hop timing/yeast facts get called out in reviews and forums, undermining the 70% culture promise.
**Prevention:** A rules-of-thumb reference doc, a homebrewer reviewer, directional truth over simulation bloat, UI copy that marks intentionally gamey rules.

### Pitfall C: Failure states that punish learning
**What goes wrong:** Losing costs time/resources, so players avoid experimenting, which kills the deduction loop.
**Prevention:** Loss = small cost or cooldown-free retry; always bank clues; reward partial success (roadmap P2 already calls for retry + banked clues).

### Pitfall D: Encounter fatigue
**What goes wrong:** Hundreds of 3-pour encounters with long animations and dialogue.
**Prevention:** Skip/fast-forward, quick-retry, one-line feedback + icon change, ~2 s animation budget (Pitfall 6).

### Pitfall E: Thermal and battery on long sessions
**What goes wrong:** Perpetual `TimelineView`/particle effects warm the device and drain battery; Low Power Mode and Reduce Motion make it worse.
**Prevention:** Pause ambient animation off-screen/idle, cap particles, test a 30-minute session on an older device (Pitfall 7).

### Pitfall F: Privacy surface creep
**What goes wrong:** Adding analytics, crash, or ad SDKs adds privacy-manifest, "data collected" label, ATT and policy work (5.1.1, 5.1.2).
**Prevention:** Zero third-party SDKs for v1; use MetricKit and Xcode Organizer crash reports; local debug logs only. Then the privacy label can read "Data Not Collected," which is also a trust signal for an 18+ audience.

### Pitfall G: Unvetted regional availability
**What goes wrong:** Alcohol content is restricted or illegal to promote in some countries; Apple can restrict by region and you are responsible for compliance in each territory you enable (2.3.6) [HIGH on the quote; country list VERIFY].
**Prevention:** Choose storefronts deliberately in Pricing and Availability: launch in a conservative set (US, CA, UK, IE, AU, NZ, EU) and add others after review; re-check after the rating is saved.

### Pitfall H: Xcode toolchain and CI lock-in
**What goes wrong:** Xcode updates (annual SDK deadline) break builds; signing certificates expire; single-machine builds.
**Prevention:** Keep the domain in a Swift package with command-line tests (`swift test`), automate archive+upload (Xcode Cloud or `xcodebuild` + `fastlane`), and note the SDK deadline each spring.

---

## Minor Pitfalls

### Pitfall a: Hardcoded strings and magic numbers
**Prevention:** String Catalogs for UI, JSON for content, one tuning constants file.

### Pitfall b: Naming and typing UX
**What goes wrong:** Beer naming needs text entry; the keyboard covers half the screen in portrait.
**Prevention:** Generated names with re-roll plus an optional text field with keyboard-safe layout.

### Pitfall c: Audio and haptics left for last
**What goes wrong:** Pour/clink/cheer feedback is a large share of "juice."
**Prevention:** Placeholder SFX/haptics from P3; decide audio sourcing and licenses in P1 (the roadmap's "Sonic Pi" is part of the obsolete plan; re-decide for iOS).

### Pitfall d: API keys and generation dumps in the repo
**Prevention:** Env vars; commit curated finals and manifest only.

### Pitfall e: App icon and launch polish
**What goes wrong:** App icon (1024x1024, no alpha) generated by AI contains text or brand lookalikes; icons built without current Xcode tooling look off beside system icons.
**Prevention:** Generate and finalize the icon in P6 after the style bible; check with the current icon tooling in Xcode 27.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| SwiftData `@Model` for game state | Fast persistence demo | CloudKit constraints, migration crashes, lineage relationship pain | Never for game state; ok for throwaway spike |
| Unversioned save format | Ship P1 faster | Unmigratable saves, tester wipe | Never |
| One giant `@Observable GameState` | Simple wiring | Whole-screen invalidation, hitches | P1 spike only |
| Scoring/preview inside `body` | No view model needed | Main-thread hitches in brewing | Never past P2 |
| Hard-coded patron data in Swift types | No parser/validator | Can't run balance matrix | First 3 patrons in P2 only |
| Store derived attributes in saves | No recompute logic | Balance patches orphan beers | Never without `rulesetVersion` |
| Style names in patron definitions | Easy authoring | Kills deduction | Only boss gimmicks defined via attribute rules |
| One PNG per beer permutation | Simple pipeline | Memory pressure, asset sprawl | Early placeholders only |
| System chrome mixed with custom art | Faster nav | Liquid Glass vs flat mismatch | Utility screens only (Settings, About) |
| AI assets without manifest/post-process | Fast first batch | Impossible to regenerate consistently | Never beyond the P1 style-lock spike |
| Third-party analytics SDK | Easy metrics | Privacy label/manifest burden | Never for v1; local logs instead |
| Build with Xcode 26 "for now" | Avoid Liquid Glass fixes | Rework at the April 2027 deadline | Never for a release target after that date |
| Defer app record / TestFlight setup | More time on gameplay | Enrollment/provisioning surprises at P3 gate | Never |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| App Store Connect age rating | Answering from memory of 17+ | Re-answer against the 4+/9+/13+/16+/18+ questionnaire; plan 18+ (Pitfall 1) |
| TestFlight external | Submitting the first external build the week of the gate | Burn in Beta App Review at the end of P2; keep review notes |
| StoreKit 2 (if IAP) | No Restore, IAP not visible to reviewer, odds not disclosed for random items | Restore button, IAP reachable in review build, odds UI (3.1.1, 2.1(b)) |
| iCloud / CloudKit | Using SwiftData sync with unique constraints and non-optional relationships | Codable JSON + `CKSyncEngine`/`GKSavedGame`, or local + export/import (Pitfall 5) |
| Game Center | Making sign-in required | Optional; no accounts (5.1.1(v)) |
| Push notifications | Asking on first launch, or requiring them | Optional, contextual, never required (5.1.2(i)) |
| AI image tools | Mixing models/versions, no seeds saved, no commercial terms on file | Pin tool + version, manifest, archive ToS (Pitfall 11) |
| Apple Ads / social ads | Showing consumption or untargeted ages | Age-target, no consumption imagery, per-country rules (Pitfall 3) |
| EU distribution | Missing trader status | Declare in App Store Connect before launch (Pitfall 12) |
| Xcode/SDK | Developing on an old SDK | Xcode 27 from day one; April 2027 deadline (Pitfall 8) |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Broad `@Observable` dependencies | Many rows update on one change | Per-row view models, slice state | Lists of 25-50+ rows (journal, Regulars Book) |
| Work in `body` (formatters, scoring) | Hitches while dragging controls | Memoize, cache formatters, off-main compute | Live preview of 16 attributes |
| Perpetual `TimelineView` effects | Warm phone, battery drain | Pause off-screen, cap particles | Any screen left open 5+ minutes |
| `Canvas` for semantic UI | VoiceOver can't see content, no hit testing | Real views for interactive parts | Accessibility audit |
| `drawingGroup` everywhere | Blurry text, wasted memory | Apply selectively, measure | Text-heavy panels |
| Large AI PNGs | Memory warnings, jetsam kills | ~3x master, downsample, asset catalog | ~40+ full-size portraits resident |
| Unstable `ForEach` IDs | Row flicker, state loss | Stable IDs from domain | Journal/book scrolling and edits |
| Brute-force scoring on main thread | Lag when previewing every beer vs every patron | Memoize attribute vectors, precompute | 100+ recipes x 40+ patrons |
| Large save write on main thread | Autosave stutter | Background actor, atomic write | Hundreds of recipes with history |

## Security / Privacy Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Treating the save as trusted | Crash on corrupt/edited save | Validate on load (schema, ID existence, ranges), keep `.bak`, fail gracefully |
| Committing AI-service keys | Account compromise | Env vars, secrets outside repo |
| Forgetting privacy manifest/required-reason APIs | Upload warnings or rejection | Declare reasons in P1; re-run before each submission |
| Collecting personal data "for later" | Review friction (5.1.1), label burden | Collect nothing in v1 |
| Debug menus left in release | Reviewer finds hidden features (2.3.1) | `#if DEBUG` gating; document anything reviewable in Notes |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| 16 numbers on a phone screen | Overload, spreadsheet feel | Families, top-3 traits, glyph; numbers on drill-down |
| Exact breakdown after every pour | Puzzle solved instantly | Bucketed clues, 1-2 facts per pour |
| No visible knowledge log | Players forget and quit | Patron notebook always reachable (roadmap P2) |
| Top-of-screen primary actions | Re-grip, mis-taps | Bottom action bar, thumb zone |
| Fixed-size text in chunky buttons | Unreadable at large text | Semantic fonts + `ViewThatFits` |
| Unskippable animation | Fatigue | Skip/fast-forward, animation budgets |
| Color-only status/beer differences | Inaccessible | Icon + label + color |
| Failure that costs progress | Players stop experimenting | Fail-forward with banked clues |
| Interrupt-unsafe encounters | Lost progress on app switch | Serializable state, per-pour autosave |

## "Looks Done But Isn't" Checklist

- [ ] **Age rating:** questionnaire answered honestly against the actual design (not Infrequent for convenience); per-storefront ratings reviewed; age-assurance (Declared Age Range) decision recorded.
- [ ] **1.4.3 posture:** no mechanic where more alcohol is the winning strategy; review notes written; responsible-drinking note present.
- [ ] **Metadata:** every screenshot, preview and icon passes a 4+ review; no brand names/trademarks; name reserved.
- [ ] **Saves:** kill-app-mid-pour resume works; save from every shipped/TestFlight build loads; delete-and-reinstall behavior is known and disclosed; export/import works.
- [ ] **Economy:** monetization decision recorded in Key Decisions; no consumable currency/timers unless decided; odds disclosure present if randomized paid items exist.
- [ ] **Performance:** SwiftUI Instrument + Hitches run on an oldest-supported real device; memory graph checked with all portraits.
- [ ] **Liquid Glass:** built with Xcode 27; screens reviewed against glass defaults; custom vs system chrome decision documented.
- [ ] **Reachability:** every core verb reachable one-handed; no gesture conflicts with edge-swipe; hit targets >= 44 pt.
- [ ] **Accessibility:** XXL and AX3 text pass; VoiceOver can play an encounter; Reduce Motion honored; no color-only signals; Nutrition Label claims verified.
- [ ] **Art:** all assets pass the post-process script; manifest complete; no text/brand lookalikes; halos checked on real UI backgrounds.
- [ ] **TestFlight:** gate protocol written before recruiting; at least one prior external build approved by Beta App Review; local instrumentation export works.
- [ ] **App Store admin:** privacy policy live; privacy manifest and labels done; trader status complete; screenshots from the real build; no placeholder text.
- [ ] **Deduction:** harness shows every patron beatable via clues; no patron solvable by style alone; losing writes clues.
- [ ] **Balance:** matrix report shows >= 4 distinct best-in-class beers and no dominant recipe.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Wrong age rating declared | MEDIUM | Re-answer questionnaire, update metadata; expect rating-driven reach changes; fix mechanics if 1.4.3 flagged |
| 1.4.3 rejection | LOW-MEDIUM | Reply with notes + recording, request App Review appointment, rework Buzzed/copy, appeal once if misunderstood |
| Monetization decided late, economy wrong | HIGH | Strip timers/currency, rebuild reward tables as authored/deterministic, re-run balance matrix |
| SwiftData chosen, migrations crash | HIGH | Introduce versioned JSON envelope, one-time importer from SwiftData store, ship before launch |
| No save versioning | HIGH | Add `saveVersion`, write migration from the existing format, fixture saves |
| God-state invalidation | MEDIUM | Split observable models per screen, add row view-models, re-profile |
| Liquid Glass mismatch | MEDIUM | Move utility screens to system chrome, restyle custom screens around glass defaults, token-level fix in UI kit |
| Dynamic Type retrofit | HIGH | Rebuild layouts with `ViewThatFits`/scaled metrics screen by screen; do it per phase, not at once |
| AI art drift | MEDIUM-HIGH | Lock palette + post-process, regenerate outliers, accept consistent simple over inconsistent detailed |
| Playtest gate invalid | MEDIUM | Re-run with new recruits and a written protocol; delay P4 start |
| Review delays at launch | LOW-MEDIUM | Use Notes for Review, appointment, one appeal; keep marketing flexible |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| 1. Age rating as paperwork | P1 decision, P5 recheck, P7 submit | Rating recorded in Key Decisions; questionnaire answers match design |
| 2. 1.4.3 mechanics/copy | P2, P3 canary, P6, P7 | External TestFlight approved; review notes drafted; Buzzed not dominant in harness |
| 3. Metadata, trademarks, ads | P1, P5, P6, P7 | Name reserved; names-cleared log; screenshot 4+ audit |
| 4. Premium vs F2P | P3 decision, P4/P5 design | Decision doc; no timers/currency before it; odds UI if randomized paid |
| 5. Save data | P1, P2, P3, P4, P7 | Fixtures per build; kill/relaunch test; reinstall behavior documented |
| 6. Session length / interruption | P1, P3, P6 | Time budgets measured in playtest; resume-at-every-state test |
| 7. SwiftUI performance | P1, P3, P6 | Instruments run per phase on oldest device |
| 8. SDK / Liquid Glass | P1 | Builds on Xcode 27; chrome decision recorded |
| 9. Portrait reachability | P1 kit, each UI phase | One-handed test; 44 pt lint |
| 10. Dynamic Type / accessibility | P1 kit, P2/P3 audits, P6 | XXL/AX3 screenshots; VoiceOver encounter run |
| 11. AI art consistency / rights | P1 spike, P6, P7 | Contact-sheet gate; manifest; ToS archived |
| 12. Solo-dev store logistics | P1, P3, P6, P7 | Hello-world TestFlight; `store/` folder current; 3-cycle buffer |
| 13. TestFlight logistics | P1, P2, P3 | Written gate protocol; Beta App Review burned in |
| 14. Full game before proven | Roadmap, P3 gate | Outsider playtest meets criteria before P4 |
| 15. Stat soup | P2, P3 | Glance test; <= 7 live controls |
| 16. Deduction failure modes | P2, P3, P5 | Solvability harness; no style IDs in patron data |
| 17. Dominant beer | P2 | Matrix report thresholds |
| 18. Status effects | P2, P3, P5 | Order-delta metric; icon + rule visible |
| 19. Black-box brewing | P1, P2, P3 | Testers predict change outcomes |
| 20. Content explosion | P2, P4, P5 | Budget locked; validator in CI |
| 21. Collection pull | P4 | Mutation forks; derived Regulars tiers |
| 22. Management/idle/overworld creep | Roadmap, P4, P5 | Closed perk list; no timers |
| 23. Onboarding/settings/iOS polish | P1, P3, P5, P6, P7 | Fresh-player test; silent-switch test |

## Sources

- Apple App Review Guidelines (1.4.3, 2.1, 2.2, 2.3.1-2.3.8, 3.1.1, 3.1.2, 4.1, 4.2, 5.1.1, 5.1.2, 5.2): https://developer.apple.com/app-store/review/guidelines/ - MED (HIGH on quoted text; fetched through a summarizer, last ~12K characters of the page not read)
- Apple age ratings values and definitions (tiers, Alcohol/Tobacco/Drug descriptor, Infrequent=13+, Frequent=18+, regional notes): https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions - MED
- Apple "Set an app age rating" (override, regional ratings, unrated): https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/ - MED
- Apple Upcoming Requirements (Xcode 26 SDK from 2026-04-28; age-rating answers due 2026-01-31; DSA trader status; required-reason APIs): https://developer.apple.com/news/upcoming-requirements/ - MED
- April 2027 iOS 27 SDK requirement (announced 2026-09-09) and iOS 27 launch (2026-09-14): https://www.macobserver.com/news/april-2027-sdk-requirement-five-platforms/ ; Apple Developer Forums on Liquid Glass / `UIDesignRequiresCompatibility` ignored in Xcode 27: https://developer.apple.com/forums/thread/839061 - MED
- Apple 18+ app download gating in Brazil/Australia/Singapore and age-sharing in Utah/Louisiana: https://www.helpnetsecurity.com/2026/02/25/apple-expands-age-verification-controls/ - MED; Texas SB2420 Fifth Circuit stay: https://alerts.zwillgen.com/alerts/injunction-temporarily-lifted-for-texas-app-store-accountability-law - MED (status unstable)
- Apple Developer Forums on alcohol/drinking-game rejections and BAC calculator rejections: https://developer.apple.com/forums/thread/649488 , https://developer.apple.com/forums/thread/689498 , https://developer.apple.com/forums/thread/848256 - LOW-MED (individual developer reports)
- Brewery Boss: Beer Game App Store listing (13+ with Infrequent alcohol references; free + $0.99 ad removal): https://apps.apple.com/us/app/-/id1566591698 ; Fiz (17+ at time of listing): search result - LOW-MED
- WWDC25 session 306, Optimize SwiftUI performance with Instruments: https://developer.apple.com/videos/play/wwdc2025/306/ - MED-HIGH
- SwiftData + CloudKit constraints and SwiftData versioned-schema migration crashes: https://fatbobman.com/en/snippet/rules-for-adapting-data-models-to-cloudkit/ , https://mertbulan.com/never-use-swiftdata-without-versionedschema/ , https://developer.apple.com/forums/thread/742904 - MED
- TestFlight limits and Beta App Review: https://developer.apple.com/testflight/ - MED-HIGH
- App Review turnaround statistics and rejection tips (50% <24h, 90% <48h; 40%+ rejections are 2.1): https://developer.apple.com/distribute/app-review/ - MED-HIGH
- Accessibility Nutrition Labels: https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels - MED
- EU DSA trader status in App Store Connect: https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements - MED
- Apple Ads restricted-content guidance for alcohol: https://ads.apple.com/policies - LOW-MED
- US Copyright Office position on AI-generated images: secondary coverage (e.g., https://blog.promise.legal/ai-game-assets-copyright-steam-disclosure-2026/) - MED; not legal advice
- Game-design pitfalls (stat soup, deduction information budgets, dominant strategies, content treadmills, collection attachment, solo-dev scope): synthesized from `brewfighter-design-v1.md`, PROJECT.md, and the prior research round (2026-10-06) - MEDIUM; not independently sourced
- Not verified this session: exact current App Store Connect screenshot pixel sizes, Korea GRAC requirements for this game, specific hop trademark registrations, per-country alcohol-app restrictions, whether the Declared Age Range API is mandatory for an 18+ game under Texas law, Apple Small Business Program eligibility details.

---
*Pitfalls research for: collectible brewing RPG, native Swift/SwiftUI iPhone, commercial solo App Store release*
*Researched: 2026-10-08*
