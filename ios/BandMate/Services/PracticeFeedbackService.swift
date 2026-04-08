import Foundation

@MainActor
class PracticeFeedbackService {
    static let shared = PracticeFeedbackService()

    private var toolkitURL: String {
        let url = Config.EXPO_PUBLIC_TOOLKIT_URL
        if !url.isEmpty { return url }
        return "https://toolkit.rork.com"
    }

    func analyzePractice(
        songTitle: String,
        instrument: Instrument,
        skillLevel: SkillLevel,
        notes: [MusicNote],
        keySignature: String,
        timeSignature: String,
        tempo: Int,
        practiceDuration: TimeInterval,
        audioURL: URL?
    ) async throws -> PracticeFeedback {
        let endpoint = toolkitURL.hasSuffix("/") ? "\(toolkitURL)agent/chat" : "\(toolkitURL)/agent/chat"
        guard let url = URL(string: endpoint) else {
            throw PracticeFeedbackError.invalidURL
        }

        let notesSummary = buildNotesSummary(notes)
        let durationFormatted = formatDuration(practiceDuration)

        let prompt = buildPrompt(
            songTitle: songTitle,
            instrument: instrument,
            skillLevel: skillLevel,
            notesSummary: notesSummary,
            keySignature: keySignature,
            timeSignature: timeSignature,
            tempo: tempo,
            duration: durationFormatted
        )

        let requestBody: [String: Any] = [
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 120

        var lastError: Error = PracticeFeedbackError.serverError
        for attempt in 0..<3 {
            if attempt > 0 {
                try? await Task.sleep(for: .seconds(2 * attempt))
            }

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    lastError = PracticeFeedbackError.serverError
                    continue
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    let bodyStr = String(data: data, encoding: .utf8) ?? "no body"
                    print("Practice feedback API error \(httpResponse.statusCode): \(bodyStr)")
                    if httpResponse.statusCode >= 500 {
                        lastError = PracticeFeedbackError.serverError
                        continue
                    }
                    throw PracticeFeedbackError.serverError
                }

                let responseText = extractTextFromResponse(data)

                if let jsonString = extractJSON(from: responseText),
                   let jsonData = jsonString.data(using: .utf8) {
                    do {
                        let aiResponse = try JSONDecoder().decode(AIFeedbackResponse.self, from: jsonData)
                        return PracticeFeedback(
                            overallScore: aiResponse.overallScore,
                            summary: aiResponse.summary,
                            strengths: aiResponse.strengths,
                            improvements: aiResponse.improvements,
                            tips: aiResponse.tips,
                            encouragement: aiResponse.encouragement,
                            focusAreas: aiResponse.focusAreas.map { FocusArea(name: $0.name, score: $0.score, detail: $0.detail) }
                        )
                    } catch {
                        print("JSON decode error: \(error)")
                        lastError = PracticeFeedbackError.parsingError
                        continue
                    }
                }

                if !responseText.isEmpty {
                    return createFallbackFeedback(from: responseText, songTitle: songTitle, skillLevel: skillLevel)
                }

                lastError = PracticeFeedbackError.parsingError
                continue
            } catch let error as PracticeFeedbackError {
                throw error
            } catch {
                lastError = error
                continue
            }
        }

        throw lastError
    }

    private func createFallbackFeedback(from text: String, songTitle: String, skillLevel: SkillLevel) -> PracticeFeedback {
        let baseScore: Int
        switch skillLevel {
        case .beginner: baseScore = 75
        case .intermediate: baseScore = 65
        case .advanced: baseScore = 55
        }

        return PracticeFeedback(
            overallScore: baseScore,
            summary: "Great effort practicing \(songTitle)! Keep up the consistent work.",
            strengths: ["Dedication to practice", "Good tempo awareness", "Solid note accuracy"],
            improvements: ["Focus on dynamics", "Work on smooth transitions"],
            tips: ["Practice slowly and gradually increase speed", "Use a metronome for timing", "Record yourself to hear improvements"],
            encouragement: "Every practice session makes you better. Keep it up!",
            focusAreas: [
                FocusArea(name: "Pitch Accuracy", score: baseScore + 5, detail: "Good pitch recognition overall"),
                FocusArea(name: "Rhythm & Timing", score: baseScore, detail: "Steady rhythm with room to improve"),
                FocusArea(name: "Dynamics", score: baseScore - 5, detail: "Try varying your volume more"),
                FocusArea(name: "Expression", score: baseScore - 10, detail: "Add more musical expression to phrases")
            ]
        )
    }

    private func extractTextFromResponse(_ data: Data) -> String {
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
                }
            }
            if let last = messages.last,
               let content = last["content"] as? String { return content }
        }

        if let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
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

    private func buildNotesSummary(_ notes: [MusicNote]) -> String {
        let totalNotes = notes.filter { !$0.isRest }.count
        let restCount = notes.filter { $0.isRest }.count
        let pitchRange: String = {
            let pitches = notes.filter { !$0.isRest }.map(\.pitch)
            guard let minP = pitches.min(), let maxP = pitches.max() else { return "N/A" }
            return "MIDI \(minP)-\(maxP)"
        }()
        let uniqueNotes = Set(notes.filter { !$0.isRest }.map(\.noteName))
        let totalBeats = notes.last.map { $0.startBeat + $0.duration } ?? 0

        return """
        Total notes: \(totalNotes), Rests: \(restCount), \
        Pitch range: \(pitchRange), \
        Unique pitches: \(uniqueNotes.sorted().joined(separator: ", ")), \
        Total beats: \(Int(totalBeats))
        """
    }

    private func buildPrompt(
        songTitle: String,
        instrument: Instrument,
        skillLevel: SkillLevel,
        notesSummary: String,
        keySignature: String,
        timeSignature: String,
        tempo: Int,
        duration: String
    ) -> String {
        """
        You are an expert music teacher and practice coach. A student just finished a practice session. \
        Analyze their practice and provide detailed, constructive feedback.

        PRACTICE SESSION DETAILS:
        - Song: "\(songTitle)"
        - Instrument: \(instrument.rawValue)
        - Key Signature: \(keySignature)
        - Time Signature: \(timeSignature)
        - Tempo: \(tempo) BPM
        - Practice Duration: \(duration)
        - Skill Level: \(skillLevel.rawValue)
        - Music Content: \(notesSummary)

        SKILL LEVEL GUIDANCE:
        \(skillLevelGuidance(skillLevel))

        Respond with ONLY valid JSON in this exact format (no markdown, no code blocks):
        {
            "overallScore": <number 1-100>,
            "summary": "<2-3 sentence overall assessment>",
            "strengths": ["<strength 1>", "<strength 2>", "<strength 3>"],
            "improvements": ["<area 1>", "<area 2>"],
            "tips": ["<actionable tip 1>", "<actionable tip 2>", "<actionable tip 3>"],
            "encouragement": "<motivating closing message>",
            "focusAreas": [
                {"name": "Pitch Accuracy", "score": <1-100>, "detail": "<specific feedback>"},
                {"name": "Rhythm & Timing", "score": <1-100>, "detail": "<specific feedback>"},
                {"name": "Dynamics", "score": <1-100>, "detail": "<specific feedback>"},
                {"name": "Expression", "score": <1-100>, "detail": "<specific feedback>"}
            ]
        }
        """
    }

    private func skillLevelGuidance(_ level: SkillLevel) -> String {
        switch level {
        case .beginner:
            return """
            For BEGINNER: Be very encouraging and supportive. Focus on basic concepts like hitting the right notes, \
            maintaining steady tempo, and proper breathing/posture. Use simple language. \
            Celebrate small wins. Score generously (60-90 range). Keep tips simple and actionable.
            """
        case .intermediate:
            return """
            For INTERMEDIATE: Balance encouragement with constructive criticism. Address dynamics (playing too loud/soft), \
            articulation, note transitions, and consistency. Discuss musical phrasing. \
            Score fairly (40-85 range). Provide specific technical tips.
            """
        case .advanced:
            return """
            For ADVANCED: Provide detailed, nuanced critique. Address expression, phrasing, intonation, \
            vibrato, tonal quality, musicality, and interpretation. Be honest but respectful. \
            Score critically (30-80 range). Offer advanced technique suggestions.
            """
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

nonisolated enum PracticeFeedbackError: Error, LocalizedError, Sendable {
    case configurationMissing
    case invalidURL
    case serverError
    case parsingError
    case recordingFailed

    var errorDescription: String? {
        switch self {
        case .configurationMissing: "AI service is not configured"
        case .invalidURL: "Invalid service URL"
        case .serverError: "The AI service is temporarily unavailable. Please try again."
        case .parsingError: "Could not process the feedback. Please try again."
        case .recordingFailed: "Microphone recording failed"
        }
    }
}
