import SwiftUI

struct ContentView: View {
    @State private var waves = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.20, green: 0.47, blue: 0.96), Color(red: 0.10, green: 0.20, blue: 0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("👋")
                    .font(.system(size: 96))
                    .rotationEffect(.degrees(waves % 2 == 1 ? 20 : 0))
                    .animation(.spring(duration: 0.3), value: waves)

                Text("Hello from Paul's App Store")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Built on the Mac, shipped through GitHub Pages, installed by AltStore.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    waves += 1
                } label: {
                    Text(waves == 0 ? "Wave back" : "Waved \(waves)×")
                        .font(.headline)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(.white, in: Capsule())
                        .foregroundStyle(Color(red: 0.10, green: 0.20, blue: 0.55))
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
