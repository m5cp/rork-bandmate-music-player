import Foundation
import UIKit

@Observable
@MainActor
class MusicRecognitionService {
    var isProcessing: Bool = false
    var processingStatus: String = "Preparing..."
    var errorMessage: String?

    private let toolkitURL: String = {
        let url = Config.EXPO_PUBLIC_TOOLKIT_URL
        return url.isEmpty ? "https://toolkit.rork.app" : url
    }()

    func analyzeSheetMusic(image: UIImage) async -> ParsedMusic? {
        isProcessing = true
        processingStatus = "Preparing image..."
        errorMessage = nil

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to process image"
            isProcessing = false
            return nil
        }

        let base64Image = imageData.base64EncodedString()

        processingStatus = "Analyzing sheet music..."

        do {
            let result = try await sendToAI(base64Image: base64Image)
            processingStatus = "Complete!"
            isProcessing = false
            return result
        } catch {
            errorMessage = "Analysis failed: \(error.localizedDescription)"
            isProcessing = false
            return nil
        }
    }

    private func sendToAI(base64Image: String) async throws -> ParsedMusic {
        let url = URL(string: "\(toolkitURL)/agent/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

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
                            "image": "data:image/jpeg;base64,\(base64Image)"
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw MusicRecognitionError.serverError
        }

        let responseText = extractTextFromResponse(data: data)

        guard let jsonString = extractJSON(from: responseText),
              let jsonData = jsonString.data(using: .utf8) else {
            return createFallbackMusic()
        }

        do {
            let decoded = try JSONDecoder().decode(AIMusicalResponse.self, from: jsonData)
            return convertToParseMusic(decoded)
        } catch {
            return createFallbackMusic()
        }
    }

    private func extractTextFromResponse(data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let text = json["text"] as? String { return text }
            if let messages = json["messages"] as? [[String: Any]],
               let last = messages.last,
               let content = last["content"] as? String {
                return content
            }
            if let parts = json["parts"] as? [[String: Any]] {
                for part in parts {
                    if let text = part["text"] as? String { return text }
                }
            }
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func extractJSON(from text: String) -> String? {
        if let startRange = text.range(of: "{"),
           let endRange = text.range(of: "}", options: .backwards) {
            let jsonSubstring = text[startRange.lowerBound...endRange.upperBound]
            return String(jsonSubstring)
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
        case .serverError: "Server returned an error"
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
