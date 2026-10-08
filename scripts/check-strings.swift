// String Catalog coverage and hygiene checker (PLAT-06).
//
// Run from the repo root:  swift scripts/check-strings.swift
//
// Checks, against App/BrewFighter/Localizable.xcstrings:
//   MISSING        a key referenced by an app string literal or by BrewCore content JSON is not in the catalog
//   BADKEY         a catalog key is not a semantic dotted identifier (optionally followed by specifiers)
//   EMPTY          a catalog key has an empty English value
//   NONPOSITIONAL  an English value uses a non-positional format specifier (use %1$lld, not %lld)
//   BANNED         an English value contains intoxication vocabulary (App Review 1.4.3 framing)
//
// Foundation only. Exit 0 when clean, 1 when any problem is found.

import Foundation

let fm = FileManager.default
let root = fm.currentDirectoryPath
let catalogPath = "App/BrewFighter/Localizable.xcstrings"
let appDir = "App/BrewFighter"
let contentDir = "Packages/BrewCore/Sources/BrewCore/Resources/Content"

var problems: [String] = []

func fail(_ line: String) { problems.append(line) }

func regex(_ pattern: String) -> NSRegularExpression {
    do { return try NSRegularExpression(pattern: pattern) } catch { fatalError("bad regex \(pattern): \(error)") }
}

func replacing(_ re: NSRegularExpression, in text: String, with template: String) -> String {
    re.stringByReplacingMatches(
        in: text, range: NSRange(text.startIndex..., in: text), withTemplate: template)
}

func matches(_ re: NSRegularExpression, in text: String) -> [NSTextCheckingResult] {
    re.matches(in: text, range: NSRange(text.startIndex..., in: text))
}

func files(under dir: String, withExtension ext: String) -> [String] {
    guard let e = fm.enumerator(atPath: dir) else { return [] }
    var out: [String] = []
    for case let rel as String in e where rel.hasSuffix(".\(ext)") { out.append("\(dir)/\(rel)") }
    return out.sorted()
}

// MARK: - Catalog

guard let catalogData = fm.contents(atPath: catalogPath),
    let catalogJSON = try? JSONSerialization.jsonObject(with: catalogData) as? [String: Any],
    let catalogStrings = catalogJSON["strings"] as? [String: Any]
else {
    print("check-strings: cannot read \(catalogPath) (run from the repo root)")
    exit(1)
}

let specifierRE = regex(#"%(lld|ld|d|@|f|lf)"#)
let keyRE = regex(#"^[a-z][A-Za-z0-9]*(\.[A-Za-z0-9_]+)+( %(lld|ld|d|@|f|lf))*$"#)
// A conversion that has no `N$` position. `%%` is stripped first because it is a literal percent sign.
let nonPositionalRE = regex(#"%(?!\d+\$)(l|ll|h|hh|z|q)?[@dDiuUxXoOfeEgGcCsSpaA]"#)
let bannedWords = ["buzzed", "drunk", "wasted", "tipsy", "hammered", "sloshed"]

func normalizeKey(_ key: String) -> String {
    replacing(specifierRE, in: key, with: "%")
}

var catalogKeys = Set<String>()
for (key, value) in catalogStrings.sorted(by: { $0.key < $1.key }) {
    catalogKeys.insert(normalizeKey(key))

    if matches(keyRE, in: key).isEmpty { fail("BADKEY \(key)") }

    let units = (value as? [String: Any])?["localizations"] as? [String: Any]
    let en = (units?["en"] as? [String: Any])?["stringUnit"] as? [String: Any]
    let text = (en?["value"] as? String) ?? ""
    if text.isEmpty {
        fail("EMPTY \(key)")
        continue
    }
    let withoutLiteralPercent = text.replacingOccurrences(of: "%%", with: "")
    if !matches(nonPositionalRE, in: withoutLiteralPercent).isEmpty {
        fail("NONPOSITIONAL \(key) -> \(text)")
    }
    for word in bannedWords {
        let re = regex("(?i)\\b\(word)\\b")
        if !matches(re, in: text).isEmpty { fail("BANNED \(key) contains '\(word)'") }
    }
}

// MARK: - App string literals

// Interpolations inside a localized literal must be simple local identifiers: \(name).
let interpolationRE = regex(#"\\\([^()]*\)"#)
let literalRE = regex(
    #"(?:\b(?:Text|Button|Label|LocalizedStringKey|LocalizedStringResource)\(|\bString\(localized:)\s*"((?:[^"\\]|\\.)*)""#)

for file in files(under: appDir, withExtension: "swift") {
    guard let source = try? String(contentsOfFile: file, encoding: .utf8) else { continue }
    // Drop line comments so documentation examples are not scanned.
    let code = source.split(separator: "\n", omittingEmptySubsequences: false)
        .map { line -> String in
            let trimmed = line.drop { $0 == " " || $0 == "\t" }
            return trimmed.hasPrefix("//") ? "" : String(line)
        }
        .joined(separator: "\n")
    for match in matches(literalRE, in: code) {
        guard let range = Range(match.range(at: 1), in: code) else { continue }
        let literal = String(code[range])
        let normalized = replacing(interpolationRE, in: literal, with: "%")
        if !catalogKeys.contains(normalized) { fail("MISSING \(literal) (\(file))") }
    }
}

// MARK: - Content keys

var contentKeys: [(key: String, file: String)] = []

func collect(_ node: Any, file: String) {
    if let dict = node as? [String: Any] {
        for (name, value) in dict {
            if name.hasSuffix("Keys"), let list = value as? [Any] {
                for case let key as String in list { contentKeys.append((key, file)) }
            } else if name.hasSuffix("Key"), let key = value as? String {
                contentKeys.append((key, file))
            } else {
                collect(value, file: file)
            }
        }
    } else if let list = node as? [Any] {
        for item in list { collect(item, file: file) }
    }
}

for file in files(under: contentDir, withExtension: "json") {
    guard let data = fm.contents(atPath: file),
        let json = try? JSONSerialization.jsonObject(with: data)
    else {
        fail("MISSING <unreadable content file> (\(file))")
        continue
    }
    collect(json, file: file)
}

// Computed keys: the 16 attributes and the 4 attribute families.
let attributeIDs = [
    "malt", "sweetness", "dryness", "body", "bitterness", "hopAroma", "citrus", "tropical",
    "herbal", "spice", "roast", "fruit", "funk", "sour", "carbonation", "abv",
]
let familyIDs = ["malt", "hop", "yeast", "mouthfeel"]
for id in attributeIDs { contentKeys.append(("attribute.\(id).name", "computed: AttributeID")) }
for id in familyIDs { contentKeys.append(("family.\(id).name", "computed: AttributeFamily")) }

var reported = Set<String>()
for (key, file) in contentKeys where !catalogKeys.contains(key) {
    if reported.insert(key).inserted { fail("MISSING \(key) (\(file))") }
}

// MARK: - Result

if problems.isEmpty {
    print("check-strings: OK (\(catalogStrings.count) keys)")
    exit(0)
}
for line in problems { print(line) }
print("check-strings: FAILED (\(problems.count) problems)")
exit(1)
