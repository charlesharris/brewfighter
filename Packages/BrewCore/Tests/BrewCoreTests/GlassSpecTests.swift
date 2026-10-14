import Foundation
import Testing

@testable import BrewCore

@Suite struct GlassSpecTests {
    let content: ContentCatalog

    init() throws {
        content = try ContentCatalog.loadBundled()
    }

    private func beer(_ recipe: Recipe, batch: Int = 1) throws -> Beer {
        Beer(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000C1")!, batchNumber: batch, brewDay: 1,
            recipe: recipe, result: try Brewer.brew(recipe, content: content), contentVersion: content.contentVersion)
    }

    private func archetypeSpec(_ styleID: String) throws -> GlassSpec {
        GlassSpec.make(for: try beer(Archetypes.recipe(for: styleID, content: content)), content: content)
    }

    // MARK: Determinism

    @Test func sameBeerGivesEqualSpecs() throws {
        let b = try beer(content.housePaleAle)
        #expect(GlassSpec.make(for: b, content: content) == GlassSpec.make(for: b, content: content))
    }

    @Test func seedFollowsTheBatchNumber() throws {
        let one = GlassSpec.make(for: try beer(content.housePaleAle, batch: 1), content: content)
        let two = GlassSpec.make(for: try beer(content.housePaleAle, batch: 2), content: content)
        let oneAgain = GlassSpec.make(for: try beer(content.housePaleAle, batch: 1), content: content)
        #expect(one.seed != two.seed)
        #expect(one.seed == oneAgain.seed)
        #expect(one.seed != 0)
    }

    // MARK: SRM color stops

    @Test func srmStopsMatchTheChartEndpoints() {
        #expect(content.srmColors.rgb(srmTenths: 10) == RGB(r: 0xFF, g: 0xE6, b: 0x99))
        #expect(content.srmColors.rgb(srmTenths: 400) == RGB(r: 0x36, g: 0x08, b: 0x0A))
    }

    @Test func srmOutsideTheChartClampsToTheEndStops() {
        #expect(content.srmColors.rgb(srmTenths: 0) == content.srmColors.rgb(srmTenths: 10))
        #expect(content.srmColors.rgb(srmTenths: -30) == content.srmColors.rgb(srmTenths: 10))
        #expect(content.srmColors.rgb(srmTenths: 5000) == content.srmColors.rgb(srmTenths: 400))
        #expect(content.srmColors.rgb(srmTenths: Int.max) == content.srmColors.rgb(srmTenths: 400))
    }

    @Test func srmFiftyFiveIsTheIntegerMidpointBetweenStopsFiveAndSix() {
        let five = content.srmColors.rgb(srmTenths: 50)
        let six = content.srmColors.rgb(srmTenths: 60)
        let mid = content.srmColors.rgb(srmTenths: 55)
        #expect(five == RGB(r: 0xFB, g: 0xB1, b: 0x23))
        #expect(six == RGB(r: 0xF8, g: 0xA6, b: 0x00))
        for (a, b, m) in [(five.r, six.r, mid.r), (five.g, six.g, mid.g), (five.b, six.b, mid.b)] {
            #expect(abs(2 * m - (a + b)) <= 1, "midpoint \(m) of \(a) and \(b)")
        }
    }

    // MARK: Ranges

    @Test(arguments: ["structured", "sample"])
    func derivedValuesStayInRangeOverTheRecipeGrids(which: String) throws {
        let recipes =
            which == "structured"
            ? RecipeGrid.structured(content: content)
            : RecipeGrid.sample(seed: 42, count: 500, content: content)
        for (index, recipe) in recipes.enumerated() {
            let spec = GlassSpec.make(for: try beer(recipe), content: content)
            #expect((4...60).contains(spec.bubbleCount), "\(which)#\(index) bubbles \(spec.bubbleCount)")
            #expect((6...35).contains(spec.headHeightPercent), "\(which)#\(index) head \(spec.headHeightPercent)")
            #expect((0...80).contains(spec.hazePercent), "\(which)#\(index) haze \(spec.hazePercent)")
            for channel in [spec.liquid.r, spec.liquid.g, spec.liquid.b, spec.head.r, spec.head.g, spec.head.b] {
                #expect((0...255).contains(channel), "\(which)#\(index) channel \(channel)")
            }
        }
    }

    // MARK: Shape

    @Test func highAbvForcesTheSnifter() throws {
        var strong = try beer(content.housePaleAle)
        strong.result.stats.abvTenths = 80
        #expect(GlassSpec.make(for: strong, content: content).shape == .snifter)
        strong.result.stats.abvTenths = 79
        #expect(GlassSpec.make(for: strong, content: content).shape == content.glassShape(forStyle: strong.result.styleID))
    }

    @Test func shapeComesFromTheStylesGlassField() throws {
        for (index, recipe) in RecipeGrid.sample(seed: 7, count: 300, content: content).enumerated() {
            let b = try beer(recipe)
            let spec = GlassSpec.make(for: b, content: content)
            if b.result.stats.abvTenths >= 80 {
                #expect(spec.shape == .snifter, "#\(index)")
            } else {
                #expect(spec.shape == content.glassShape(forStyle: b.result.styleID), "#\(index)")
            }
        }
    }

    @Test func unknownStyleIDFallsBackToTheShaker() {
        #expect(content.glassShape(forStyle: "no_such_style") == .shaker)
    }

    // MARK: Visibly different glasses (ART-01)

    @Test func glassArchetypesArePairwiseAtLeastSixtyApart() throws {
        let specs = try Archetypes.glassSet.map { ($0, try archetypeSpec($0)) }
        #expect(specs.count == 6)
        for i in specs.indices {
            for j in specs.indices where j > i {
                let d = specs[i].1.distance(to: specs[j].1)
                #expect(d >= 60, "\(specs[i].0) vs \(specs[j].0) distance \(d)")
            }
        }
    }

    @Test func distanceIsSymmetricAndZeroForEqualSpecs() throws {
        let a = try archetypeSpec("stout")
        let b = try archetypeSpec("pilsner")
        #expect(a.distance(to: a) == 0)
        #expect(a.distance(to: b) == b.distance(to: a))
    }

    @Test func stoutHeadIsDarkerThanPilsnerHead() throws {
        let stout = try archetypeSpec("stout").head
        let pilsner = try archetypeSpec("pilsner").head
        #expect(stout.r + stout.g + stout.b < pilsner.r + pilsner.g + pilsner.b)
    }

    @Test func stoutIsDarkerInTheGlassThanPilsner() throws {
        let stout = try archetypeSpec("stout").liquid
        let pilsner = try archetypeSpec("pilsner").liquid
        #expect(stout.r + stout.g + stout.b < pilsner.r + pilsner.g + pilsner.b)
    }

    @Test func hazyIPAIsHazierThanThePilsner() throws {
        #expect(try archetypeSpec("hazy_ipa").hazePercent > (try archetypeSpec("pilsner").hazePercent))
    }
}
