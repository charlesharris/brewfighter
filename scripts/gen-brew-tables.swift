// Offline generator for BrewCore's transcendental lookup tables.
//
// Run from the repo root:  swift scripts/gen-brew-tables.swift
//
// This is the ONLY place floating-point math happens. The engine reads the committed
// JSON as Int tables, so results are bit-identical across macOS, iOS and Linux.
// Running the script twice produces byte-identical output.
//
// Tables:
//   tinseth.json  Tinseth hop utilization per slot per OG point (Int per 100,000).
//
// Plan 01-04 extends this script with the SRM color table.

import Foundation

let outputDir = "Packages/BrewCore/Sources/BrewCore/Resources/Content"

// MARK: - Tinseth utilization

let ogMin = 1020
let ogMax = 1120

/// Effective boil minutes and a post-multiplier per slot (research Pitfall 9).
/// Whirlpool is 20 minutes at a reduced temperature, so its utilization is halved.
let slotModel: [(name: String, minutes: Double, multiplier: Double)] = [
    ("bittering", 60, 1.0),
    ("flavor", 15, 1.0),
    ("aroma", 5, 1.0),
    ("whirlpool", 20, 0.5),
]

/// Tinseth: utilization = 1.65 * 0.000125^(G - 1) * (1 - e^(-0.04 t)) / 4.15, G = ogPoints / 1000.
func utilization(ogPoints: Int, minutes: Double, multiplier: Double) -> Double {
    let gravity = Double(ogPoints) / 1000.0
    let bigness = 1.65 * pow(0.000125, gravity - 1.0)
    let timeFactor = (1.0 - exp(-0.04 * minutes)) / 4.15
    return bigness * timeFactor * multiplier
}

var slots: [String: [Int]] = [:]
for slot in slotModel {
    slots[slot.name] = (ogMin...ogMax).map {
        Int((utilization(ogPoints: $0, minutes: slot.minutes, multiplier: slot.multiplier) * 100_000).rounded())
    }
}

struct TinsethFile: Encodable {
    let ogMin: Int
    let ogMax: Int
    let slots: [String: [Int]]
}

func write<T: Encodable>(_ value: T, to name: String) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    do {
        var data = try encoder.encode(value)
        data.append(0x0A)
        try data.write(to: URL(fileURLWithPath: "\(outputDir)/\(name)"), options: .atomic)
        print("wrote \(outputDir)/\(name)")
    } catch {
        print("gen-brew-tables: failed to write \(name): \(error)")
        exit(1)
    }
}

guard FileManager.default.fileExists(atPath: outputDir) else {
    print("gen-brew-tables: run from the repo root (missing \(outputDir))")
    exit(1)
}

write(TinsethFile(ogMin: ogMin, ogMax: ogMax, slots: slots), to: "tinseth.json")
