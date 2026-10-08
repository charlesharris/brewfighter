# Feature Research

**Domain:** Collectible brewing RPG (player-designed beers as "creatures", deduction-style patron encounters) as a native iPhone game, portrait, touch-first, commercial App Store release, monetization model (premium vs F2P+IAP) undecided
**Researched:** 2026-10-08
**Supersedes:** the 2026-10-06 desktop/Steam version of this file. Genre findings (deduction legibility, clue notebook, collection states, anti-grind) are carried forward in compressed form. Steam, Steam Deck, gamepad, keyboard-focus, three-OS and DragonRuby content is dropped.
**Overall confidence:** MEDIUM. Apple policy facts were read from developer.apple.com in October 2026 and cross-checked where possible (see Sources). The hybrid itself has no direct comparable, so differentiator value is reasoned judgment. Retention benchmarks and comparable-game observations come from secondary web sources and are LOW to MEDIUM. Items tagged (LOW) rest on training knowledge or a single secondary source and need a check before they drive a requirement.

---

## What Changes on Mobile (read this first)

| Area | Desktop/Steam assumption (old) | iPhone reality (new) |
|------|-------------------------------|----------------------|
| Session shape | 30-120 min sittings | Unpredictable 2-10 min sessions that are interrupted by calls, notifications, app switches. Every screen must be resumable at the exact state. |
| Input | Mouse/keyboard/gamepad, focus model | One thumb, portrait. Bottom-reachable primary actions, 44pt+ targets, no hover, no drag-only interactions. |
| Distribution gate | Steam page + content survey | App Review (human + automated), age rating questionnaire, privacy nutrition label, 4+-safe store metadata. |
| Subject-matter risk | "Avoid glorifying intoxication" (soft) | Alcohol is the entire subject. Expect a **18+ age rating** (see Alcohol section), which has live regional consequences in 2026. |
| Saves | Slots, manual save, cloud via Steam | Single continuous autosave; iOS may kill the app at any time; device-to-device continuity via iCloud backup/sync. |
| Accessibility | Remap, text scale | Dynamic Type, VoiceOver, Reduce Motion, Differentiate Without Color, Sufficient Contrast, and the new App Store Accessibility Nutrition Labels. |
| Monetization | Premium Steam price | Open question. The economy must not hard-code either answer (see Monetization Flexibility). |

---

## Feature Landscape

### Table Stakes (Users Expect These; Missing = Leave or Rejected)

#### A. Core collection-RPG table stakes (carried forward, adapted for touch)

| Feature | Why Expected | Complexity | Mobile adaptation / notes |
|---------|--------------|------------|---------------------------|
| Active tap lineup (6 beers) with swap, reorder, saved presets | Party management is the genre's core screen; reordering is gameplay (serving order) | MEDIUM | Reorder with tap-to-select-then-tap-slot as the primary path; drag as an enhancement only. Presets ("vs. hop-heads") matter because the player retunes per patron. |
| Collection codexes with Unknown / Seen / Known / Mastered states and completion % (Regulars Book, Ingredient Codex, Yeast Bank, Beer Library) | Dex-style completion drives collection; Pokemon TCG Pocket-style set-completion screens are what mobile collectors expect | MEDIUM | Grid of silhouettes at 3-4 columns; large tap targets; completion % header; filter by rarity/state. |
| Rarity tiers with distinct visual treatment (frame + icon + label, not color alone) | Rarity is the collector hook | LOW | Also satisfies "Differentiate Without Color Alone". |
| Per-entity detail card: attributes, traits, abilities, ancestry | Attachment forms at the card | MEDIUM | Sheet presentation (bottom sheet), attributes as labeled bars with numbers, must reflow at accessibility Dynamic Type sizes. |
| Matchup legibility (post-pour itemized breakdown, e.g. "+22 Hop Match, -12 Excess Bitterness") | Success criterion #2; without it deduction becomes frustration | MEDIUM | Short, scannable list; each line tied to an attribute icon. |
| Persistent per-patron clue notebook (auto-recorded, visible during beer selection) | Directly serves "deduction not frustration"; players cannot hold clues across interrupted sessions | MEDIUM | **Higher priority on mobile**: sessions are fragmented, so memory cannot be assumed. Each dialogue reaction must be tagged with the structured fact it reveals. |
| Low-cost retry on failed encounters that preserves revealed clues | Short sessions mean a lost encounter must not feel like lost time | LOW | Retry in one tap from the result screen. |
| Clear progression gating, telegraphed boss rules | Unhinted boss rules are the genre's main review complaint | MEDIUM | Each boss rule hinted via a Regulars Book entry or a bartender regular. |
| Rewards after wins (ingredient, yeast, patron progress, recipe) | Win-loot-build loop | LOW | Content work more than engineering. |
| Nicknaming beers with auto-generated defaults | Ownership | LOW | iOS keyboard handles input; name generator makes naming optional. |
| Live outcome preview while brewing (attribute bars update as choices change) | Biggest crafting UX requirement | HIGH | Stepped wizard (Mash, Boil, Ferment, Condition) with a persistent preview strip pinned near the top and the active choice controls in the thumb zone. |
| Recipe journal: auto-saved brews, favorite/pin, search/filter, one-tap "brew again" | Repetition fatigue is the crafting-sim complaint; mobile amplifies it | MEDIUM | Quick rebrew should be 2 taps. |
| Discoverable ingredient properties (traits reveal through use) | Discovery is the crafting reward | MEDIUM | Show "?" for undiscovered traits. |
| Fast first session: first encounter within about 90 seconds, progressive disclosure of brewing variables | First-session drop-off is the main mobile retention cliff | MEDIUM | Median mobile D1 retention is about 22% and D7 about 4% (LOW-MEDIUM, secondary summaries of 2025 GameAnalytics data); iOS runs higher. A premium game cares less about D1 but the first five minutes still decide reviews and refunds. |
| Distinct, memorable patrons with portraits and 3-4 expression states | Characters are the product (Kyle, Patio Dad) | HIGH | 25-40 patrons plus 8 bosses for one-city v1 (design doc says 8 bosses). Content budget dominates schedule. |
| Atmosphere: music, UI sounds, pour SFX | Silence reads as unfinished | MEDIUM | Gap: audio sourcing unspecified. See iPhone section for audio-session behavior. |

#### B. iPhone game table stakes (new this round)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Instant resume to exact state after interruption or kill.** Persist after every committed action: each pour in an encounter, each wizard step in a brew, each purchase. Restore on cold launch into the same screen. | iOS suspends and terminates apps freely; calls, notifications, Control Center, app switches are constant. Losing a half-finished encounter is the top-tier mobile sin. | MEDIUM-HIGH | Observe `scenePhase` (`.inactive`/`.background`) to flush saves. Encounter state machine must be fully serializable. No mid-animation unrecoverable states. |
| Short, interruptible core loop: one brew plus one encounter completable in about 3-5 minutes; no mandatory long cutscenes | Typical mobile sessions are 2-5 minutes (LOW-MEDIUM, secondary sources) | MEDIUM | Design constraint on content authoring: dialogue skippable, results screens dismissible with one tap. |
| Fully offline play, no account, no server | Phones lose connectivity constantly; Pokemon TCG Pocket's always-online requirement is a recurring complaint (LOW-MEDIUM) | LOW | Also makes "Data Not Collected" privacy label achievable (see App Store section). No login means Sign in with Apple (4.8) and account deletion (5.1.1(v)) never apply. |
| Atomic, versioned local save (write temp then replace, schema version, migrations) in Application Support | Long-lived state (lineage DAG, yeast generations) will be patched; corrupted saves destroy trust | MEDIUM | Files in Application Support are included in iCloud device backups for free. This covers "new phone" for most players. |
| Cold start to interactive in about 2 seconds, resume from background in under 1 second | Mobile players abandon slow launches | MEDIUM | Avoid loading all procedural art at launch; lazy-load. Profile on the oldest supported device. |
| One-handed portrait layout: primary actions in the lower 40% of the screen, bottom tab bar or bottom sheets, no critical controls in top corners | Project constraint; thumb reach is the iPhone usability baseline | MEDIUM | Test iPhone SE size through Pro Max. Respect safe areas / Dynamic Island. iPad runs scaled (project decision): verify letterboxed layout does not break. |
| Touch targets at least 44x44pt; every gesture has a visible tap alternative | Apple HIG baseline (MEDIUM, widely documented, not re-fetched this round) | LOW | Swipe-to-delete, drag-to-reorder always paired with a button path. |
| Haptics: `sensoryFeedback` / `UIFeedbackGenerator` for tap confirm, pour result tiers, Perfect Pour, rarity reveal; Core Haptics only for 1-2 signature moments (the pour) | Haptics are a core part of "satisfying tap" feel on iPhone. Apple guidance: reserve for meaningful moments, pair with visual/audio, always provide an off switch | LOW-MEDIUM | Settings toggle (and optional intensity). Never the sole carrier of information. |
| Audio session behavior: mix with other audio by default, respect silent switch for SFX, separate music/SFX volume | Players listen to podcasts while playing; unexpected audio hijack gets one-star reviews | LOW | Default music to off-or-low if other audio is playing. |
| **Dynamic Type** throughout (SwiftUI semantic fonts, `@ScaledMetric`, layouts that reflow at accessibility sizes) | Apple's Larger Text label requires all common tasks to work at larger sizes; dense 16-attribute screens are the hard case | MEDIUM-HIGH | Attribute display must switch from side-by-side to stacked at large sizes. Test at AX5. This is a layout-architecture decision, not a polish pass. |
| **VoiceOver** labels and values on all controls; attribute bars read as "Bitterness 4 of 10, patron dislikes" | Apple Accessibility Nutrition Label criteria: perceive, operate and understand all common tasks | MEDIUM | Custom accessibility values for bars/radars; announce pour results and clue reveals. |
| Reduce Motion alternative for pour/particle/count-up animations; Differentiate Without Color Alone; Sufficient Contrast; Dark Mode decision | Part of the nine Accessibility Nutrition Label features (VoiceOver, Voice Control, Larger Text, Dark Interface, Differentiate Without Color Alone, Sufficient Contrast, Reduced Motion, Captions, Audio Descriptions) | MEDIUM | Labels are **voluntary now but Apple says they will become required** to submit apps and updates. Claim only what is fully true: a claim requires ALL common tasks to work. AdCap-style bright palette needs contrast verification. |
| Settings screen: music / SFX volume, haptics toggle, reduce-motion override, text size note, restore purchases (if any IAP), privacy policy link, support link, credits, reset/delete save, "drink responsibly" note | Privacy policy must be reachable in-app (5.1.1); reviewers and players expect these | LOW-MEDIUM | Settings persisted separately from the save. |
| Onboarding via mentor character with staged unlock of brewing variables and attributes | A 16-attribute deduction game is dense; onboarding is the main retention risk | HIGH | Teach one attribute pair first (bitterness + aroma), reveal the rest over the first hours. Design progressive disclosure before the data model hardens. |
| Crash resilience: no force-unwrap crashes in save loading; recover from corrupt save to last good backup | App Review rejects crashing builds (2.1); crash complaints dominate early reviews | MEDIUM | Keep one rolling backup of the previous save. Xcode Organizer / MetricKit give crash data without third-party SDKs. |
| Confirm-before-destructive actions, with "archive instead of delete" for beers (protects lineage) | Basic UX hygiene | LOW | |
| Review prompt used sparingly (`requestReview` once after a high moment, never on launch) | Avoid review-nag backlash | LOW | System rate-limits prompts (LOW: about 3 per 365 days, from training knowledge). |
| Notifications: **none required**. If used at all, local only, opt-in, requested in context after the first win | Guideline 4.5.4: notifications must not be required for app function; marketing needs explicit opt-in with an opt-out | LOW | With no timers or energy there is little to notify about. Defer to post-launch. |

#### C. App Store / App Review table stakes (verified this round against developer.apple.com)

| Requirement | Why it is table stakes | Complexity | Notes |
|-------------|------------------------|------------|-------|
| **Honest age rating questionnaire in App Store Connect** (new scheme with 4+, 9+, 13+, 16+, 18+ since iOS 26) | 2.3.6: answer honestly; mismatch risks rejection or removal. Rating also drives regional gating | LOW | Alcohol/tobacco/drug use or references: infrequent maps to 13+, frequent maps to 18+. See Alcohol section; plan for 18+. Questionnaire now also asks about social media capability (required for new submissions from September 2026): answer no. |
| **Privacy policy URL** in App Store Connect and reachable in-app | 5.1.1; required field | LOW | Short policy is enough if there is no data collection. |
| **App Privacy ("nutrition") label** completed accurately | Required; developer is responsible for third-party SDK collection; crash/performance diagnostics count as collected data if they leave the device | LOW if zero SDKs, MEDIUM-HIGH with analytics/ads | The strongest privacy-posture decision: no third-party SDKs means a clean "Data Not Collected" style label and no ATT prompt. Any analytics/ads SDK changes this. |
| **PrivacyInfo.xcprivacy** with required-reason API declarations | Enforced since May 2024; `UserDefaults` (reason code CA92.1), file timestamp, disk space, boot time, active keyboard APIs need declared reasons | LOW | SwiftUI `@AppStorage` and file APIs trigger this. Missing declarations cause automated rejection emails. |
| Build with the iOS 26 SDK / Xcode 26 or later | Apps uploaded since 28 April 2026 must use it (MEDIUM) | LOW | Deployment target can still be lower; see Gaps. |
| **Screenshots**: 1-10 per size; at minimum a set for the 6.1" Dynamic Island size (1179x2556 or 1206x2622 portrait); other sizes scale automatically if the UI is consistent; no alpha channel; jpeg/png | Required to submit (MEDIUM: Apple page fetched; secondary sources claim a 6.9" set, so confirm in App Store Connect at upload time) | LOW-MEDIUM | Screenshots must show the app in use, not title art (2.3.3). Apple published new screenshot-issue guidance on 5 Oct 2026. |
| **Store metadata appropriate for a 4+ audience** (screenshots, previews, icon) even though the app is rated higher | Guideline 2.3.8. Directly affects an alcohol game's marketing | MEDIUM | No people drinking, no drunkenness, no gratuitous beer-pouring close-ups; lead with characters, tap list UI, ingredient cards and recipe lineage. Treat beer-glass imagery as a review risk to test, not a guarantee (MEDIUM, interpretation). |
| App preview (optional): 15-30 s, up to 3, portrait 886x1920, captured from the device | 2.3.4: device screen capture only | LOW-MEDIUM | Same 4+ rule applies. |
| Reviewer notes explaining the theme: fictional adult characters, no real alcohol sales/ordering, no encouragement of excessive drinking, 18+ rating declared | Reduces back-and-forth on 1.4.3 | LOW | Include a short walkthrough since there is no login. |
| Metadata completeness: support URL, copyright, category (Games > Role Playing or Simulation), name 30 characters or fewer, no keyword stuffing, IAP disclosed in description/screenshots if any (2.3.2) | App Completeness (2.1) | LOW | No placeholder text, working URLs. |
| IAP hygiene **if any IAP exists**: all unlocks through StoreKit (3.1.1), restore purchases button, purchased currency never expires, randomized purchasable items must disclose odds before purchase | Apple 3.1.1 | MEDIUM | See Monetization Flexibility. |
| Age-assurance readiness (Declared Age Range API) for regions with legal requirements | Apple states even 18+ apps must call the API in regions where legally required, to check age category; Texas (4 June 2026), Utah (6 May), Louisiana (1 July), plus Apple blocking 18+ downloads for unconfirmed accounts in Australia, Brazil, Singapore from 24 February 2026 | MEDIUM | Apple's own docs were thin on exactly what an offline, no-account 18+ game must do. Needs a dedicated check against the age-assurance Q&A and likely legal review before submission. API is iOS 26 era: deployment target interacts (see Gaps). Texas SB 2420 is in active litigation (MEDIUM, secondary). |
| Territory selection | Alcohol content may be restricted by law/rating regime in some countries (Korea requires GRAC rating for games; China requires a license; Vietnam has its own rating rules) | LOW | Launch in US, Canada, UK, EU, Australia, New Zealand; deselect others at first. Territory legality (LOW, partly training knowledge). |
| Export compliance answer (no non-exempt encryption) and TestFlight external beta before submission | Standard pipeline hygiene | LOW | |

---

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Sensory-profile matchup layer (about 16 attributes vs hidden patron palate), explicitly not style-matching | Defining mechanic; no mobile comparable. Makes two IPAs different "creatures" | HIGH | Pure, headless-testable scoring module; simulate thousands of pairs for balance. |
| 3-pour deduction encounter with clue reveals | Wordle/Obra Dinn-like satisfaction in a 2-minute mobile-sized puzzle; fits fragmented sessions better than long battles | HIGH | Three pours is itself the brute-force limiter. |
| Serving-order status effects (6-8 at launch) | Turns "pick best beer" into sequencing | MEDIUM | Cap the count for legibility. Rename or soften intoxication-flavored statuses (see Alcohol section). |
| Recipe evolution with preserved ancestry (family tree) | Attachment engine; "my saison's grandchild" | MEDIUM-HIGH | Lineage DAG and yeast generations share bookkeeping. Tree UI must work in portrait (vertical tree with pinch/scroll). |
| Yeast Bank with rarity and bounded mutation | Rare-collectible hook unique to the setting | MEDIUM-HIGH | Deterministic-seeded mutation so results are explainable. |
| Ingredient synergies and drawbacks | Identity beyond +N stats | MEDIUM | Keep the graph explainable. |
| Regulars Book with passive benefits | Collection of people with world-linked rewards | MEDIUM | Only benefits that plug into v1 systems. |
| Boss encounters as rule-modifiers (8 in v1) | Marketable set pieces, progression gates | MEDIUM | Telegraph each rule. |
| Procedurally rendered beer glass (SRM color, head, carbonation) from attributes, drawn with SwiftUI `Canvas`/shapes | High collectible payoff per effort; resolves the AI-art consistency risk for the most repeated asset | MEDIUM | Also the hero asset for the share card. |
| **AdCap-feel "juice" on numbers**: chunky buttons with press states, count-up score tallies with haptic ticks, pop-in reward animations, bright flat palette | Gives the "satisfying to tap" feel that sets it apart from drab brewing sims; low cost in SwiftUI | MEDIUM | Reference only; no idle mechanics. Respect Reduce Motion. |
| **Ritual reveal moments without gambling** (new yeast culture, rare ingredient, patron "becomes a Regular"): staged animation, Core Haptics signature, deterministic or earned rewards | Delivers the Pokemon TCG Pocket pack-opening emotional beat (players praise the tactile pack opening) without a loot box | MEDIUM | Keeps Apple 3.1.1 odds disclosure and the "simulated gambling" rating descriptor out of scope. |
| Real-brewing learning codex and tooltips | Brand promise (70% genuine beer culture); appeals to craft-beer players | MEDIUM | Writing and accuracy review. |
| Share-sheet beer card (image: glass, name, attributes, lineage) via `ShareLink` | Free social marketing from craft-beer audience; supports "my beer as a character" | LOW-MEDIUM | Local image only, no server. Not recipe trading. Mind 4+ metadata rule only for store assets, not user shares. |
| Colorblind-safe, VoiceOver-complete deduction UI | Rare in the genre; also earns honest Accessibility Nutrition Labels, which are shown on the product page | MEDIUM | Marketing-visible differentiator on iOS 26+ product pages. |
| iCloud sync (CloudKit) of the save across iPhone and iPad | Seamless device continuity | MEDIUM-HIGH | Backup alone covers new-phone restores; true sync adds conflict-resolution scope. P2/post-launch candidate. |
| Game Center **achievements** (discovery/mastery based) | Surfaces the game in Game Center / Apple Games app, "Friends are playing", widgets | LOW-MEDIUM | Requires the Game Center capability and App Store Connect configuration. Achievements only; no leaderboards (see Anti-Features). |
| Daily "Special Request" patron seeded from the local date (offline) | Gentle reason to return without server, timers or streak punishment | LOW-MEDIUM | Optional; never gate progress on it. |
| Home Screen widget showing the tap list or Regular of the day (WidgetKit) | Retention surface native to iOS | MEDIUM | P3; post-launch. |
| Beer-culture comedy writing grounded in recognizable archetypes | The 70/30 tone is the brand | HIGH (content) | Budget revision passes. Rename trademark-bearing jokes (see Pitfall list below). |

---

### Anti-Features (Deliberately NOT Build)

| Anti-Feature | Why It Is Requested | Why Problematic (esp. on iOS) | Do Instead |
|--------------|--------------------|-------------------------------|-----------|
| Gacha/loot-box beers, yeasts or ingredients (randomized purchasable items) | Proven F2P revenue; mirrors pack opening | Apple 3.1.1 requires pre-purchase odds disclosure; Australia now rates loot-box apps 16+ (and a game with simulated gambling can reach 13+/18+); it destroys the "authored beer" fantasy and attribution | Earned, deterministic or visible-pity rewards; ritual reveals without purchase. |
| Interstitial or rewarded ads | F2P default | Alcohol-themed 18+ app limits ad networks and creative; ad SDKs force a heavier privacy label and ATT; breaks cozy tone | If F2P: IAP only, no ad SDK. |
| Energy / stamina / real-time fermentation timers / appointment mechanics | Mobile F2P standard; "authentic brewing" | Punishes short sessions, complicates saves, conflicts with retry-instantly design and the project's no-idle decision | Fermentation as a choice variable resolved instantly. |
| Idle/offline-earnings mechanics | AdCap reference | Project explicitly rules out real idle mechanics | Borrow the UI feel only. |
| Dual currency (soft + hard/premium) from day one | Standard F2P economy | Locks the economy into F2P; hard to remove without rebalancing | One soft currency or none (see Monetization Flexibility). |
| Accounts, login, server backend, cloud profiles | Cross-device, analytics | Adds Sign in with Apple (4.8), account deletion (5.1.1(v)), data collection disclosure, privacy risk | Offline local save plus iCloud backup/sync. |
| Chat, UGC, public sharing hub, multiplayer, leaderboards, recipe trading | Community | Triggers messaging/UGC rating descriptors and Guideline 1.2 moderation duties; netcode and support costs; out of scope per PROJECT.md | Local share card. |
| Push notification marketing, streak-loss guilt notifications | Retention | 4.5.4 requires explicit opt-in for marketing; reads as manipulation (5.6 code of conduct warns against tricking users) | None in v1. |
| Linking to buy real beer, delivery, retailer affiliate links, or alcohol sale facilitation | Monetization idea for beer audience | Alcohol commerce brings licensing and age-gating obligations under 1.4.3 and local law | Keep the game fictional. |
| Real brand/trademark content (Untappd, real brewery logos, trademarked hop names) | Authenticity and jokes | IP guidelines (5.2) and brand risk (LOW: legal interpretation, verify). The design doc names "The Untappd Guy" and Citra. | Fictional parody names ("The Rating Guy", app-of-the-moment parody); generic or invented hop/ingredient names unless clearance is confirmed. |
| Glorifying intoxication ("get patrons drunk", chugging, drinking games) | Comedy | Directly adjacent to 1.4.3 (excessive consumption) and to the "frequent depiction" age-rating tier; Apple staff reportedly stopped allowing drinking-game apps (LOW: forum anecdote from 2020-21) | Intoxication-flavored statuses become palate effects ("Mellow", "Loosened Up") rather than drunkenness goals. |
| Mini-game brewing (QTE stirring, timing bars) | Tactile fun | Accessibility burden, undermines deliberate recipe design | Optional light animation only. |
| Large status-effect zoo (15+) | Depth | Legibility collapse | 6-8 at launch. |
| Procedurally generated patrons | Infinite content | Loses personality comedy and clue reliability | Hand-authored from templates. |
| Permadeath / losing beers on failure | Stakes | Conflicts with attachment | Retry only. |
| Hidden preferences with no discoverable evidence | Cheap difficulty | Violates deduction-not-frustration | Every hidden trait inferable from at least one clue channel. |
| Grind/XP gating | Padding | Conflicts with knowledge-driven loop | Gate on knowledge and recipe quality. |
| Landscape or native iPad layouts, Apple Watch, App Clips, Live Activities in v1 | Platform coverage | Doubles QA and design for little return | Portrait iPhone only; revisit post-launch. |
| Third-party analytics/attribution SDKs in a premium build | Data-driven iteration | Expands privacy label; may trigger ATT | Xcode Organizer + MetricKit + TestFlight feedback. |
| Review-gating or aggressive rating pop-ups | Ratings | Reputation and 5.6 conduct issues | One system prompt after a win. |

---

## Alcohol-Themed App Review: What Is Actually Required

**Verdict:** Allowed, with caveats. Beer-brewing games already exist on the iPhone App Store (Fiz: Brewery Management, Brew Town, Idle Brewery, Brewery Boss, all found in a search of the store, with Fiz and Brew Town listed at the old 17+ tier; MEDIUM, store listings via search). The rules are about encouragement, age rating and metadata, not the topic.

| Topic | What Apple says (current as read Oct 2026) | Implication for Brew Fighter | Confidence |
|-------|-------------------------------------------|------------------------------|-----------|
| Guideline 1.4.3 | Apps that encourage consumption of tobacco/vape, illegal drugs, or **excessive** amounts of alcohol are not permitted. Apps that encourage minors to consume are rejected. Facilitating the sale of controlled substances or tobacco is not allowed. | A brewing/tasting game is fine. Avoid: reward loops for drinking more, "drunk" as a goal, minors as patrons, chugging/drinking-game mechanics, linking to alcohol sales. | MEDIUM |
| Age rating | Descriptor "Alcohol, Tobacco, or Drug Use or References": **infrequent = 13+, frequent = 18+**. Definition: references to or depictions of the consumption of alcohol, including drunken behavior. Apple does not publish thresholds for infrequent vs frequent. | Alcohol is on every screen. **Plan and design for 18+.** A 13+ outcome is not realistically defensible and answering to get 13+ risks rejection or later removal (2.3.6). | MEDIUM |
| Rating consequence: 18+ gating | Since 24 Feb 2026, accounts in Australia, Brazil and Singapore cannot download 18+ apps unless confirmed as adults. Utah, Louisiana and Texas age-assurance regimes started May-July 2026. | Smaller reachable audience in some regions; probably acceptable for a craft-beer audience of legal drinking age. Build and test Declared Age Range handling. | MEDIUM |
| Store metadata | Guideline 2.3.8: icons, screenshots and previews must be suitable for a 4+ audience even if the app is rated higher. | Marketing creative cannot lean on beer-drinking imagery. Showcase characters, tap handles, recipe cards, ingredient art. | MEDIUM (text read; reviewer strictness on beer glasses is unknown) |
| Advertising the app | Apple Ads policy: alcohol ad content may be restricted by country, must be age-appropriate, and the policy table allows alcohol ads on Search Results placements only (not Today tab, Search tab, or Product Page) (LOW-MEDIUM, summary of a policy table). | Apple Search Ads budget is constrained; plan organic, creator, and community marketing (beer communities, homebrew forums). | LOW-MEDIUM |
| Kids Category / child data | Kids Category and 5.1.4 do not apply to an 18+ game. | Do not target or tag as kids. No "For Kids" language. | MEDIUM |
| Age-assurance APIs | Apple Q&A: developers are responsible for their own age restrictions; in regions where legally required, 18+ apps must also check age with Declared Age Range. | Include an age-check hook; scope with legal review. | MEDIUM |
| In-app messaging | Include a visible "drink responsibly / for adults of legal drinking age" note in Settings and an age statement in the description. | Cheap, signals good faith to reviewers. | LOW (recommendation, not a stated rule) |

**Design-level mitigations (cheap now, expensive later):**
1. Keep encounters about tasting, taste matching and craft; the win condition is "satisfaction", never intoxication level.
2. Rebrand "Buzzed" and "Wrecked Palate" as palate-effect statuses with non-drunk framing (e.g., "Mellow", "Palate Shock"). The 6-8 status cap leaves room.
3. All patrons are clearly adults; pours are small tasting pours.
4. No real-brand content; no links to buy alcohol.
5. Dry-run the age rating questionnaire in App Store Connect in the first phase, before art direction for store assets is locked, so the 18+ result is a known input and not a late surprise.

---

## Monetization Flexibility (what the economy must keep open)

Decision is deferred, but the economy phase depends on it. Research recommendation: **lean premium (paid upfront or free-download with a single full-game unlock)** because: the product is a knowledge/deduction game whose value is lost under timers or energy; 18+ alcohol rating narrows ad inventory and Apple Ads placement; loot-box mechanics collide with 3.1.1 and the authored-beer fantasy; and systems-deep premium mobile games have succeeded (Balatro at $9.99 on iOS and Apple Arcade; Stardew Valley's first three weeks on iOS exceeded $1M; LOW-MEDIUM secondary sources, while the same sources note premium remains a niche share of mobile revenue and average premium titles struggle). The Small Business Program gives a 15% commission on the first $1M of proceeds (MEDIUM). Nothing below forecloses F2P; it just keeps it cheap to add.

| Design constraint to apply now | Keeps premium open | Keeps F2P+IAP open |
|-------------------------------|--------------------|--------------------|
| All content reachable through play; no content that can only be bought | Required | IAP can later sell convenience (cosmetics, shortcuts), not gates |
| Single soft currency (or none), with a data-driven ledger of sources and sinks | Simple economy | Can add a sink for a purchasable pack without a rebalance |
| Entitlement layer abstraction (`isFullGameUnlocked`, `hasPurchased(productID)`) behind a protocol, StoreKit 2 wired but unused in premium | One paid unlock = one entitlement | Consumable and non-consumable products plug in |
| A natural content seam (end of first district / first N bosses) where a "free then unlock" gate could sit | Ignored | Supports free-download-with-unlock (Apple requires unlocks through IAP; demos on the App Store are not allowed, TestFlight only) |
| No randomized rewards tied to purchases | Avoids odds disclosure | Avoids 3.1.1 odds disclosure and Australia 16+ loot-box bump |
| No timers/energy as the pacing mechanism | Cozy pacing | Pacing then comes from content depth, so F2P cannot "sell time" (accepted trade-off) |
| Analytics behind a protocol; default is local-only | Clean privacy label | A vendor SDK can be added later with an updated label |
| Cosmetic layer separate from mechanics (glassware, tap-handle skins, portrait frames) | Free cosmetic unlocks as rewards | Purchasable cosmetics without affecting balance |
| Restore Purchases wired in Settings from the start | Harmless | Required once IAP exists |

Features whose scope changes by model: ad SDK and ATT (F2P only), starter-pack/offers UI (F2P only), receipt/entitlement validation (both, via StoreKit 2 on-device), price-tier localization (both), App Store "free trial"/intro offers (subscription only; not recommended).

---

## Mobile Comparables: What They Teach

| Comparable | Borrow | Avoid / Note | Confidence |
|------------|--------|--------------|------------|
| **AdVenture Capitalist / idle games** (UI feel only) | Operating screen that shows profit, cost and time per item at a glance; big buy buttons with clear cost; bright flat palette; satisfying count-ups; bottom-reachable actions; "welcome back" summary modal (adapt to "where you left off") | Offline earnings, prestige/angel resets, manager automation: not gameplay for this project | MEDIUM |
| **Pokemon TCG Pocket** | Tactile pack-opening ritual; set-completion screens; missions; low-friction daily engagement | Always-online requirement, pay-to-win perception, matchmaking complaints, trading limits (all recurring complaints, LOW-MEDIUM) | LOW-MEDIUM |
| **Pokemon GO** | Dex/evolution attachment loop; collection completion as motivation | Live-ops and location dependence: not reproducible offline | LOW-MEDIUM |
| **Cozy mobile sims** (Kairosoft-style management, Stardew mobile) | Short management decisions, charming characters, touch-adapted UI (large tappable lists, sheets) | Dense stat tables without hierarchy; ports that keep desktop UI | LOW (training knowledge plus generic search) |
| **Premium systems-deep mobile hits** (Balatro mobile, Stardew Valley) | Evidence that a one-time-price, no-IAP strategy/progression game can win on iOS and Apple Arcade | Their success is atypical; premium remains a small share of revenue | LOW-MEDIUM |
| **Existing beer-brewing mobile games** (Fiz, Brew Town, Idle Brewery, Brewery Boss) | Precedent that alcohol-themed brewing games pass App Review at 17+/18+ | They are management/idle games; none is a deduction RPG, so the niche is open | MEDIUM |

---

## Feature Dependencies

```
Serializable game-state model (encounter, brew wizard, inventory, lineage)
    └──requires──> Versioned atomic save in Application Support
                       └──enables──> Instant resume after interruption
                       └──enables──> iCloud backup/restore, later CloudKit sync

Attribute data model (16 attributes) + palate model
    └──requires──> Headless scoring engine ──requires──> Itemized pour breakdown
                                                └──requires──> Structured clue tags
                                                                  └──enables──> Clue notebook, Regulars Book progress
    └──requires──> Brewing computation ──requires──> Live preview UI ──enables──> Procedural beer glass ──enables──> Share card

Dynamic Type / VoiceOver / Reduce Motion layout rules (decided at first screen)
    └──requires──> Every later screen (retrofit is expensive)
    └──enables──> Honest Accessibility Nutrition Labels

Age rating dry-run (App Store Connect) ──informs──> Status-effect naming, marketing creative, territory list
    └──requires──> Declared Age Range handling (late phase) ──requires──> legal check, deployment-target decision

Privacy posture (no third-party SDKs) ──enables──> "Data not collected" label, no ATT, simple review
    └──conflicts──> Ad SDKs, vendor analytics

Entitlement abstraction ──enables──> Premium unlock or IAP later (decision gate before economy phase)
Economy sink/source ledger ──requires──> Monetization decision (soft currency scope)

Onboarding ──requires──> Stable brewing + encounter UI; progressive-disclosure design must precede the data model
Game Center achievements ──requires──> Stable discovery/mastery event list (post-systems)
Store assets (screenshots/preview) ──requires──> Stable UI + 2.3.8 creative rules + rating result

Gacha/loot boxes ──conflicts──> Authored-beer fantasy, 3.1.1 odds disclosure
Real-time timers ──conflicts──> Interruptible short sessions, instant retry
Large status zoo ──conflicts──> Encounter legibility
Style-lookup matching ──conflicts──> Sensory-profile matchup layer
```

### Dependency Notes

- **Accessibility layout rules come first.** The 16-attribute screens are the hardest Dynamic Type case. Decide stacked vs side-by-side reflow when designing the first card, not in a polish phase.
- **Save/resume is architecture, not a feature.** Encounter and brew flows must be modeled as serializable state machines from the start; adding resume later means rewriting them.
- **Structured clues, not free text.** Each reaction line carries tags for the facts it reveals so the notebook and Regulars Book populate automatically.
- **Age rating and monetization are two project-level decision gates** that touch many features: schedule the questionnaire dry-run and the premium/F2P decision before the economy and store-asset phases.
- **Passive benefits require the systems they affect:** do not ship a chef benefit without food pairing.

---

## MVP Recommendation

### Launch With (v1)

1. Serializable state, versioned atomic save, instant resume (architecture, first)
2. Attribute data model, brewing computation, live preview wizard
3. Palate model, scoring engine, 3-pour encounter with itemized breakdown and clue notebook
4. Tap lineup (6) with serving order and 3-4 statuses first, 6-8 by launch
5. Recipe journal with quick rebrew; recipe ancestry data (tree UI later)
6. Portrait one-handed UI system with Dynamic Type, VoiceOver, Reduce Motion, haptics and AdCap-style juice
7. Mentor onboarding with progressive disclosure
8. Patrons, bosses, locations to one-city scale; Regulars Book; Yeast Bank (mutation after lineage model is proven)
9. Settings, privacy policy, support, restore-purchases hook, "drink responsibly" note
10. App Store package: 18+ questionnaire, privacy label, PrivacyInfo.xcprivacy, 4+-safe screenshots/preview, reviewer notes, territory list, Declared Age Range handling, TestFlight beta
11. One differentiator beyond core: procedural beer glass (it also feeds store creative and the share card)

### Add After Validation (v1.x)

- Share-sheet beer card, Game Center achievements, iCloud sync, family tree polish
- Expanded statuses and synergy graph, assist options (hint on demand)
- Daily Special Request patron, WidgetKit widget, localization
- Optional local notifications (opt-in)

### Future (v2+)

- Regions, brewery/taproom management, food pairing, barrel programs (all deferred per PROJECT.md)
- Android (separate native effort), iPad-native layouts

### Feature Prioritization Matrix

| Feature | User Value | Cost | Priority |
|---------|-----------|------|----------|
| Resume/save architecture | HIGH | MEDIUM-HIGH | P1 |
| Scoring engine + itemized breakdown | HIGH | HIGH | P1 |
| Brewing wizard with live preview | HIGH | HIGH | P1 |
| 3-pour encounter + clue notebook | HIGH | HIGH | P1 |
| One-handed portrait UI + Dynamic Type + VoiceOver | HIGH | MEDIUM-HIGH | P1 |
| Onboarding | HIGH | HIGH | P1 |
| Tap lineup + presets, statuses | HIGH | MEDIUM | P1 |
| Patron/boss content | HIGH | HIGH | P1 |
| App Store package (rating, privacy, metadata) | HIGH (gate) | MEDIUM | P1 |
| Age-assurance handling | MEDIUM (gate in regions) | MEDIUM | P1 late |
| Haptics + juice | MEDIUM-HIGH | LOW-MEDIUM | P1/P2 |
| Procedural beer glass | MEDIUM-HIGH | MEDIUM | P2 |
| Recipe ancestry tree UI | MEDIUM | MEDIUM | P2 |
| Yeast mutation, synergies, passive benefits | MEDIUM | MEDIUM-HIGH | P2 |
| Brewing codex | MEDIUM | MEDIUM | P2 |
| Game Center achievements | LOW-MEDIUM | LOW-MEDIUM | P2/P3 |
| Share card | LOW-MEDIUM | LOW-MEDIUM | P3 |
| iCloud sync | MEDIUM | MEDIUM-HIGH | P3 |
| Widget, daily patron, notifications | LOW | MEDIUM | P3 |

---

## Gaps and Decisions Needed Before Requirements

1. **Accept an 18+ rating?** Strong recommendation yes. Run the questionnaire dry-run early to confirm.
2. **Premium vs F2P:** research leans premium or free-with-unlock; decide before the economy phase; apply the flexibility constraints now.
3. **Minimum iOS version:** iOS 17 gives `sensoryFeedback`, Observation and SwiftData (training knowledge, MEDIUM); Declared Age Range and Accessibility Nutrition Labels are iOS 26-era. Decide how an 18+ game behaves on older iOS where the age API is absent (needs a check of Apple's age-assurance Q&A).
4. **Name/IP clearance:** "The Untappd Guy" and trademarked hop names (e.g., Citra) in the design doc (LOW; verify with counsel).
5. **Territory list** and whether to skip Korea, China, Vietnam and Middle East.
6. **Game Center yes/no** (achievements only recommended) and **iCloud sync yes/no** for v1.
7. **Dark Mode** support and which Accessibility Nutrition Label claims to make.
8. **Audio sourcing** (music/SFX): still unspecified.
9. **Patron and boss counts** for the one-city v1 (content budget drives schedule).
10. **Economy model:** ingredients as permanent unlocks (recommended) vs consumables; failure cost (recommended: retry only).
11. **Screenshot spec check:** confirm required sizes in App Store Connect at upload time (Apple's page lists 6.1" as required; secondary sources say 6.9"; the page also lists a future foldable size).

---

## Sources

- Apple App Review Guidelines (1.4.3, 2.1, 2.3.x, 3.1.1, 4.5.4, 5.1.x, 5.3; page dated 8 June 2026): https://developer.apple.com/app-store/review/guidelines/ - MEDIUM (fetched and summarized; 2.3.8 and 1.4.3 wording read directly)
- Apple age ratings values and definitions (alcohol infrequent = 13+, frequent = 18+): https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions - MEDIUM (cross-checked with search summaries)
- Apple developer news 2026 (age ratings, Texas SB 2420, age assurance, App Review updates): https://developer.apple.com/news/ ; https://developer.apple.com/news/?id=sg176nne ; https://developer.apple.com/news/?id=ljpl7kyn - MEDIUM
- Apple age assurance Q&A: https://developer.apple.com/support/age-assurance - MEDIUM (thin on offline-18+ specifics)
- 18+ download blocking in Australia/Brazil/Singapore (24 Feb 2026): https://9to5mac.com/2026/02/24/apple-expands-age-assurance-tools-as-new-app-store-requirements-roll-out-in-several-regions/ ; https://www.helpnetsecurity.com/2026/02/25/apple-expands-age-verification-controls/ - MEDIUM
- New 13+/16+/18+ rating tiers: https://www.macobserver.com/news/apple-adds-new-app-store-age-ratings-13-16-and-18/ ; https://www.mactech.com/2025/07/25/apple-updates-age-ratings-in-its-various-app-stores - MEDIUM
- Apple App Privacy details: https://developer.apple.com/app-store/app-privacy-details/ - MEDIUM
- Required-reason API: https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api - MEDIUM
- Screenshot specifications: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications - MEDIUM; app previews: https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications - MEDIUM; secondary: https://ptkd.com/journal/app-store-screenshot-dimensions-2026 - LOW (conflicts on 6.9")
- Accessibility Nutrition Labels: https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels - MEDIUM
- Game Center overview: https://developer.apple.com/game-center/ - MEDIUM
- HIG haptics guidance: https://developer.apple.com/design/human-interface-guidelines/playing-haptics - MEDIUM (HIG games and accessibility pages did not return body text; related claims rely on training knowledge)
- Apple Ads policy (alcohol): https://ads.apple.com/policies - LOW-MEDIUM
- SDK requirement (Xcode 26 from 28 April 2026): https://expo.dev/blog/app-store-connect-minimum-sdk-26 - LOW-MEDIUM
- Texas SB 2420 status: https://developer.apple.com/forums/thread/810754 ; https://www.reedsmith.com/our-insights/blogs/viewpoints/102kddh/texas-law-requires-age-verification-for-app-stores-and-developers/ - MEDIUM
- Drinking-game App Review forum thread (anecdotal, 2020-21): https://developer.apple.com/forums/thread/649488 - LOW
- Beer-brewing game listings on the App Store: https://apps.apple.com/us/app/-/id1566591698 ; https://apps.apple.com/us/app/-/id1660298536 ; https://game-solver.com/brew-town/ - MEDIUM-LOW
- Mobile retention benchmarks (GameAnalytics 2025/2026 summaries): https://gamedevreports.substack.com/p/gameanalytics-mobile-gaming-benchmarks - LOW-MEDIUM
- Premium mobile viability (Balatro mobile, Stardew iOS): https://toucharcade.com/2024/09/05/balatro-mobile-release-date-price-download-apple-arcade/ ; https://www.notebookcheck.net/Stardew-Valley-raked-in-over-1-million-in-its-first-month-on-iOS.366871.0.html ; https://sensortower.com/blog/free-vs-paid-games - LOW-MEDIUM
- Pokemon TCG Pocket, AdCap, mobile session-design secondary sources (various, see search results) - LOW
- Carried forward from the 2026-10-06 round: genre sources on Potion Craft, Monster Sanctuary, Dave the Diver, Return of the Obra Dinn deduction design - MEDIUM
- App Store Small Business Program (15% on first $1M): https://revenuecat.com/blog/enroll-app-store-small-business-program - MEDIUM
- Project inputs: `/Users/charris/src/brewfighter/.planning/PROJECT.md`, `/Users/charris/src/brewfighter/brewfighter-design-v1.md`

---
*Feature research for: collectible brewing RPG, native iPhone (Brew Fighter)*
*Researched: 2026-10-08*
