import SwiftUI

@main
struct DemoApp: App {
    @State private var viewModel = DemoViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
