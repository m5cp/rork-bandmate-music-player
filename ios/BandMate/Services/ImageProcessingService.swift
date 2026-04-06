import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

nonisolated struct ImageProcessingService: Sendable {
    static func enhanceSheetMusic(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        let context = CIContext()

        let adjustedImage = applyContrastAndBrightness(ciImage)
        let sharpenedImage = applySharpen(adjustedImage)
        let straightenedImage = applyStraighten(sharpenedImage)

        guard let cgImage = context.createCGImage(straightenedImage, from: straightenedImage.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage)
    }

    private static func applyContrastAndBrightness(_ image: CIImage) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.contrast = 1.3
        filter.brightness = 0.05
        filter.saturation = 0
        return filter.outputImage ?? image
    }

    private static func applySharpen(_ image: CIImage) -> CIImage {
        let filter = CIFilter.unsharpMask()
        filter.inputImage = image
        filter.radius = 2.0
        filter.intensity = 0.5
        return filter.outputImage ?? image
    }

    private static func applyStraighten(_ image: CIImage) -> CIImage {
        let filter = CIFilter.straighten()
        filter.inputImage = image
        filter.angle = 0
        return filter.outputImage ?? image
    }
}
