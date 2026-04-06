import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct DocumentPickerView: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.pdf, .image, .png, .jpeg]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onImageSelected: onImageSelected) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onImageSelected: @MainActor (UIImage) -> Void

        init(onImageSelected: @escaping @MainActor (UIImage) -> Void) {
            self.onImageSelected = onImageSelected
        }

        nonisolated func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            let accessing = url.startAccessingSecurityScopedResource()

            let callback = onImageSelected
            Task { @MainActor in
                defer {
                    if accessing { url.stopAccessingSecurityScopedResource() }
                }
                if url.pathExtension.lowercased() == "pdf" {
                    if let image = renderPDFFirstPage(url: url) {
                        callback(image)
                    }
                } else if let data = try? Data(contentsOf: url),
                          let image = UIImage(data: data) {
                    callback(image)
                }
            }
        }

        nonisolated func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}

private func renderPDFFirstPage(url: URL) -> UIImage? {
    guard let document = PDFDocument(url: url),
          let page = document.page(at: 0) else { return nil }

    let pageRect = page.bounds(for: .mediaBox)
    let scale: CGFloat = 2.0
    let renderSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

    let renderer = UIGraphicsImageRenderer(size: renderSize)
    return renderer.image { context in
        UIColor.white.setFill()
        context.fill(CGRect(origin: .zero, size: renderSize))
        context.cgContext.scaleBy(x: scale, y: scale)
        page.draw(with: .mediaBox, to: context.cgContext)
    }
}
