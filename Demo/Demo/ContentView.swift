import Observation
import SwiftUI
import FVendors

struct ContentView: View {
    @Bindable var viewModel: DemoViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FVendors Demo")
                            .font(.largeTitle.bold())
                        Text("A minimal example showing logging, decoding, cache-first loading, and simple SwiftUI state updates.")
                            .foregroundStyle(.secondary)
                    }

                    GroupBox("User") {
                        VStack(alignment: .leading, spacing: 10) {
                            row("Name", viewModel.user?.name ?? "Not loaded")
                            row("Email", viewModel.user?.email ?? "Not loaded")
                            row("Source", viewModel.dataSource?.displayName ?? "None")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    GroupBox("Status") {
                        VStack(alignment: .leading, spacing: 10) {
                            row("State", viewModel.statusMessage)
                            row("Loading", viewModel.isLoading ? "Yes" : "No")
                            if let error = viewModel.lastErrorMessage {
                                Text(error)
                                    .foregroundStyle(.red)
                                    .font(.footnote)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(spacing: 12) {
                        Button {
                            Task {
                                await viewModel.loadUser()
                            }
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Load User")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isLoading)

                        Button("Clear Cache") {
                            Task {
                                await viewModel.clearCache()
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isLoading && viewModel.user == nil)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Demo")
        }
    }

    @ViewBuilder
    private func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    ContentView(
        viewModel: DemoViewModel(
            logger: .noop,
            network: .mock { _ in
                try JSONEncoder().encode(
                    DemoUser(id: 1, name: "Taylor Swift", email: "taylor@example.com")
                )
            },
            cache: .inMemory()
        )
    )
}
