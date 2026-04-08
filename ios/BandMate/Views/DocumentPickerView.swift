import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct DocumentPickerView: UIViewControllerRepresentable {
    let onImagesSelected: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.pdf, .image, .png, .jpeg]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onImagesSelected: onImagesSelected) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onImagesSelected: @MainActor ([UIImage]) -> Void

        init(onImagesSelected: @escaping @MainActor ([UIImage]) -> Void) {
            self.onImagesSelected = onImagesSelected
        }

        nonisolated func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let callback = onImagesSelected
            Task { @MainActor in
                var allImages: [UIImage] = []
                for url in urls {
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessing { url.stopAccessingSecurityScopedResource() }
                    }
                    if url.pathExtension.lowercased() == "pdf" {
                        let pages = renderAllPDFPages(url: url)
                        allImages.append(contentsOf: pages)
                    } else if let data = try? Data(contentsOf: url),
                              let image = UIImage(data: data) {
                        allImages.append(image)
                    }
                }
                if !allImages.isEmpty {
                    callback(allImages)
                }
            }
        }

        nonisolated func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}

private func renderAllPDFPages(url: URL) -> [UIImage] {
    guard let document = PDFDocument(url: url) else { return [] }
    var images: [UIImage] = []
    let scale: CGFloat = 2.0

    for i in 0..<document.pageCount {
        guard let page = document.page(at: i) else { continue }
        let pageRect = page.bounds(for: .mediaBox)
        let renderSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

        let renderer = UIGraphicsImageRenderer(size: renderSize)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: renderSize))
            context.cgContext.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: context.cgContext)
        }
        images.append(image)
    }
    return images
}
