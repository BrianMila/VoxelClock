import Foundation

// 3-wide x 5-tall pixel bitmap font for digits 0–9, plus a 1-wide colon.
// Each UInt8 row: bit 2 = leftmost column, bit 0 = rightmost.
enum DigitFont {
    static let digitWidth = 3
    static let colonWidth = 1
    static let height = 5

    static let glyphs: [Int: [UInt8]] = [
        0: [0b111, 0b101, 0b101, 0b101, 0b111],
        1: [0b010, 0b110, 0b010, 0b010, 0b111],
        2: [0b111, 0b001, 0b111, 0b100, 0b111],
        3: [0b111, 0b001, 0b111, 0b001, 0b111],
        4: [0b101, 0b101, 0b111, 0b001, 0b001],
        5: [0b111, 0b100, 0b111, 0b001, 0b111],
        6: [0b111, 0b100, 0b111, 0b101, 0b111],
        7: [0b111, 0b001, 0b001, 0b010, 0b010],
        8: [0b111, 0b101, 0b111, 0b101, 0b111],
        9: [0b111, 0b101, 0b111, 0b001, 0b111],
    ]

    // Colon: single-column dots in rows 1 and 3
    static let colonGlyph: [UInt8] = [
        0b0,
        0b1,
        0b0,
        0b1,
        0b0,
    ]

    static func pixels(for digit: Int) -> [(col: Int, row: Int)] {
        guard let rows = glyphs[digit] else { return [] }
        return pixels(from: rows, width: digitWidth)
    }

    static func colonPixels() -> [(col: Int, row: Int)] {
        pixels(from: colonGlyph, width: colonWidth)
    }

    private static func pixels(from rows: [UInt8], width: Int) -> [(col: Int, row: Int)] {
        var result: [(Int, Int)] = []
        for (r, bits) in rows.enumerated() {
            for c in 0..<width where bits & (1 << (width - 1 - c)) != 0 {
                result.append((c, r))
            }
        }
        return result
    }
}
