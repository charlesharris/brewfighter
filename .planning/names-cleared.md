# Names-cleared log

Every player-facing name shipped in Brew Fighter, with the real-world analog it might be confused with and what was checked. This is a risk log, not legal advice. Roadmap research flag: names must be cleared before the App Store name reservation (plan 01-10) and before any marketing material.

Ingredient IDs are neutral (`grain.gNN`, `hop.hNN`, `yeast.yNN`, `adjunct.aNN`) and display names live only in the String Catalog (`content.<id>.name`). Renaming a display name therefore never touches saves, content JSON or tests.

Plan 01-04 appends style names.

| Name | Kind | Used as | Real-world analog / risk | Check performed | Status |
|------|------|---------|--------------------------|-----------------|--------|
| Brew Fighter | App name | App Store name, home-screen name, `CFBundleDisplayName` | Similarity to Capcom's "Street Fighter" (fighting-game franchise, registered marks in games). Different goods and a different second word, but the "-Fighter" construction is shared. | Informal comparison only | needs human trademark search before ASC name reservation (plan 01-10) |
| Solstice | Hop | `content.hop.h01.name` | Citrus-tropical hop family; generic English word | Compared against the known commercial hop variety list by eye; not matched | fictional; USPTO search pending |
| Old Meadow | Hop | `content.hop.h02.name` | Herbal-spicy noble-style hop family | Compared against the known commercial hop variety list by eye; not matched | fictional; USPTO search pending |
| Timberline | Hop | `content.hop.h03.name` | Piney-resinous high-alpha hop family; "Timberline" is a common place and product word | Compared against the known commercial hop variety list by eye; not matched | fictional; USPTO search pending |
| Island Haze | Hop | `content.hop.h04.name` | Juicy tropical hop family; "Haze" overlaps the hazy-IPA style vocabulary | Compared against the known commercial hop variety list by eye; not matched | fictional; USPTO search pending |
| Garden Gate | Hop | `content.hop.h05.name` | Earthy-floral English-style hop family | Compared against the known commercial hop variety list by eye; not matched | fictional; USPTO search pending |
| Bright Peel | Hop | `content.hop.h06.name` | Citrus-peel hop family | Compared against the known commercial hop variety list by eye; not matched | fictional; USPTO search pending |
| Workhorse | Hop | `content.hop.h07.name` | Clean high-alpha bittering hop family; generic English word | Compared against the known commercial hop variety list by eye; not matched | fictional; USPTO search pending |
| Orchard Gold | Hop | `content.hop.h08.name` | Stone-fruit and tropical hop family | Compared against the known commercial hop variety list by eye; not matched | fictional; USPTO search pending |
| Pale Malt | Grain | `content.grain.g01.name` | Generic malt category term | Generic descriptive term | generic descriptive term |
| Pilsner Malt | Grain | `content.grain.g02.name` | Generic malt category term | Generic descriptive term | generic descriptive term |
| Wheat Malt | Grain | `content.grain.g03.name` | Generic malt category term | Generic descriptive term | generic descriptive term |
| Crystal 60 | Grain | `content.grain.g04.name` | Generic caramel/crystal malt category and Lovibond rating | Generic descriptive term | generic descriptive term |
| Roasted Barley | Grain | `content.grain.g05.name` | Generic malt category term | Generic descriptive term | generic descriptive term |
| Flaked Oats | Adjunct | `content.adjunct.a01.name` | Generic brewing adjunct | Generic descriptive term | generic descriptive term |
| Candi Sugar | Adjunct | `content.adjunct.a02.name` | Generic brewing adjunct | Generic descriptive term | generic descriptive term |
| Raspberry Puree | Adjunct | `content.adjunct.a03.name` | Generic fruit ingredient | Generic descriptive term | generic descriptive term |
| Clean American Ale | Yeast | `content.yeast.y01.name` | Generic descriptor, no strain or lab brand | Generic descriptive term | generic descriptive term |
| English Ale | Yeast | `content.yeast.y02.name` | Generic style descriptor, no strain or lab brand | Generic descriptive term | generic descriptive term |
| Lager | Yeast | `content.yeast.y03.name` | Generic style descriptor | Generic descriptive term | generic descriptive term |
| Farmhouse | Yeast | `content.yeast.y04.name` | Generic style descriptor | Generic descriptive term | generic descriptive term |
| Wild Cellar Blend | Yeast | `content.yeast.y05.name` | Generic descriptor, no lab blend name | Generic descriptive term | generic descriptive term |

## Automated guard

`grep -rniE 'citra|mosaic|simcoe|galaxy|amarillo' Packages/BrewCore/Sources/BrewCore/Resources/Content` must print nothing (plan 01-03 acceptance). The list is a floor, not a clearance: extend it as new hop and yeast brand names come to mind.
