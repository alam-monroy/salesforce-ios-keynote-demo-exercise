//
//  RootView.swift
//
//  Created by Andres Marin on 13/02/26.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appLanguage: AppLanguage
    @State private var isLoaded = false

    var body: some View {
        Group {
            if isLoaded {
                if #available(iOS 26.0, *) {
                    PhoneView()
                } else {
                    UnsupportedOSView()
                }
            }
        }
        .task { await loadConfig() }
    }

    @MainActor
    private func loadConfig() async {
        let config: AppConfig? = await withCheckedContinuation { continuation in
            NetworkService.shared.fetchChatConfig { result in
                switch result {
                case .success(let c): continuation.resume(returning: c)
                case .failure:        continuation.resume(returning: nil)
                }
            }
        }
        appLanguage.apply(config?.language)
        isLoaded = true
    }
}
