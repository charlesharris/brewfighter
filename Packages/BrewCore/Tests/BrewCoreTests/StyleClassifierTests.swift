import Foundation
import Testing

@testable import BrewCore

@Suite struct StyleClassifierTests {
    let content: ContentCatalog

    init() throws {
        content = try ContentCatalog.loadBundled()
    }

    private func vector(_ values: [AttributeID: Int]) -> AttributeVector { AttributeVector(values) }

    @Test func zeroVectorFallsBackToExperimentalAle() {
        #expect(StyleClassifier.classify(.zero, styles: content.styles) == "experimental_ale")
    }

    @Test func fullAmericanPaleAleMatchWins() {
        let v = vector([.bitterness: 40, .hopAroma: 50, .malt: 30, .roast: 5, .abv: 50])
        #expect(StyleClassifier.classify(v, styles: content.styles) == "american_pale_ale")
    }

    @Test func unqualifiedMaltySweetBeerFallsBackToAmberAle() {
        let v = vector([.malt: 45, .sweetness: 30, .roast: 10])
        #expect(StyleClassifier.classify(v, styles: content.styles) == "amber_ale")
    }

    @Test func failingARequiredConditionBlocksAStyleDespiteHighMatch() {
        // Roast is required to be 0...10; everything else matches (weight 8 of 10 = 80% >= 75).
        let v = vector([.bitterness: 40, .hopAroma: 50, .malt: 30, .roast: 15, .abv: 50])
        #expect(StyleClassifier.classify(v, styles: content.styles) != "american_pale_ale")
    }

    @Test func belowThresholdMatchDoesNotQualify() {
        // Required conditions hold, but hopAroma and malt miss: (3 + 2 + 0) / 10 = 50% < 75%.
        let v = vector([.bitterness: 40, .hopAroma: 5, .malt: 80, .roast: 5])
        #expect(StyleClassifier.classify(v, styles: content.styles) != "american_pale_ale")
    }

    @Test func equalMatchPercentGoesToTheEarlierStyleInTheTable() {
        let condition = StyleCondition(attribute: .malt, min: 10, max: 90, weight: 1, required: true)
        let first = StyleDefinition(id: "first", nameKey: "style.first.name", threshold: 50, conditions: [condition])
        let second = StyleDefinition(id: "second", nameKey: "style.second.name", threshold: 50, conditions: [condition])
        let fallback = StyleDefinition(id: "experimental_ale", nameKey: "style.experimental_ale.name", threshold: nil, conditions: [])
        let v = vector([.malt: 50])

        let forward = StyleTable(styles: [first, second], fallbacks: [fallback])
        #expect(StyleClassifier.classify(v, styles: forward) == "first")
        let reversed = StyleTable(styles: [second, first], fallbacks: [fallback])
        #expect(StyleClassifier.classify(v, styles: reversed) == "second")
    }

    @Test func higherMatchPercentBeatsEarlierPosition() {
        let strict = StyleDefinition(
            id: "strict", nameKey: "style.strict.name", threshold: 50,
            conditions: [
                StyleCondition(attribute: .malt, min: 10, max: 90, weight: 1, required: false),
                StyleCondition(attribute: .body, min: 80, max: 100, weight: 1, required: false),
            ])  // malt matches, body misses: 50%
        let perfect = StyleDefinition(
            id: "perfect", nameKey: "style.perfect.name", threshold: 50,
            conditions: [StyleCondition(attribute: .malt, min: 10, max: 90, weight: 1, required: false)])  // 100%
        let fallback = StyleDefinition(id: "experimental_ale", nameKey: "style.experimental_ale.name", threshold: nil, conditions: [])
        let table = StyleTable(styles: [strict, perfect], fallbacks: [fallback])
        #expect(StyleClassifier.classify(vector([.malt: 50]), styles: table) == "perfect")
    }

    @Test func styleNameKeysResolveForStylesAndFallbacks() {
        #expect(content.styleNameKey("american_pale_ale") == "style.american_pale_ale.name")
        #expect(content.styleNameKey("amber_ale") == "style.amber_ale.name")
        #expect(content.styleNameKey("experimental_ale") == "style.experimental_ale.name")
        #expect(content.styleNameKey("nope") == nil)
    }

    @Test func recipeJSONNeverContainsAStyleKey() throws {
        let data = try JSONEncoder().encode(content.housePaleAle)
        let object = try JSONSerialization.jsonObject(with: data)

        func keys(in value: Any) -> [String] {
            if let dict = value as? [String: Any] {
                return dict.keys.flatMap { [$0] + keys(in: dict[$0]!) }
            }
            if let array = value as? [Any] { return array.flatMap { keys(in: $0) } }
            return []
        }
        let all = keys(in: object)
        #expect(!all.isEmpty)
        #expect(all.allSatisfy { !$0.lowercased().contains("style") }, "\(all)")
    }

    @Test func brewedBeerStyleIsInTheStyleTable() throws {
        let result = try Brewer.brew(content.housePaleAle, content: content)
        #expect(content.styleNameKey(result.styleID) != nil)
        // The hopped house recipe (bitterness, hop aroma, low roast) matches the pale ale style.
        #expect(result.styleID == StyleClassifier.classify(result.attributes, styles: content.styles))
        #expect(result.styleID == "american_pale_ale")
    }

    // MARK: Full roster (D-18)

    private func classify(_ recipe: Recipe) throws -> String {
        try Brewer.brew(recipe, content: content).styleID
    }

    private let expectedStyleOrder = [
        "west_coast_ipa", "hazy_ipa", "american_pale_ale", "stout", "porter", "brown_ale", "english_bitter",
        "saison", "wild_ale", "wheat_beer", "pilsner", "helles_lager", "blonde_ale",
    ]

    @Test func stylesFileDefinesThirteenStylesAndTwoFallbacksInOrder() {
        #expect(content.styles.styles.map(\.id) == expectedStyleOrder)
        #expect(content.styles.fallbacks.map(\.id) == ["amber_ale", "experimental_ale"])
        #expect(Archetypes.allStyles == expectedStyleOrder)
    }

    @Test func everyStyleHasAStableASCIIIDAndACatalogNameKey() {
        for style in content.styles.styles + content.styles.fallbacks {
            #expect(style.id.range(of: "^[a-z]+(_[a-z]+)*$", options: .regularExpression) != nil, "\(style.id)")
            #expect(style.nameKey == "style.\(style.id).name")
        }
    }

    @Test(arguments: [
        "west_coast_ipa", "hazy_ipa", "american_pale_ale", "stout", "porter", "brown_ale", "english_bitter",
        "saison", "wild_ale", "wheat_beer", "pilsner", "helles_lager", "blonde_ale",
    ])
    func everyStyleIsReachableFromItsArchetypeRecipe(styleID: String) throws {
        let result = try Brewer.brew(Archetypes.recipe(for: styleID, content: content), content: content)
        let a = result.attributes
        let summary = AttributeID.allCases.map { "\($0.rawValue)=\(a[$0])" }.joined(separator: " ")
        #expect(result.styleID == styleID, "\(styleID) classified as \(result.styleID): \(summary)")
    }

    @Test func housePaleAleClassifiesAsAmericanPaleAle() throws {
        #expect(try classify(content.housePaleAle) == "american_pale_ale")
    }

    @Test func westCoastAndHazyIPAAreDifferentBeers() throws {
        let west = try classify(Archetypes.recipe(for: "west_coast_ipa", content: content))
        let hazy = try classify(Archetypes.recipe(for: "hazy_ipa", content: content))
        #expect(west != hazy)
    }

    @Test func fallbackShareOverTheStructuredGridIsAtMostHalf() throws {
        let recipes = RecipeGrid.structured(content: content)
        var fallbacks = 0
        var counts: [String: Int] = [:]
        for recipe in recipes {
            let id = try classify(recipe)
            counts[id, default: 0] += 1
            if id == "amber_ale" || id == "experimental_ale" { fallbacks += 1 }
        }
        #expect(fallbacks * 2 <= recipes.count, "fallbacks \(fallbacks) of \(recipes.count): \(counts)")
    }

    @Test func everySampleRecipeClassifiesToAKnownStyle() throws {
        let known = Set((content.styles.styles + content.styles.fallbacks).map(\.id))
        for (index, recipe) in RecipeGrid.sample(seed: 7, count: 500, content: content).enumerated() {
            let id = try classify(recipe)
            #expect(known.contains(id), "#\(index) -> \(id)")
        }
    }

    @Test func emptyAndMinimalRecipesFallBackInsteadOfClaimingAStyle() throws {
        let fallbacks: Set<String> = ["amber_ale", "experimental_ale"]
        #expect(fallbacks.contains(StyleClassifier.classify(.zero, styles: content.styles)))
        let minimal = Recipe(
            grainBill: GrainBill(baseID: "grain.g01", entries: [GrainEntry(fermentableID: "grain.g01", percent: 100)]),
            yeastID: "yeast.y01")
        #expect(fallbacks.contains(try classify(minimal)))
    }

    @Test func aBrewedBeerPersistsTheStyleIDAndNeverTheDisplayName() throws {
        let result = try Brewer.brew(content.housePaleAle, content: content)
        let beer = Beer(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000D1")!, batchNumber: 1, brewDay: 1,
            recipe: content.housePaleAle, result: result, contentVersion: content.contentVersion)
        let json = String(decoding: try JSONEncoder().encode(beer), as: UTF8.self)
        #expect(json.contains("american_pale_ale"))
        #expect(!json.contains("American Pale Ale"))
    }
}
