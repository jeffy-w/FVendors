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

                    GroupBox("Tomato Generator") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Spawned: \(viewModel.tomatoes.count)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(viewModel.tomatoes) { tomato in
                                        TomatoView(tomato: tomato)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .padding(.vertical, 10)
                            }
                            .frame(minHeight: 80)
                            
                            HStack {
                                Button("Spawn Tomato") {
                                    withAnimation(.spring()) {
                                        viewModel.spawnTomato()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button("Clear") {
                                    withAnimation {
                                        viewModel.clearTomatoes()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .foregroundStyle(.red)
                            }
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

struct TomatoView: View {
    let tomato: TomatoEmoji
    
    var body: some View {
        ZStack {
            // Body (Tomato Shape)
            Circle()
                .fill(Color(hex: tomato.bodyColor))
                .frame(width: 60, height: 60)
                .overlay(alignment: .top) {
                    // Green Leaf
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 14))
                        .offset(y: -5)
                }
            
            // Face Group
            VStack(spacing: 2) {
                // Eyes
                HStack(spacing: 12) {
                    Text(tomato.eyeType.rawValue)
                    Text(tomato.eyeType.rawValue)
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.black.opacity(0.8))
                
                // Mouth
                Text(tomato.mouthType.rawValue)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.black.opacity(0.8))
                    .offset(y: 2)
            }
            .offset(y: 4)
            
            // Blush
            if tomato.blushVisible {
                HStack(spacing: 28) {
                    Circle()
                        .fill(.pink.opacity(0.4))
                        .frame(width: 10, height: 4)
                    Circle()
                        .fill(.pink.opacity(0.4))
                        .frame(width: 10, height: 4)
                }
                .offset(y: 8)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 12) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
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
