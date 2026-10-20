import SwiftUI

struct ContentView: View {
    @State private var vm = ClockViewModel()

    var body: some View {
        VoxelClockRealityView(digits: vm.digits)
    }
}
