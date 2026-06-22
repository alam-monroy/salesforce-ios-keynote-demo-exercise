//
//  Models.swift
//
//  Created by Andres Marin on 13/02/26.
//

import Foundation

struct AppConfig: Codable {
    let configName: String
    let language: String?
    let contacts: [ContactConfig]?
}

struct ContactConfig: Codable, Identifiable {
    let id: Int
    let name: String
    let avatar: String?
    let imageURL: String?
    let description: String?
    let websiteURL: String?
}
