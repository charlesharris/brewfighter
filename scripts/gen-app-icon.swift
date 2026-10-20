#!/usr/bin/env swift
// Procedural Brew Fighter app icon: a flat AdCap-style copper brew kettle with steam and a hop cone.
// Deterministic (no randomness): running it twice yields identical pixels.
// No text, no beer glass, no drinking (4+-appropriate store metadata).
// Usage: swift scripts/gen-app-icon.swift   (run from the repo root)

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let outDir = "App/BrewFighter/Assets.xcassets/AppIcon.appiconset"
let outPath = "\(outDir)/AppIcon-1024.png"

let space = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else { fatalError("no context") }

func color(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(colorSpace: space, components: [r, g, b, a])!
}

// Brand palette (mirrors App/BrewFighter/UIKit/Palette.swift).
let amber = color(0.96, 0.65, 0.14)
let foamCream = color(0.99, 0.96, 0.87)
let ink = color(0.13, 0.09, 0.06)
let copper = color(0.80, 0.42, 0.16)
let copperLight = color(0.93, 0.58, 0.28)
let copperDark = color(0.58, 0.28, 0.10)
let hopGreen = color(0.25, 0.66, 0.33)
let hopLight = color(0.45, 0.80, 0.42)
let hopDark = color(0.14, 0.45, 0.22)
let white = color(1, 1, 1)

let s = CGFloat(size)
// CoreGraphics origin is bottom-left; designs below use y-up coordinates.

// Background: warm amber-to-cream radial.
let bg = CGGradient(colorsSpace: space, colors: [foamCream, amber] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(
    bg, startCenter: CGPoint(x: s * 0.5, y: s * 0.62), startRadius: 0,
    endCenter: CGPoint(x: s * 0.5, y: s * 0.62), endRadius: s * 0.78,
    options: [.drawsAfterEndLocation]
)

let outline: CGFloat = 22

func stroke(_ path: CGPath, fill: CGColor, line: CGColor = ink, width: CGFloat = outline) {
    ctx.setFillColor(fill)
    ctx.addPath(path)
    ctx.fillPath()
    ctx.setStrokeColor(line)
    ctx.setLineWidth(width)
    ctx.setLineJoin(.round)
    ctx.setLineCap(.round)
    ctx.addPath(path)
    ctx.strokePath()
}

// Soft ground shadow under the kettle.
ctx.setFillColor(color(0.24, 0.15, 0.09, 0.22))
ctx.fillEllipse(in: CGRect(x: s * 0.17, y: s * 0.12, width: s * 0.66, height: s * 0.07))

// Kettle legs.
for x in [s * 0.30, s * 0.62] {
    let leg = CGPath(roundedRect: CGRect(x: x, y: s * 0.14, width: s * 0.08, height: s * 0.10),
                     cornerWidth: 14, cornerHeight: 14, transform: nil)
    stroke(leg, fill: copperDark)
}

// Kettle body: a chunky rounded pot.
let bodyRect = CGRect(x: s * 0.20, y: s * 0.22, width: s * 0.60, height: s * 0.44)
let body = CGPath(roundedRect: bodyRect, cornerWidth: s * 0.16, cornerHeight: s * 0.16, transform: nil)
ctx.saveGState()
ctx.addPath(body)
ctx.clip()
let bodyGrad = CGGradient(colorsSpace: space, colors: [copperLight, copper, copperDark] as CFArray,
                          locations: [0, 0.55, 1])!
ctx.drawLinearGradient(bodyGrad, start: CGPoint(x: bodyRect.minX, y: bodyRect.midY),
                       end: CGPoint(x: bodyRect.maxX, y: bodyRect.midY), options: [])
ctx.restoreGState()
ctx.setStrokeColor(ink)
ctx.setLineWidth(outline)
ctx.setLineJoin(.round)
ctx.addPath(body)
ctx.strokePath()

// Body highlight streak.
let streak = CGPath(roundedRect: CGRect(x: s * 0.26, y: s * 0.30, width: s * 0.045, height: s * 0.26),
                    cornerWidth: 20, cornerHeight: 20, transform: nil)
ctx.setFillColor(color(1, 0.88, 0.65, 0.75))
ctx.addPath(streak)
ctx.fillPath()

// Rivet band across the kettle.
let band = CGPath(roundedRect: CGRect(x: s * 0.20, y: s * 0.40, width: s * 0.60, height: s * 0.05),
                  cornerWidth: 8, cornerHeight: 8, transform: nil)
stroke(band, fill: copperDark, width: 14)

// Lid.
let lid = CGPath(roundedRect: CGRect(x: s * 0.17, y: s * 0.62, width: s * 0.66, height: s * 0.075),
                 cornerWidth: 30, cornerHeight: 30, transform: nil)
stroke(lid, fill: copperLight)
// Lid knob.
let knob = CGPath(ellipseIn: CGRect(x: s * 0.46, y: s * 0.68, width: s * 0.08, height: s * 0.08), transform: nil)
stroke(knob, fill: copperDark, width: 16)

// Side handles.
for (x, flip) in [(s * 0.14, CGFloat(-1)), (s * 0.86, CGFloat(1))] {
    let handle = CGMutablePath()
    handle.move(to: CGPoint(x: x - flip * s * 0.04, y: s * 0.52))
    handle.addQuadCurve(to: CGPoint(x: x - flip * s * 0.04, y: s * 0.36),
                        control: CGPoint(x: x + flip * s * 0.06, y: s * 0.44))
    ctx.setStrokeColor(ink)
    ctx.setLineWidth(40)
    ctx.setLineCap(.round)
    ctx.addPath(handle)
    ctx.strokePath()
    ctx.setStrokeColor(copperDark)
    ctx.setLineWidth(20)
    ctx.addPath(handle)
    ctx.strokePath()
}

// Two white steam puffs.
func puff(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
    let p = CGMutablePath()
    p.addEllipse(in: CGRect(x: cx - r, y: cy - r * 0.8, width: r * 2, height: r * 1.6))
    p.addEllipse(in: CGRect(x: cx - r * 1.5, y: cy - r * 0.55, width: r * 1.3, height: r * 1.1))
    p.addEllipse(in: CGRect(x: cx + r * 0.3, y: cy - r * 0.55, width: r * 1.3, height: r * 1.1))
    ctx.setFillColor(white)
    ctx.addPath(p)
    ctx.fillPath()
}
puff(s * 0.38, s * 0.84, s * 0.065)
puff(s * 0.60, s * 0.89, s * 0.055)
puff(s * 0.52, s * 0.79, s * 0.04)

// Hop cone in front (lower right of kettle): overlapping scale layers, deterministic.
let hopCenter = CGPoint(x: s * 0.62, y: s * 0.30)
let hopW: CGFloat = s * 0.26
let hopH: CGFloat = s * 0.34

// Leaf behind the cone.
let leaf = CGMutablePath()
leaf.move(to: CGPoint(x: hopCenter.x - hopW * 0.1, y: hopCenter.y + hopH * 0.5))
leaf.addQuadCurve(to: CGPoint(x: hopCenter.x - hopW * 0.95, y: hopCenter.y + hopH * 0.75),
                  control: CGPoint(x: hopCenter.x - hopW * 0.6, y: hopCenter.y + hopH * 1.0))
leaf.addQuadCurve(to: CGPoint(x: hopCenter.x - hopW * 0.1, y: hopCenter.y + hopH * 0.5),
                  control: CGPoint(x: hopCenter.x - hopW * 0.5, y: hopCenter.y + hopH * 0.42))
stroke(leaf, fill: hopLight, width: 16)

// Stem.
let stem = CGMutablePath()
stem.move(to: CGPoint(x: hopCenter.x, y: hopCenter.y + hopH * 0.46))
stem.addLine(to: CGPoint(x: hopCenter.x + hopW * 0.06, y: hopCenter.y + hopH * 0.62))
ctx.setStrokeColor(ink)
ctx.setLineWidth(30)
ctx.setLineCap(.round)
ctx.addPath(stem)
ctx.strokePath()
ctx.setStrokeColor(hopDark)
ctx.setLineWidth(14)
ctx.addPath(stem)
ctx.strokePath()

// Cone: a teardrop silhouette, then rows of scales (bottom row widest).
let cone = CGMutablePath()
cone.move(to: CGPoint(x: hopCenter.x, y: hopCenter.y - hopH * 0.5))
cone.addCurve(to: CGPoint(x: hopCenter.x - hopW * 0.5, y: hopCenter.y + hopH * 0.1),
              control1: CGPoint(x: hopCenter.x - hopW * 0.35, y: hopCenter.y - hopH * 0.42),
              control2: CGPoint(x: hopCenter.x - hopW * 0.55, y: hopCenter.y - hopH * 0.15))
cone.addCurve(to: CGPoint(x: hopCenter.x, y: hopCenter.y + hopH * 0.5),
              control1: CGPoint(x: hopCenter.x - hopW * 0.45, y: hopCenter.y + hopH * 0.35),
              control2: CGPoint(x: hopCenter.x - hopW * 0.2, y: hopCenter.y + hopH * 0.5))
cone.addCurve(to: CGPoint(x: hopCenter.x + hopW * 0.5, y: hopCenter.y + hopH * 0.1),
              control1: CGPoint(x: hopCenter.x + hopW * 0.2, y: hopCenter.y + hopH * 0.5),
              control2: CGPoint(x: hopCenter.x + hopW * 0.45, y: hopCenter.y + hopH * 0.35))
cone.addCurve(to: CGPoint(x: hopCenter.x, y: hopCenter.y - hopH * 0.5),
              control1: CGPoint(x: hopCenter.x + hopW * 0.55, y: hopCenter.y - hopH * 0.15),
              control2: CGPoint(x: hopCenter.x + hopW * 0.35, y: hopCenter.y - hopH * 0.42))
cone.closeSubpath()
ctx.saveGState()
ctx.addPath(cone)
ctx.clip()
let coneGrad = CGGradient(colorsSpace: space, colors: [hopLight, hopGreen, hopDark] as CFArray,
                          locations: [0, 0.5, 1])!
ctx.drawLinearGradient(coneGrad, start: CGPoint(x: hopCenter.x - hopW * 0.5, y: hopCenter.y + hopH * 0.3),
                       end: CGPoint(x: hopCenter.x + hopW * 0.5, y: hopCenter.y - hopH * 0.3), options: [])
// Scale rows: overlapping rounded scallops, darker outline.
let rows = 4
for row in 0..<rows {
    let t = CGFloat(row) / CGFloat(rows)
    let y = hopCenter.y + hopH * (0.34 - t * 0.62)
    let count = row == 0 ? 2 : (row == 1 ? 3 : 3)
    let sw = hopW * (row == 0 ? 0.40 : 0.36)
    for i in 0..<count {
        let offset = (CGFloat(i) - CGFloat(count - 1) / 2) * sw * 0.9
        let scale = CGPath(ellipseIn: CGRect(x: hopCenter.x + offset - sw / 2, y: y - sw * 0.5,
                                             width: sw, height: sw * 0.9), transform: nil)
        ctx.setFillColor(row % 2 == 0 ? hopGreen : hopLight)
        ctx.addPath(scale)
        ctx.fillPath()
        ctx.setStrokeColor(hopDark)
        ctx.setLineWidth(9)
        ctx.addPath(scale)
        ctx.strokePath()
    }
}
ctx.restoreGState()
ctx.setStrokeColor(ink)
ctx.setLineWidth(outline)
ctx.setLineJoin(.round)
ctx.addPath(cone)
ctx.strokePath()

// Write PNG (opaque).
guard let image = ctx.makeImage() else { fatalError("no image") }
try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
let url = URL(fileURLWithPath: outPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("no destination")
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("write failed") }

let contents = """
{
  "images" : [
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}

"""
try contents.write(toFile: "\(outDir)/Contents.json", atomically: true, encoding: .utf8)
try """
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}

""".write(toFile: "App/BrewFighter/Assets.xcassets/Contents.json", atomically: true, encoding: .utf8)
print("wrote \(outPath)")
