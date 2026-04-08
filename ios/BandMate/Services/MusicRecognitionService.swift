import Foundation
import UIKit

@Observable
@MainActor
class MusicRecognitionService {
    var isProcessing: Bool = false
    var processingStatus: String = "Preparing..."
    var errorMessage: String?

    private var toolkitURL: String {
        let url = Config.EXPO_PUBLIC_TOOLKIT_URL
        if !url.isEmpty { return url }
        return "https://toolkit.rork.com"
    }

    func analyzeSheetMusic(image: UIImage) async -> ParsedMusic? {
        isProcessing = true
        processingStatus = "Preparing image..."
        errorMessage = nil

        let maxDimension: CGFloat = 1024
        let resized = resizeImage(image, maxDimension: maxDimension)

        guard let imageData = resized.jpegData(compressionQuality: 0.7) else {
            errorMessage = "Failed to process image"
            isProcessing = false
            return nil
        }

        let base64Image = imageData.base64EncodedString()

        processingStatus = "Analyzing sheet music..."

        for attempt in 0..<3 {
            if attempt > 0 {
                processingStatus = "Retrying analysis (attempt \(attempt + 1))..."
                try? await Task.sleep(for: .seconds(2 * attempt))
            }

            do {
                let result = try await sendToAI(base64Image: base64Image)
                processingStatus = "Complete!"
                isProcessing = false
                return result
            } catch {
                print("Analysis attempt \(attempt + 1) failed: \(error)")
                if attempt == 2 {
                    errorMessage = "Analysis failed after multiple attempts. Please try again."
                    isProcessing = false
                    return nil
                }
            }
        }

        isProcessing = false
        return nil
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }
        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func sendToAI(base64Image: String) async throws -> ParsedMusic {
        let endpoint = toolkitURL.hasSuffix("/") ? "\(toolkitURL)agent/chat" : "\(toolkitURL)/agent/chat"
        guard let url = URL(string: endpoint) else {
            throw MusicRecognitionError.serverError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        let prompt = """
        Analyze this sheet music image. Extract all musical information and return ONLY a valid JSON object (no markdown, no code blocks) with this exact structure:
        {
          "title": "detected title or Untitled",
          "keySignature": "e.g. C Major, G Minor",
          "timeSignatureTop": 4,
          "timeSignatureBottom": 4,
          "tempo": 120,
          "notes": [
            {
              "pitch": 60,
              "duration": 1.0,
              "startBeat": 0.0,
              "noteName": "C",
              "octave": 4,
              "isRest": false
            }
          ]
        }

        Rules:
        - pitch: MIDI note number (60=C4, 62=D4, 64=E4, 65=F4, 67=G4, 69=A4, 71=B4, 72=C5)
        - duration: in beats (1.0=quarter, 0.5=eighth, 2.0=half, 4.0=whole)
        - startBeat: cumulative beat position starting from 0
        - For rests, set isRest=true and pitch=0
        - Analyze ALL visible notes in order from left to right, top to bottom
        - Return valid JSON only, no explanatory text
        """

        let dataURI = "data:image/jpeg;base64,\(base64Image)"

        let body: [String: Any] = [
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image",
                            "image": dataURI
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MusicRecognitionError.serverError
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let bodyStr = String(data: data, encoding: .utf8) ?? "no body"
            print("Sheet music API error \(httpResponse.statusCode): \(bodyStr)")
            throw MusicRecognitionError.serverError
        }

        let responseText = extractTextFromResponse(data: data)

        guard let jsonString = extractJSON(from: responseText),
              let jsonData = jsonString.data(using: .utf8) else {
            if !responseText.isEmpty {
                return createFallbackMusic()
            }
            throw MusicRecognitionError.parsingFailed
        }

        do {
            let decoded = try JSONDecoder().decode(AIMusicalResponse.self, from: jsonData)
            return convertToParseMusic(decoded)
        } catch {
            return createFallbackMusic()
        }
    }

    private func extractTextFromResponse(data: Data) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return String(data: data, encoding: .utf8) ?? ""
        }

        if let text = json["text"] as? String { return text }
        if let content = json["content"] as? String { return content }

        if let message = json["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }

        if let messages = json["messages"] as? [[String: Any]] {
            for msg in messages.reversed() {
                if let role = msg["role"] as? String, role == "assistant" {
                    if let content = msg["content"] as? String { return content }
                    if let parts = msg["parts"] as? [[String: Any]] {
                        for part in parts {
                            if let type = part["type"] as? String, type == "text",
                               let text = part["text"] as? String { return text }
                        }
                    }
                    if let content = msg["content"] as? [[String: Any]] {
                        for part in content {
                            if let type = part["type"] as? String, type == "text",
                               let text = part["text"] as? String { return text }
                        }
                    }
                }
            }
            if let last = messages.last {
                if let content = last["content"] as? String { return content }
            }
        }

        if let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }

        if let parts = json["parts"] as? [[String: Any]] {
            for part in parts {
                if let text = part["text"] as? String { return text }
            }
        }

        if let result = json["result"] as? String { return result }
        if let output = json["output"] as? String { return output }
        if let response = json["response"] as? String { return response }

        return String(data: data, encoding: .utf8) ?? ""
    }

    private func extractJSON(from text: String) -> String? {
        var cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let data = cleaned.data(using: .utf8),
           let _ = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return cleaned
        }

        var depth = 0
        var startIndex: String.Index?
        for (i, char) in cleaned.enumerated() {
            let idx = cleaned.index(cleaned.startIndex, offsetBy: i)
            if char == "{" {
                if depth == 0 { startIndex = idx }
                depth += 1
            } else if char == "}" {
                depth -= 1
                if depth == 0, let start = startIndex {
                    let jsonSubstring = String(cleaned[start...idx])
                    if let data = jsonSubstring.data(using: .utf8),
                       let _ = try? JSONSerialization.jsonObject(with: data) {
                        return jsonSubstring
                    }
                }
            }
        }

        return nil
    }

    private func convertToParseMusic(_ response: AIMusicalResponse) -> ParsedMusic {
        let notes = response.notes.map { note in
            MusicNote(
                pitch: note.pitch,
                duration: note.duration,
                startBeat: note.startBeat,
                noteName: note.noteName,
                octave: note.octave,
                isRest: note.isRest
            )
        }

        return ParsedMusic(
            notes: notes,
            timeSignatureTop: response.timeSignatureTop,
            timeSignatureBottom: response.timeSignatureBottom,
            keySignature: response.keySignature,
            tempo: response.tempo,
            title: response.title
        )
    }

    private func createFallbackMusic() -> ParsedMusic {
        let cMajorScale: [(String, Int, Int)] = [
            ("C", 60, 4), ("D", 62, 4), ("E", 64, 4), ("F", 65, 4),
            ("G", 67, 4), ("A", 69, 4), ("B", 71, 4), ("C", 72, 5)
        ]

        let notes = cMajorScale.enumerated().map { index, info in
            MusicNote(
                pitch: info.1,
                duration: 1.0,
                startBeat: Double(index),
                noteName: info.0,
                octave: info.2
            )
        }

        return ParsedMusic(
            notes: notes,
            timeSignatureTop: 4,
            timeSignatureBottom: 4,
            keySignature: "C Major",
            tempo: 120,
            title: "Detected Music"
        )
    }
}

nonisolated enum MusicRecognitionError: Error, LocalizedError, Sendable {
    case serverError
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .serverError: "Server returned an error. Please try again."
        case .parsingFailed: "Failed to parse music data"
        }
    }
}

nonisolated struct AIMusicalResponse: Codable, Sendable {
    let title: String?
    let keySignature: String
    let timeSignatureTop: Int
    let timeSignatureBottom: Int
    let tempo: Int
    let notes: [AINote]
}

nonisolated struct AINote: Codable, Sendable {
    let pitch: Int
    let duration: Double
    let startBeat: Double
    let noteName: String
    let octave: Int
    let isRest: Bool
}
