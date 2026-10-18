import AppKit
import CoreImage
import CoreText
import SwiftUI

enum BrandAssets {
    static func url(named name: String, ext: String) -> URL? {
        let file = "\(name).\(ext)"
        let direct: [URL?] = [
            Bundle.main.url(forResource: name, withExtension: ext),
            Bundle.main.resourceURL?.appendingPathComponent(file),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/\(file)")
        ]
        if let match = direct.compactMap({ $0 }).first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
            return match
        }

        var directory = Bundle.main.bundleURL
        for _ in 0..<8 {
            let candidate = directory.appendingPathComponent("Resources/\(file)")
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            let parent = directory.deletingLastPathComponent()
            if parent.path == directory.path { break }
            directory = parent
        }
        return nil
    }

    static func registerFonts() {
        for name in ["PressStart2P-Regular", "VT323-Regular"] {
            guard let url = url(named: name, ext: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    @MainActor
    static func image(_ name: String) -> NSImage? {
        if let cached = cache[name] { return cached }
        guard let url = url(named: name, ext: "png"),
              let image = NSImage(contentsOf: url) else { return nil }
        cache[name] = image
        return image
    }

    @MainActor private static var cache: [String: NSImage] = [:]
}

struct BundledImage: View {
    var name: String
    var contentMode: ContentMode = .fill

    var body: some View {
        if let image = BrandAssets.image(name) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            Rectangle().fill(Theme.beigeDark)
        }
    }
}

struct BadgeRow: View {
    var side: CGFloat = 58

    private let names = [
        "badge-pet",
        "badge-vic20",
        "badge-c64",
        "badge-plus4",
        "badge-c128",
        "badge-mega65"
    ]

    var body: some View {
        HStack(spacing: max(4, side / 16)) {
            ForEach(names, id: \.self) { name in
                BundledImage(name: name)
                    .frame(width: side, height: side, alignment: .top)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: max(4, side / 10))
                            .stroke(Theme.outline, lineWidth: max(2, side / 22))
                    )
                    .accessibilityLabel(name.replacingOccurrences(of: "badge-", with: ""))
            }
        }
    }
}

enum QRCode {
    @MainActor private static var cached: NSImage?

    @MainActor
    static func joinImage() -> NSImage {
        if let cached { return cached }
        let image = make(Theme.joinURL, pointSide: 640) ?? NSImage(size: NSSize(width: 32, height: 32))
        cached = image
        return image
    }

    static func make(_ string: String, pointSide: CGFloat) -> NSImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }

        let extent = output.extent.integral
        guard extent.width > 0, extent.height > 0 else { return nil }
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        guard let small = context.createCGImage(output, from: extent) else { return nil }

        let scale = max(1, floor(pointSide / extent.width))
        let pixels = Int(extent.width * scale)
        guard let bitmap = CGContext(
            data: nil,
            width: pixels,
            height: pixels,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        bitmap.interpolationQuality = .none
        bitmap.setShouldAntialias(false)
        bitmap.draw(small, in: CGRect(x: 0, y: 0, width: pixels, height: pixels))
        guard let scaled = bitmap.makeImage() else { return nil }
        return NSImage(cgImage: scaled, size: NSSize(width: pixels, height: pixels))
    }
}

struct MembershipQR: View {
    var side: CGFloat

    var body: some View {
        Image(nsImage: QRCode.joinImage())
            .interpolation(.none)
            .resizable()
            .frame(width: side, height: side)
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 12).fill(Theme.cream)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.outline, lineWidth: max(3, side / 50))
            )
            .accessibilityLabel("YouTube membership QR code")
    }
}
