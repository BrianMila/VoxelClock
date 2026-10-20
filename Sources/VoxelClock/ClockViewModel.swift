import Foundation
import Observation

@Observable
@MainActor
final class ClockViewModel {
    private(set) var digits: [Int] = [0, 0, 0, 0]

    private var timer: Timer?

    init() {
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        let now = Date()
        let cal = Calendar.current
        let h = cal.component(.hour, from: now)
        let m = cal.component(.minute, from: now)
        digits = [h / 10, h % 10, m / 10, m % 10]
    }
}
