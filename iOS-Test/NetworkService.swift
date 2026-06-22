//
//  NetworkService.swift
//
//  Created by Andres Marin on 13/02/26.
//

import Foundation

/// Errors specific to loading the demo's remote/local configuration.
enum ConfigError: Error {
    case bundleResourceMissing
    case decodingFailed(underlying: Error)
    case invalidRemoteURL
}

class NetworkService {
    static let shared = NetworkService()

    private(set) var remoteConfigURL: URL?

    private let urlDefaultsKey = "com.salesforce.demo.remoteConfigURL"

    init() {
        if let saved = UserDefaults.standard.string(forKey: urlDefaultsKey) {
            remoteConfigURL = URL(string: saved)
        }
    }

    /// Lets a future settings surface point this demo at a different
    /// event/brand's config without shipping a new build.
    func setRemoteConfigURL(_ url: URL?) {
        remoteConfigURL = url
        UserDefaults.standard.set(url?.absoluteString, forKey: urlDefaultsKey)
    }

    func fetchChatConfig(completion: @escaping (Result<AppConfig, Error>) -> Void) {
        guard let remoteURL = remoteConfigURL else {
            loadBundledConfig(completion: completion)
            return
        }
        fetchRemoteConfig(from: remoteURL) { [weak self] result in
            switch result {
            case .success(let config):
                completion(.success(config))
            case .failure:
                self?.loadBundledConfig(completion: completion)
            }
        }
    }

    // MARK: - Remote

    private func fetchRemoteConfig(
        from url: URL,
        completion: @escaping (Result<AppConfig, Error>) -> Void
    ) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data else {
                completion(.failure(ConfigError.invalidRemoteURL))
                return
            }
            do {
                let config = try JSONDecoder().decode(AppConfig.self, from: data)
                completion(.success(config))
            } catch {
                completion(.failure(ConfigError.decodingFailed(underlying: error)))
            }
        }.resume()
    }

    // MARK: - Bundled fallback

    private func loadBundledConfig(completion: @escaping (Result<AppConfig, Error>) -> Void) {
        guard let fileURL = Bundle.main.url(forResource: "Configs", withExtension: "json") else {
            completion(.failure(ConfigError.bundleResourceMissing))
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let config = try JSONDecoder().decode(AppConfig.self, from: data)
            completion(.success(config))
        } catch {
            completion(.failure(ConfigError.decodingFailed(underlying: error)))
        }
    }
}
