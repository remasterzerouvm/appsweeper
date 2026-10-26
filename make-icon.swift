// Generates AppIcon.icns: run `swift make-icon.swift` (only needed to change the icon).
import AppKit

func png(_ px: Int) -> Data {
    let img = NSImage(size: NSSize(width: px, height: px), flipped: false) { r in
        let body = r.insetBy(dx: CGFloat(px) * 0.06, dy: CGFloat(px) * 0.06)
        let path = NSBezierPath(roundedRect: body, xRadius: body.width * 0.225, yRadius: body.width * 0.225)
        NSGradient(starting: NSColor(red: 1, green: 0.42, blue: 0.35, alpha: 1),
                   ending: NSColor(red: 0.82, green: 0.1, blue: 0.2, alpha: 1))!.draw(in: path, angle: -90)
        let cfg = NSImage.SymbolConfiguration(pointSize: CGFloat(px) * 0.5, weight: .semibold)
            .applying(.init(paletteColors: [.white]))
        let sym = NSImage(systemSymbolName: "trash.fill", accessibilityDescription: nil)!.withSymbolConfiguration(cfg)!
        let s = sym.size
        sym.draw(at: NSPoint(x: (r.width - s.width) / 2, y: (r.height - s.height) / 2), from: .zero, operation: .sourceOver, fraction: 1)
        return true
    }
    let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
    return rep.representation(using: .png, properties: [:])!
}

let dir = "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
for (name, px) in [("16x16", 16), ("16x16@2x", 32), ("32x32", 32), ("32x32@2x", 64), ("128x128", 128), ("128x128@2x", 256),
                   ("256x256", 256), ("256x256@2x", 512), ("512x512", 512), ("512x512@2x", 1024)] {
    try! png(px).write(to: URL(fileURLWithPath: "\(dir)/icon_\(name).png"))
}
