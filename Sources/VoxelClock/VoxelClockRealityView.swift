import SwiftUI
import RealityKit
import UIKit

struct VoxelClockRealityView: View {
    var digits: [Int]

    // Cube dimensions — big chunky voxels
    private let cubeSize: Float = 0.026
    private let gap: Float = 0.004
    private var step: Float { cubeSize + gap }

    // Layout column offsets (0-indexed, in cube steps)
    // Four 3-wide digits + 1-wide colon, 1-column gaps throughout:
    // [D0]_[D1]_[:]_[D2]_[D3]
    private let digitColOffsets = [0, 4, 10, 14]
    private let colonColOffset  = 8
    private let totalCols: Float = 17
    private let totalRows: Float = 5

    // Pink → purple → blue, one color per digit position
    private let digitColors: [SIMD3<Float>] = [
        SIMD3(0.169, 0.525, 0.773),  // blue       (hours tens)
        SIMD3(0.471, 0.290, 0.700),  // purple      (hours units)
        SIMD3(0.720, 0.220, 0.680),  // pink-purple (minutes tens)
        SIMD3(1.000, 0.235, 0.675),  // hot pink    (minutes units)
    ]
    private let colonColor = SIMD3<Float>(0.600, 0.255, 0.690)

    var body: some View {
        RealityView { content in
            let root = Entity()
            // Volumes get little/no environment light for PBR materials,
            // so supply our own image-based light: a procedural "studio"
            // environment with bright softboxes for plastic-like highlights.
            if let image = Self.studioLightingImage(),
               let env = try? await EnvironmentResource(equirectangular: image) {
                // Exponent of 0 uses the image intensities as-is
                // (each +1 doubles the light and blows out highlights)
                root.components.set(ImageBasedLightComponent(
                    source: .single(env),
                    intensityExponent: 0.0
                ))
            }
            rebuildCubes(in: root)
            content.add(root)
        } update: { content in
            guard let root = content.entities.first else { return }
            rebuildCubes(in: root)
        }
    }

    private func rebuildCubes(in root: Entity) {
        root.children.removeAll()
        let xBase = -totalCols / 2.0 * step
        let yBase =  totalRows / 2.0 * step

        for (i, digit) in digits.enumerated() {
            let colBase = Float(digitColOffsets[i])
            let color   = digitColors[i]
            for (col, row) in DigitFont.pixels(for: digit) {
                let e = makeCube(color: color, litBy: root)
                e.position = [
                    xBase + (colBase + Float(col)) * step,
                    yBase - Float(row) * step,
                    0
                ]
                root.addChild(e)
            }
        }

        // Colon
        for (col, row) in DigitFont.colonPixels() {
            let e = makeCube(color: colonColor, litBy: root)
            e.position = [
                xBase + (Float(colonColOffset) + Float(col)) * step,
                yBase - Float(row) * step,
                0
            ]
            root.addChild(e)
        }
    }

    private func makeCube(color: SIMD3<Float>, litBy lightSource: Entity) -> ModelEntity {
        let mesh = MeshResource.generateBox(size: cubeSize, cornerRadius: 0.003)
        var mat  = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: .init(
            red:   CGFloat(color.x),
            green: CGFloat(color.y),
            blue:  CGFloat(color.z),
            alpha: 1.0
        ))
        // High-gloss plastic: very smooth dielectric with a polished clearcoat
        mat.roughness          = .init(floatLiteral: 0.08)
        mat.metallic           = .init(floatLiteral: 0.0)
        mat.clearcoat          = .init(floatLiteral: 1.0)
        mat.clearcoatRoughness = .init(floatLiteral: 0.03)
        let entity = ModelEntity(mesh: mesh, materials: [mat])
        // PBR materials only pick up our IBL if they opt in as receivers
        entity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: lightSource))
        return entity
    }

    // Generates a small equirectangular lighting image: bright sky above,
    // dimmer floor below, plus two white "softbox" spots that produce the
    // sharp specular highlights characteristic of shiny plastic.
    private static func studioLightingImage() -> CGImage? {
        let width = 256, height = 128
        guard let ctx = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // Gentle vertical gradient: a near-even studio gray so no face
        // direction washes out; the softboxes below supply the sparkle.
        let colors = [
            UIColor(white: 0.62, alpha: 1).cgColor,
            UIColor(white: 0.50, alpha: 1).cgColor,
            UIColor(white: 0.38, alpha: 1).cgColor,
        ] as CFArray
        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: [0.0, 0.55, 1.0]
        ) {
            // CGContext origin is bottom-left; image top (sky) is y = height
            ctx.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: height),
                end: .zero,
                options: []
            )
        }

        // Softbox highlights, placed above the horizon
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fillEllipse(in: CGRect(x: 40,  y: 84, width: 52, height: 28))
        ctx.fillEllipse(in: CGRect(x: 168, y: 90, width: 38, height: 22))

        return ctx.makeImage()
    }
}
