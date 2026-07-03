import SwiftUI

@main
struct DemoApp: App {
    private let dependencies: AppDependencies
    @State private var viewModel: DemoViewModel

    init() {
        let dependencies = AppDependencies.demoOffline
        self.dependencies = dependencies
        _viewModel = State(initialValue: DemoViewModel(dependencies: dependencies))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .environment(\.appDependencies, dependencies)
        }
    }
}
