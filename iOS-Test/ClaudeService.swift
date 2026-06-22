//
//  ClaudeService.swift
//
//  Created by Alam Monroy.
//

import Foundation

/// Generates a plausible call transcript + summary using the Anthropic
/// API, given only the contact name and call duration (this demo has no
/// real audio/transcript — the call itself is a simulated ringtone and
/// timer, not a real connection).
class ClaudeService {
    static let shared = ClaudeService()

    enum ClaudeError: Error {
        case missingAPIKey
        case invalidResponse
        case requestFailed(underlying: Error)
    }

    struct CallSummary {
        let transcript: String
        let summary: String
    }

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-sonnet-4-6"

    func generateSummary(contactName: String, durationSeconds: Int) async -> Result<CallSummary, Error> {
        guard let apiKey = Self.loadAPIKey() else {
            return .failure(ClaudeError.missingAPIKey)
        }

        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        let durationLabel = String(format: "%d:%02d", minutes, seconds)

        let prompt = """
        Generate a short, plausible phone call transcript and summary for \
        a demo app. The call was with "\(contactName)" and lasted \
        \(durationLabel). This is for a stage demo, not a real call — \
        invent a brief, business-appropriate exchange (e.g. a customer \
        support or partnership check-in call).

        Respond with ONLY valid JSON, no markdown formatting, in this \
        exact shape:
        {"transcript": "...", "summary": "..."}

        The transcript should be 3-5 short lines of dialogue. The summary \
        should be 1-2 sentences capturing the call's purpose and outcome.
        """

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 500,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return parseSummary(from: data)
        } catch {
            return .failure(ClaudeError.requestFailed(underlying: error))
        }
    }

    private func parseSummary(from data: Data) -> Result<CallSummary, Error> {
        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = root["content"] as? [[String: Any]],
            let text = content.first?["text"] as? String
        else {
            return .failure(ClaudeError.invalidResponse)
        }

        guard
            let jsonData = text.data(using: .utf8),
            let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
            let transcript = parsed["transcript"] as? String,
            let summary = parsed["summary"] as? String
        else {
            return .failure(ClaudeError.invalidResponse)
        }

        return .success(CallSummary(transcript: transcript, summary: summary))
    }

    /// Loads the API key from Secrets.plist, which is gitignored and
    /// never committed. See PROJECT_NOTES.md for setup steps.
    private static func loadAPIKey() -> String? {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let key = plist["ANTHROPIC_API_KEY"] as? String,
            !key.isEmpty
        else {
            return nil
        }
        return key
    }
}
