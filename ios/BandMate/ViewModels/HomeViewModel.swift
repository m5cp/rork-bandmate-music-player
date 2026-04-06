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
}
