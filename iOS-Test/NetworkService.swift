//
//  NetworkService.swift
//
//  Created by Andres Marin on 13/02/26.
//

import Foundation

class NetworkService {
    static let shared = NetworkService()

    func fetchChatConfig(completion: @escaping (Result<AppConfig, Error>) -> Void) {
        guard let fileURL = Bundle.main.url(forResource: "Configs", withExtension: "json") else {
            completion(.failure(NSError(
                domain: "NetworkService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Configs.json was not found in the app bundle."]
            )))
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let config = try JSONDecoder().decode(AppConfig.self, from: data)
            completion(.success(config))
        } catch {
            completion(.failure(error))
        }
    }
}
