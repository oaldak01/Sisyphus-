//
//  BlockingState.swift
//  Discipline
//
//  Model for persisting blocking state
//

import Foundation

struct CustomBlockedSite: Codable, Identifiable, Equatable {
    let id: UUID
    let domain: String
    let createdAt: Date
    
    init(id: UUID = UUID(), domain: String, createdAt: Date = Date()) {
        self.id = id
        self.domain = domain
        self.createdAt = createdAt
    }
}
