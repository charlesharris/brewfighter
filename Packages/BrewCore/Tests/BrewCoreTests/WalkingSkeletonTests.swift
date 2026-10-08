import Foundation
import Testing

@testable import BrewCore

private let beerID1 = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
private let beerID2 = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

private func minimalRecipe() -> Recipe {
    Recipe(
        grainBill: GrainBill(baseID: "grain.g01", entries: [GrainEntry(fermentableID: "grain.g01", percent: 100)]),
        yeastID: "yeast.y01")
}

@Suite struct WalkingSkeletonTests {
    let content: ContentCatalog

    init() throws {
        content = try ContentCatalog.loadBundled()
    }

    // MARK: Content

    @Test func catalogLoadsWithHousePaleAle() {
        #expect(content.contentVersion == 1)
        #expect(content.housePaleAle.yeastID == "yeast.y01")
        #expect(content.starterRecipe("house_pale_ale") == content.housePaleAle)
        #expect(content.starterRecipe("nope") == nil)
        #expect(content.housePaleAle.grainBill.entries.map(\.percent).reduce(0, +) == 100)
    }

    // MARK: Brewer

    @Test func brewIsDeterministic() throws {
        let a = try Brewer.brew(content.housePaleAle, content: content)
        let b = try Brewer.brew(content.housePaleAle, content: content)
        #expect(a == b)
    }

    @Test(arguments: ["house", "minimal"])
    func ledgerRowsSumExactlyToEveryAttribute(which: String) throws {
        let recipe = which == "house" ? content.housePaleAle : minimalRecipe()
        let result = try Brewer.brew(recipe, content: content)
        for attribute in AttributeID.allCases {
            let sum = result.rows(for: attribute).reduce(0) { $0 + $1.delta }
            #expect(sum == result.attributes[attribute], "\(attribute)")
            #expect((0...AttributeScale.max).contains(result.attributes[attribute]), "\(attribute)")
        }
        #expect(!result.ledger.contains { $0.delta == 0 }, "zero-delta rows are never emitted")
    }

    @Test func houseLedgerIsInBrewingStageOrder() throws {
        let result = try Brewer.brew(content.housePaleAle, content: content)
        let kinds = result.ledger.map(\.source.kind)
        let order: [SourceKind] = [.baseline, .fermentable, .strength, .mashTemp, .hop, .yeast, .fermentTemp, .fermentDuration, .conditioning, .cap]
        let indices = kinds.map { order.firstIndex(of: $0)! }
        #expect(indices == indices.sorted())
        // 90% pale + 10% crystal: crystal sweetness is divRound(300 * 10, 100) = 30 tenths.
        let crystal = result.ledger.first { $0.source.refID == "grain.g04" && $0.attribute == .sweetness }
        #expect(crystal?.delta == 30)
        #expect(result.attributes[.carbonation] == 50)
        #expect(result.stats.ogPoints == 1050)
    }

    @Test func divRoundRoundsHalfAwayFromZero() {
        #expect(divRound(1350, 100) == 14)
        #expect(divRound(-1350, 100) == -14)
        #expect(divRound(1349, 100) == 13)
        #expect(divRound(-1349, 100) == -13)
        #expect(divRound(0, 100) == 0)
    }

    @Test func capRowKeepsRowsEqualToValue() {
        let source = LedgerSource(kind: .fermentable, refID: "test")
        let rows = [
            LedgerRow(attribute: .malt, source: source, delta: 70),
            LedgerRow(attribute: .malt, source: source, delta: 35),
            LedgerRow(attribute: .body, source: source, delta: -5),
        ]
        let (vector, ledger) = Brewer.finalize(rows)
        #expect(vector[.malt] == 100)
        let maltRows = ledger.filter { $0.attribute == .malt }
        #expect(maltRows.last == LedgerRow(attribute: .malt, source: LedgerSource(kind: .cap), delta: -5))
        #expect(maltRows.reduce(0) { $0 + $1.delta } == 100)
        #expect(vector[.body] == 0)
        let bodyRows = ledger.filter { $0.attribute == .body }
        #expect(bodyRows.last == LedgerRow(attribute: .body, source: LedgerSource(kind: .cap), delta: 5))
        #expect(bodyRows.reduce(0) { $0 + $1.delta } == 0)
    }

    // MARK: Reducer

    @Test func reducerBrewFromNewCommitsBatchAndDay() throws {
        var rng = SeededRNG(seed: 7)
        let (state, events) = Reducer.apply(
            .brew(recipe: content.housePaleAle, beerID: beerID1), to: .new, content: content, rng: &rng)
        #expect(state.beers.count == 1)
        let beer = try #require(state.beers.first)
        #expect(beer.id == beerID1)
        #expect(beer.batchNumber == 1)
        #expect(beer.brewDay == 1)
        #expect(beer.contentVersion == 1)
        #expect(state.day == 15)
        #expect(state.nextBatchNumber == 2)
        #expect(events == [
            .dayAdvanced(from: 1, to: 15),
            .beerBrewed(beerID: beerID1, batchNumber: 1),
            .styleAssigned(beerID: beerID1, styleID: beer.result.styleID),
        ])
    }

    @Test func secondBrewUsesNextBatchAndCurrentDay() throws {
        var rng = SeededRNG(seed: 7)
        let (s1, _) = Reducer.apply(.brew(recipe: content.housePaleAle, beerID: beerID1), to: .new, content: content, rng: &rng)
        let (s2, _) = Reducer.apply(.brew(recipe: minimalRecipe(), beerID: beerID2), to: s1, content: content, rng: &rng)
        #expect(s2.beers.map(\.batchNumber) == [1, 2])
        #expect(s2.beers[1].brewDay == 15)
        #expect(s2.day == 29)
        #expect(s2.nextBatchNumber == 3)
    }

    @Test func brewingNeverTouchesTheRNG() {
        var rng = SeededRNG(seed: 7)
        let before = rng
        _ = Reducer.apply(.brew(recipe: content.housePaleAle, beerID: beerID1), to: .new, content: content, rng: &rng)
        #expect(rng == before)
        // A rejected brew leaves it alone too.
        _ = Reducer.apply(.brew(recipe: Recipe(), beerID: beerID2), to: .new, content: content, rng: &rng)
        #expect(rng == before)
    }

    @Test func emptyGrainBillIsRejectedWithStateUnchanged() {
        var rng = SeededRNG(seed: 1)
        var recipe = content.housePaleAle
        recipe.grainBill = GrainBill()
        let (state, events) = Reducer.apply(.brew(recipe: recipe, beerID: beerID1), to: .new, content: content, rng: &rng)
        #expect(events == [.brewRejected([.noGrain])])
        #expect(state == .new)
    }

    @Test func missingYeastIsRejectedWithStateUnchanged() {
        var rng = SeededRNG(seed: 1)
        var recipe = content.housePaleAle
        recipe.yeastID = nil
        let (state, events) = Reducer.apply(.brew(recipe: recipe, beerID: beerID1), to: .new, content: content, rng: &rng)
        #expect(events == [.brewRejected([.noYeast])])
        #expect(state.day == 1)
        #expect(state.beers.isEmpty)
        #expect(state.nextBatchNumber == 1)
    }

    @Test func minimalRecipeBrews() throws {
        var rng = SeededRNG(seed: 1)
        let (state, events) = Reducer.apply(.brew(recipe: minimalRecipe(), beerID: beerID1), to: .new, content: content, rng: &rng)
        #expect(state.beers.count == 1)
        #expect(events.count == 3)
    }

    // MARK: SaveCodec

    @Test func codecRoundTripsAndIsByteStable() throws {
        var rng = SeededRNG(seed: 7)
        let (s1, _) = Reducer.apply(.brew(recipe: content.housePaleAle, beerID: beerID1), to: .new, content: content, rng: &rng)
        let (s2, _) = Reducer.apply(.brew(recipe: minimalRecipe(), beerID: beerID2), to: s1, content: content, rng: &rng)
        let data = try SaveCodec.encode(s2)
        #expect(try SaveCodec.decode(data) == s2)
        #expect(try SaveCodec.encode(s2) == data)
        #expect(try SaveCodec.decode(SaveCodec.encode(.new)) == .new)
    }

    @Test func newerSchemaIsRejectedBeforePayloadDecode() {
        let data = Data(#"{"schemaVersion":2,"payload":"not a game state"}"#.utf8)
        #expect(throws: SaveError.newerThanApp(2)) { try SaveCodec.decode(data) }
    }

    @Test func oversizedInputIsRejected() {
        let data = Data(count: SaveCodec.maxSaveBytes + 1)
        #expect(throws: SaveError.tooLarge) { try SaveCodec.decode(data) }
    }

    @Test func garbageBytesAreUnreadable() {
        #expect(throws: SaveError.unreadable) { try SaveCodec.decode(Data([0xDE, 0xAD, 0xBE, 0xEF])) }
        #expect(throws: SaveError.unreadable) { try SaveCodec.decode(Data(#"{"schemaVersion":1}"#.utf8)) }
    }

    @Test func zeroSchemaVersionIsInvalid() {
        #expect(throws: SaveError.invalid("schemaVersion")) {
            try SaveCodec.decode(Data(#"{"schemaVersion":0}"#.utf8))
        }
    }

    // MARK: Attributes

    @Test func familiesPartitionAllSixteenAttributes() {
        #expect(AttributeFamily.malt.attributes == [.malt, .sweetness, .roast])
        #expect(AttributeFamily.hop.attributes == [.bitterness, .hopAroma, .citrus, .tropical, .herbal])
        #expect(AttributeFamily.yeast.attributes == [.fruit, .spice, .funk, .sour])
        #expect(AttributeFamily.mouthfeel.attributes == [.body, .dryness, .carbonation, .abv])
        let union = AttributeFamily.allCases.flatMap(\.attributes)
        #expect(union.count == 16)
        #expect(Set(union) == Set(AttributeID.allCases))
        for family in AttributeFamily.allCases {
            for attribute in family.attributes { #expect(attribute.family == family) }
        }
        #expect(AttributeID.hopAroma.nameKey == "attribute.hopAroma.name")
        #expect(AttributeFamily.mouthfeel.nameKey == "family.mouthfeel.name")
    }

    @Test func attributeVectorEncodesExactlySixteenKeysAndRejectsBadShapes() throws {
        let data = try JSONEncoder().encode(AttributeVector.zero)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Int])
        #expect(Set(object.keys) == Set(AttributeID.allCases.map(\.rawValue)))

        var missing = object
        missing.removeValue(forKey: "malt")
        let missingData = try JSONSerialization.data(withJSONObject: missing)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(AttributeVector.self, from: missingData) }

        var unknown = object
        unknown["umami"] = 5
        let unknownData = try JSONSerialization.data(withJSONObject: unknown)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(AttributeVector.self, from: unknownData) }
    }
}
