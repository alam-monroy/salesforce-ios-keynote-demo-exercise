//
//  LastCallContext.swift
//
//  Created by Alam Monroy.
//

import Foundation

/// Persists the contact name and duration of the most recently ended
/// call, so VoicemailView can generate a summary for it later.
struct LastCallContext: Codable {
    let contactName: String
    let durationSeconds: Int

    private static let defaultsKey = "com.salesforce.demo.lastCallContext"

    static func save(contactName: String, durationSeconds: Int) {
        let context = LastCallContext(contactName: contactName, durationSeconds: durationSeconds)
        guard let data = try? JSONEncoder().encode(context) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    static func load() -> LastCallContext? {
        guard
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let context = try? JSONDecoder().decode(LastCallContext.self, from: data)
        else {
            return nil
        }
        return context
    }
}
