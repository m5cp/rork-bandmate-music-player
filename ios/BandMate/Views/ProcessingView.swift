import SwiftUI
import SwiftData

struct ProcessingView: View {
    let image: UIImage
    @Binding var navigationPath: NavigationPath
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = ProcessingViewModel()
    @State private var animationPhase: Bool = false

    var body: some View {
        Group {
            if viewModel.isComplete, let music = viewModel.parsedMusic {
                ResultsView(
                    music: music,
                    image: image,
                    navigationPath: $navigationPath
                )
            } else if viewModel.hasError {
                errorView
            } else {
                processingView
            }
        }
        .navigationTitle("Analyzing")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.processImage(image)
        }
    }

    private var processingView: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 4)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(animationPhase ? 360 : 0))
                    .animation(reduceMotion ? nil : .linear(duration: 1).repeatForever(autoreverses: false), value: animationPhase)

                Image(systemName: "music.note")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse, isActive: !reduceMotion)
            }

            VStack(spacing: 8) {
                Text(viewModel.recognitionService.processingStatus)
                    .font(.headline)
                Text("This may take a moment...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Analyzing sheet music. \(viewModel.recognitionService.processingStatus)")

            Spacer()
        }
        .onAppear { animationPhase = true }
    }

    private var errorView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            Text("Analysis Failed")
                .font(.title2.bold())

            Text(viewModel.recognitionService.errorMessage ?? "Something went wrong. Please try again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Try Again") {
                viewModel.hasError = false
                Task {
                    await viewModel.processImage(image)
                }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint("Attempts to analyze the sheet music again")

            Spacer()
        }
    }
}
