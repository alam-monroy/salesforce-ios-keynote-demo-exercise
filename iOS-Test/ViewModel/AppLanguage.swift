//
//  AppLanguage.swift
//
//  Created by Andres Marin on 13/02/26.
//

import SwiftUI

// MARK: - Environment key

struct LocalizationBundleKey: EnvironmentKey {
    static let defaultValue: Bundle = .main
}

extension EnvironmentValues {
    var localizationBundle: Bundle {
        get { self[LocalizationBundleKey.self] }
        set { self[LocalizationBundleKey.self] = newValue }
    }
}

// MARK: - AppLanguage

/// Holds the locale and bundle driven by the JSON config.
/// Inject via `.environmentObject(appLanguage)` in NativeApp.
final class AppLanguage: ObservableObject {
    @Published var locale: Locale = Locale(identifier: "en")
    @Published var bundle: Bundle = .main

    /// Apply a BCP-47 language code from the JSON (e.g. "en", "fr").
    func apply(_ languageCode: String?) {
        guard let code = languageCode, !code.isEmpty else {
            locale = .current
            bundle = .main
            return
        }
        locale = Locale(identifier: code)
        bundle = Bundle.main.path(forResource: code, ofType: "lproj")
            .flatMap { Bundle(path: $0) } ?? .main
    }
}
