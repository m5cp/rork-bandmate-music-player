import SwiftUI
import SwiftData

@Observable
@MainActor
class HomeViewModel {
    var showCamera: Bool = false
    var showPhotoPicker: Bool = false
    var showDocumentPicker: Bool = false
    var selectedImage: UIImage?
    var showProcessing: Bool = false
    var isProcessingImages: Bool = false

    func handleCapturedImage(_ image: UIImage) {
        let enhanced = ImageProcessingService.enhanceSheetMusic(image)
        selectedImage = enhanced
        showProcessing = true
    }

    func handleSelectedImage(_ image: UIImage) {
        let enhanced = ImageProcessingService.enhanceSheetMusic(image)
        selectedImage = enhanced
        showProcessing = true
    }

    func handleMultipleImages(_ images: [UIImage]) {
        guard !images.isEmpty else { return }
        isProcessingImages = true
        if images.count == 1 {
            isProcessingImages = false
            handleSelectedImage(images[0])
            return
        }
        let stitched = stitchImagesVertically(images)
        let enhanced = ImageProcessingService.enhanceSheetMusic(stitched)
        isProcessingImages = false
        selectedImage = enhanced
        showProcessing = true
    }

    private func stitchImagesVertically(_ images: [UIImage]) -> UIImage {
        let targetWidth: CGFloat = 1024
        let maxTotalHeight: CGFloat = 4096
        var scaledImages: [(image: UIImage, size: CGSize)] = []
        var totalHeight: CGFloat = 0

        for img in images {
            let scale = targetWidth / max(img.size.width, 1)
            let scaledHeight = img.size.height * scale
            let size = CGSize(width: targetWidth, height: scaledHeight)
            scaledImages.append((img, size))
            totalHeight += scaledHeight
        }

        if totalHeight > maxTotalHeight {
            let shrink = maxTotalHeight / totalHeight
            scaledImages = scaledImages.map { item in
                let newSize = CGSize(width: item.size.width * shrink, height: item.size.height * shrink)
                return (item.image, newSize)
            }
            totalHeight = maxTotalHeight
        }

        let finalWidth = scaledImages.first?.size.width ?? targetWidth
        let totalSize = CGSize(width: finalWidth, height: totalHeight)
        let renderer = UIGraphicsImageRenderer(size: totalSize)
        return renderer.image { _ in
            var yOffset: CGFloat = 0
            for item in scaledImages {
                item.image.draw(in: CGRect(origin: CGPoint(x: 0, y: yOffset), size: item.size))
                yOffset += item.size.height
            }
        }
    }
}
