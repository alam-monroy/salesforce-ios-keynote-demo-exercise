//
//  VoicemailViewModel.swift
//
//  Created by Alam Monroy.
//

import Foundation

@MainActor
final class VoicemailViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case noRecentCall
        case loading
        case success(transcript: String, summary: String)
        case failure(message: String)
    }

    @Published private(set) var state: State = .idle

    func prepare() {
        if case .success = state { return }
        state = LastCallContext.load() != nil ? .idle : .noRecentCall
    }

    func generateSummary() {
        guard let context = LastCallContext.load() else {
            state = .noRecentCall
            return
        }

        state = .loading
        Task {
            let result = await ClaudeService.shared.generateSummary(
                contactName: context.contactName,
                durationSeconds: context.durationSeconds
            )
            switch result {
            case .success(let callSummary):
                state = .success(transcript: callSummary.transcript, summary: callSummary.summary)
            case .failure(let error):
                state = .failure(message: Self.userFacingMessage(for: error))
            }
        }
    }

    /// Maps internal errors to a short, demo-safe message. Never shows
    /// raw error descriptions on screen
    private static func userFacingMessage(for error: Error) -> String {
        if let claudeError = error as? ClaudeService.ClaudeError {
            switch claudeError {
            case .missingAPIKey:
                return "Summary generation isn't configured on this device."
            case .invalidResponse, .requestFailed:
                return "Couldn't generate a summary right now."
            }
        }
        return "Couldn't generate a summary right now."
    }
}
