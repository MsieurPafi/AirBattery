import AppKit
// Writes the SVG as a PNG of each requested pixel size.
// Usage: swift scripts/icon/export-pngs.swift <out-dir> <svg> icon_16x16.png=16 icon_16x16@2x.png=32 ...
let args = CommandLine.arguments
let dir = args[1], svg = NSImage(contentsOfFile: args[2])!
for pair in args.dropFirst(3) {
    let parts = pair.split(separator: "="), name = String(parts[0]), px = Int(parts[1])!
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: px, height: px)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    svg.draw(in: NSRect(x: 0, y: 0, width: px, height: px))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: dir + "/" + name))
}
