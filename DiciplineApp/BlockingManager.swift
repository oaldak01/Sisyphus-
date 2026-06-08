//
//  BlockingManager.swift
//  Discipline
//
//  Manages persistent website blocking
//

import Foundation
import CryptoKit
import ManagedSettings

@MainActor
class BlockingManager: ObservableObject {
    static let shared = BlockingManager()
    
    @Published private(set) var customBlockedSites: [CustomBlockedSite] = []
    @Published private(set) var hasUnlockPassword: Bool = false
    
    private let managedSettingsStore = ManagedSettingsStore()
    private let customSiteManager = CustomBlockedSiteManager()
    
    private init() {
        loadCustomBlockedSites()
    }
    
    @discardableResult
    func addCustomBlockedSite(from input: String, password: String, confirmPassword: String) throws -> CustomBlockedSite {
        let domain = try Self.normalizedDomain(from: input)
        
        if !hasUnlockPassword {
            try customSiteManager.savePassword(password, confirmation: confirmPassword)
            hasUnlockPassword = true
        }
        
        if let existingSite = customBlockedSites.first(where: { $0.domain == domain }) {
            return existingSite
        }
        
        let site = CustomBlockedSite(domain: domain)
        customBlockedSites.append(site)
        customBlockedSites.sort { $0.domain < $1.domain }
        try customSiteManager.saveSites(customBlockedSites)
        applyScreenTimeRestrictions()
        return site
    }
    
    func removeCustomBlockedSite(_ site: CustomBlockedSite, password: String) throws {
        guard customSiteManager.passwordMatches(password) else {
            throw BlockingManagerError.incorrectPassword
        }
        
        customBlockedSites.removeAll { $0.id == site.id }
        try customSiteManager.saveSites(customBlockedSites)
        applyScreenTimeRestrictions()
    }
    
    func changePassword(previous: String, newPassword: String, confirmation: String) throws {
        try customSiteManager.changePassword(previous: previous, newPassword: newPassword, confirmation: confirmation)
        hasUnlockPassword = true
    }
    
    private func loadCustomBlockedSites() {
        customBlockedSites = customSiteManager.loadSites()
        hasUnlockPassword = customSiteManager.hasPassword
        applyScreenTimeRestrictions()
    }
    
    private func applyScreenTimeRestrictions() {
        let domains = Set(customBlockedSites.map { WebDomain(domain: $0.domain) })
        
        if domains.isEmpty {
            managedSettingsStore.clearAllSettings()
        } else {
            managedSettingsStore.webContent.blockedByFilter = .specific(domains)
        }
    }
    
    private static func normalizedDomain(from input: String) throws -> String {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !value.isEmpty else {
            throw BlockingManagerError.emptyLink
        }
        
        if !value.contains("://") {
            value = "https://\(value)"
        }
        
        guard let components = URLComponents(string: value),
              var host = components.host?.trimmingCharacters(in: .whitespacesAndNewlines),
              !host.isEmpty else {
            throw BlockingManagerError.invalidLink
        }
        
        if host.hasPrefix("www.") {
            host.removeFirst(4)
        }
        
        while host.hasSuffix(".") {
            host.removeLast()
        }
        
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789.-")
        guard host.rangeOfCharacter(from: allowedCharacters.inverted) == nil,
              host.contains("."),
              !host.contains("..") else {
            throw BlockingManagerError.invalidLink
        }
        
        return host
    }
}

enum BlockingManagerError: LocalizedError {
    case emptyLink
    case invalidLink
    case passwordRequired
    case passwordMismatch
    case incorrectPassword
    
    var errorDescription: String? {
        switch self {
        case .emptyLink:
            return "Paste a website link first."
        case .invalidLink:
            return "That does not look like a valid website link."
        case .passwordRequired:
            return "Create an unlock password with at least 4 characters."
        case .passwordMismatch:
            return "The password confirmation does not match."
        case .incorrectPassword:
            return "Incorrect password."
        }
    }
}

class CustomBlockedSiteManager {
    private let userDefaults = UserDefaults(suiteName: "group.admin.DiciplineApp") ?? UserDefaults.standard
    private let sitesKey = "DisciplineCustomBlockedSites"
    private let passwordSaltKey = "DisciplineCustomBlockPasswordSalt"
    private let passwordHashKey = "DisciplineCustomBlockPasswordHash"
    
    var hasPassword: Bool {
        userDefaults.string(forKey: passwordSaltKey) != nil &&
        userDefaults.string(forKey: passwordHashKey) != nil
    }
    
    func loadSites() -> [CustomBlockedSite] {
        guard let data = userDefaults.data(forKey: sitesKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([CustomBlockedSite].self, from: data)
        } catch {
            print("Failed to decode custom blocked sites: \(error)")
            return []
        }
    }
    
    func saveSites(_ sites: [CustomBlockedSite]) throws {
        let data = try JSONEncoder().encode(sites)
        userDefaults.set(data, forKey: sitesKey)
        userDefaults.synchronize()
    }
    
    func savePassword(_ password: String, confirmation: String) throws {
        guard password.count >= 4 else {
            throw BlockingManagerError.passwordRequired
        }
        
        guard password == confirmation else {
            throw BlockingManagerError.passwordMismatch
        }
        
        let salt = UUID().uuidString
        userDefaults.set(salt, forKey: passwordSaltKey)
        userDefaults.set(Self.hash(password: password, salt: salt), forKey: passwordHashKey)
        userDefaults.synchronize()
    }
    
    func passwordMatches(_ password: String) -> Bool {
        guard let salt = userDefaults.string(forKey: passwordSaltKey),
              let savedHash = userDefaults.string(forKey: passwordHashKey) else {
            return false
        }
        
        return Self.hash(password: password, salt: salt) == savedHash
    }
    
    func changePassword(previous: String, newPassword: String, confirmation: String) throws {
        guard passwordMatches(previous) else {
            throw BlockingManagerError.incorrectPassword
        }
        guard newPassword.count >= 4 else {
            throw BlockingManagerError.passwordRequired
        }
        guard newPassword == confirmation else {
            throw BlockingManagerError.passwordMismatch
        }
        let salt = UUID().uuidString
        userDefaults.set(salt, forKey: passwordSaltKey)
        userDefaults.set(Self.hash(password: newPassword, salt: salt), forKey: passwordHashKey)
        userDefaults.synchronize()
    }
    
    private static func hash(password: String, salt: String) -> String {
        let data = Data("\(salt):\(password)".utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}



