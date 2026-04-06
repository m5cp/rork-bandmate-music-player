import SwiftUI
import AVFoundation
import VisionKit

struct CameraProxyView: View {
    let onCapture: (UIImage) -> Void

    @State private var showScanner: Bool = false
    @State private var showTips: Bool = true

    var body: some View {
        #if targetEnvironment(simulator)
        CameraUnavailablePlaceholder()
        #else
        if AVCaptureDevice.default(for: .video) != nil {
            if showTips {
                ScanningTipsView(onContinue: {
                    showTips = false
                    showScanner = true
                })
            } else if showScanner {
                DocumentScannerView(onCapture: onCapture)
            }
        } else {
            CameraUnavailablePlaceholder()
        }
        #endif
    }
}

struct ScanningTipsView: View {
    let onContinue: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let tips: [(icon: String, text: String)] = [
        ("doc.viewfinder", "Place the sheet music flat on a surface and align it within the frame"),
        ("light.max", "Make sure the area is well-lit with no harsh shadows across the page"),
        ("music.note", "All notes and musical symbols should be clearly visible"),
        ("hand.raised.slash", "Avoid fingers, objects, or anything covering the music"),
        ("textformat", "If the piece has a title or tempo marking, include it in the frame"),
        ("arrow.triangle.2.circlepath", "The scanner will auto-detect the page edges — hold steady")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 10) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 52, weight: .light))
                                .foregroundStyle(.blue)
                                .symbolEffect(.pulse, options: .repeating)

                            Text("Scanning Tips")
                                .font(.title2.bold())

                            Text("For the best music recognition results, follow these guidelines before scanning.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        .padding(.top, 8)

                        VStack(spacing: 0) {
                            ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: tip.icon)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.blue)
                                        .frame(width: 32, height: 32)
                                        .background(Color.blue.opacity(0.1), in: .rect(cornerRadius: 8))
                                        .accessibilityHidden(true)

                                    Text(tip.text)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Tip \(index + 1): \(tip.text)")

                                if index < tips.count - 1 {
                                    Divider()
                                        .padding(.leading, 62)
                                }
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }

                VStack(spacing: 10) {
                    Button {
                        onContinue()
                    } label: {
                        Label("Open Scanner", systemImage: "camera.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(.bar)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct DocumentScannerView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onCapture: (UIImage) -> Void

        init(onCapture: @escaping (UIImage) -> Void) {
            self.onCapture = onCapture
        }

        nonisolated func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else {
                Task { @MainActor in
                    controller.dismiss(animated: true)
                }
                return
            }
            let image = scan.imageOfPage(at: 0)
            Task { @MainActor in
                onCapture(image)
                controller.dismiss(animated: true)
            }
        }

        nonisolated func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            Task { @MainActor in
                controller.dismiss(animated: true)
            }
        }

        nonisolated func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            Task { @MainActor in
                controller.dismiss(animated: true)
            }
        }
    }
}

struct CameraUnavailablePlaceholder: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Camera Preview")
                    .font(.title2.bold())
                Text("Install this app on your device\nvia the Rork App to use the camera.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
