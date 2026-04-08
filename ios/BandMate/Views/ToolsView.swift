import SwiftUI

struct ToolsView: View {
    @State private var selectedTool: ToolType = .metronome

    nonisolated enum ToolType: String, CaseIterable {
        case metronome = "Metronome"
        case tuner = "Tuner"

        var icon: String {
            switch self {
            case .metronome: "metronome.fill"
            case .tuner: "tuningfork"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tool", selection: $selectedTool) {
                    ForEach(ToolType.allCases, id: \.rawValue) { tool in
                        Label(tool.rawValue, systemImage: tool.icon)
                            .tag(tool)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)

                Group {
                    switch selectedTool {
                    case .metronome:
                        MetronomeView()
                    case .tuner:
                        TunerView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tools")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
