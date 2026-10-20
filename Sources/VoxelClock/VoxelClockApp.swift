import SwiftUI

@main
struct VoxelClockApp: App {
    var body: some Scene {
        // A single volumetric window is a valid main scene on visionOS;
        // no separate launcher window is needed.
        WindowGroup {
            ContentView()
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.55, height: 0.18, depth: 0.12, in: .meters)
    }
}
