import Foundation
import Testing

@testable import BrewCore

private func recipe(hops: [HopAddition], strength: StrengthBand = .standard) -> Recipe {
    Recipe(
        grainBill: GrainBill(baseID: "grain.g01", entries: [GrainEntry(fermentableID: "grain.g01", percent: 100)]),
        strength: strength,
        hops: hops,
        yeastID: "yeast.y01")
}

@Suite struct HopContributionTests {
    let content: ContentCatalog

    init() throws {
        content = try ContentCatalog.loadBundled()
    }

    private func row(_ result: BrewResult, _ attribute: AttributeID, hop: String, slot: HopSlot) -> LedgerRow? {
        result.ledger.first {
            $0.attribute == attribute && $0.source.kind == .hop && $0.source.refID == hop
                && $0.source.detail == slot.rawValue
        }
    }

    // MARK: Utilization table

    @Test func utilizationOrderingAtOG1050() {
        let t = content.tinseth
        let aroma = t.utilizationPer100k(slot: .aroma, ogPoints: 1050)
        let whirlpool = t.utilizationPer100k(slot: .whirlpool, ogPoints: 1050)
        let flavor = t.utilizationPer100k(slot: .flavor, ogPoints: 1050)
        let bittering = t.utilizationPer100k(slot: .bittering, ogPoints: 1050)
        #expect(aroma < whirlpool)
        #expect(whirlpool < flavor)
        #expect(flavor < bittering)
        #expect((23000...23150).contains(bittering), "bittering utilization at 1050 was \(bittering)")
    }

    @Test func utilizationClampsOutOfRangeGravity() {
        let t = content.tinseth
        #expect(t.utilizationPer100k(slot: .bittering, ogPoints: -5_000) == t.utilizationPer100k(slot: .bittering, ogPoints: t.ogMin))
        #expect(t.utilizationPer100k(slot: .bittering, ogPoints: Int.max) == t.utilizationPer100k(slot: .bittering, ogPoints: t.ogMax))
        #expect(t.utilizationPer100k(slot: .bittering, ogPoints: Int.min) == t.utilizationPer100k(slot: .bittering, ogPoints: t.ogMin))
    }

    @Test func higherGravityLowersUtilization() {
        let t = content.tinseth
        #expect(t.utilizationPer100k(slot: .bittering, ogPoints: 1036) > t.utilizationPer100k(slot: .bittering, ogPoints: 1085))
    }

    // MARK: Per-addition contributions

    @Test func oneOunceBitteringGivesRealisticIBUAndBitterness() throws {
        let r = recipe(hops: [HopAddition(hopID: "hop.h01", slot: .bittering, quarterOunces: 4)])
        let result = try Brewer.brew(r, content: content)
        #expect((405...425).contains(result.stats.ibuTenths), "ibuTenths was \(result.stats.ibuTenths)")
        let bitterness = try #require(row(result, .bitterness, hop: "hop.h01", slot: .bittering))
        #expect((40...43).contains(bitterness.delta), "bitterness row was \(bitterness.delta)")
    }

    @Test func aromaSlotGivesFullAromaAndBitteringSlotRoundsHalfAwayFromZero() throws {
        let aroma = try Brewer.brew(recipe(hops: [HopAddition(hopID: "hop.h01", slot: .aroma, quarterOunces: 4)]), content: content)
        #expect(row(aroma, .hopAroma, hop: "hop.h01", slot: .aroma)?.delta == 25)

        let bittering = try Brewer.brew(recipe(hops: [HopAddition(hopID: "hop.h01", slot: .bittering, quarterOunces: 4)]), content: content)
        // 25 * 10 * 4 / 400 = 2.5, rounded half away from zero.
        #expect(row(bittering, .hopAroma, hop: "hop.h01", slot: .bittering)?.delta == 3)
    }

    @Test func slotWeightsScaleAromaRows() throws {
        for (slot, weight) in [(HopSlot.bittering, 10), (.flavor, 50), (.aroma, 100), (.whirlpool, 80)] {
            let result = try Brewer.brew(recipe(hops: [HopAddition(hopID: "hop.h04", slot: slot, quarterOunces: 8)]), content: content)
            let expected = divRound(35 * weight * 8, 400)
            #expect(row(result, .tropical, hop: "hop.h04", slot: slot)?.delta == expected, "\(slot)")
        }
    }

    @Test func ibuStatEqualsSumOfPerAdditionValues() throws {
        let additions = [
            HopAddition(hopID: "hop.h07", slot: .bittering, quarterOunces: 4),
            HopAddition(hopID: "hop.h06", slot: .flavor, quarterOunces: 6),
            HopAddition(hopID: "hop.h01", slot: .aroma, quarterOunces: 8),
        ]
        let combined = try Brewer.brew(recipe(hops: additions), content: content)
        var sum = 0
        for addition in additions {
            sum += try Brewer.brew(recipe(hops: [addition]), content: content).stats.ibuTenths
        }
        #expect(combined.stats.ibuTenths == sum)
        #expect(combined.stats.ibuTenths > 0)
    }

    @Test func hopFreeRecipeHasNoIBU() throws {
        let result = try Brewer.brew(recipe(hops: []), content: content)
        #expect(result.stats.ibuTenths == 0)
        #expect(!result.ledger.contains { $0.source.kind == .hop })
    }

    @Test func higherStrengthLowersIBUPerOunce() throws {
        let addition = [HopAddition(hopID: "hop.h07", slot: .bittering, quarterOunces: 4)]
        let session = try Brewer.brew(recipe(hops: addition, strength: .session), content: content)
        let imperial = try Brewer.brew(recipe(hops: addition, strength: .imperial), content: content)
        #expect(session.stats.ibuTenths > imperial.stats.ibuTenths)
    }

    // MARK: House pale ale

    @Test func houseHopRowsReferenceHopH01AndLedgerStillSums() throws {
        let result = try Brewer.brew(content.housePaleAle, content: content)
        let hopRows = result.ledger.filter { $0.source.kind == .hop }
        #expect(!hopRows.isEmpty)
        #expect(hopRows.allSatisfy { $0.source.refID == "hop.h01" })
        #expect(Set(hopRows.compactMap(\.source.detail)) == ["bittering", "aroma"])
        for attribute in AttributeID.allCases {
            let sum = result.rows(for: attribute).reduce(0) { $0 + $1.delta }
            #expect(sum == result.attributes[attribute], "\(attribute)")
        }
    }

    @Test func reorderingHopsLeavesAttributesAndStatsIdentical() throws {
        let additions = [
            HopAddition(hopID: "hop.h07", slot: .bittering, quarterOunces: 4),
            HopAddition(hopID: "hop.h06", slot: .flavor, quarterOunces: 6),
            HopAddition(hopID: "hop.h01", slot: .aroma, quarterOunces: 8),
        ]
        let forward = try Brewer.brew(recipe(hops: additions), content: content)
        let backward = try Brewer.brew(recipe(hops: additions.reversed()), content: content)
        #expect(forward.attributes == backward.attributes)
        #expect(forward.stats == backward.stats)
        #expect(forward.styleID == backward.styleID)
    }

    // MARK: Content

    @Test func hopCatalogResolvesNeutralIDs() {
        #expect(content.hops.count == 8)
        #expect(content.hops.map(\.id) == (1...8).map { "hop.h0\($0)" })
        #expect(content.containsHop("hop.h08"))
        #expect(!content.containsHop("hop.h09"))
        #expect(content.hopSlots.map(\.slot) == HopSlot.allCases)
        #expect(content.hopSlots.map(\.aromaWeightPercent) == [10, 50, 100, 80])
    }
}
