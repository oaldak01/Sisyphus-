//
//  ShareViewController.swift
//  DiciplineShareExtension
//
//  Blocks the current Safari URL from the share sheet.
//

import UIKit
import CryptoKit
import ManagedSettings
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let store = SharedBlockStore()
    
    private var sharedURL: URL?
    private var sharedDomain: String?
    
    private let titleLabel = UILabel()
    private let domainLabel = UILabel()
    private let statusLabel = UILabel()
    private let passwordField = UITextField()
    private let confirmPasswordField = UITextField()
    private let blockButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        loadSharedURL()
    }
    
    private func configureView() {
        view.backgroundColor = .black
        
        titleLabel.text = "Block Website"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        
        domainLabel.text = "Reading Safari URL..."
        domainLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        domainLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        domainLabel.numberOfLines = 2
        
        statusLabel.textColor = UIColor.white.withAlphaComponent(0.65)
        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.numberOfLines = 0
        
        configurePasswordField(passwordField, placeholder: "Create unlock password")
        configurePasswordField(confirmPasswordField, placeholder: "Confirm unlock password")
        passwordField.isHidden = store.hasPassword
        confirmPasswordField.isHidden = store.hasPassword
        
        blockButton.setTitle("Block Current Website", for: .normal)
        blockButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        blockButton.setTitleColor(.white, for: .normal)
        blockButton.backgroundColor = UIColor(red: 0.78, green: 0.14, blue: 0.16, alpha: 1)
        blockButton.layer.cornerRadius = 12
        blockButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        blockButton.addTarget(self, action: #selector(blockCurrentWebsite), for: .touchUpInside)
        blockButton.isEnabled = false
        blockButton.alpha = 0.5
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        cancelButton.layer.cornerRadius = 12
        cancelButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            domainLabel,
            passwordField,
            confirmPasswordField,
            blockButton,
            cancelButton,
            statusLabel
        ])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func configurePasswordField(_ field: UITextField, placeholder: String) {
        field.placeholder = placeholder
        field.textColor = .white
        field.isSecureTextEntry = true
        field.textContentType = .newPassword
        field.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        field.layer.cornerRadius = 12
        field.font = .systemFont(ofSize: 16, weight: .medium)
        field.heightAnchor.constraint(equalToConstant: 48).isActive = true
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 48))
        field.leftViewMode = .always
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.45)]
        )
    }
    
    private func loadSharedURL() {
        let providers = extensionContext?.inputItems
            .compactMap { $0 as? NSExtensionItem }
            .flatMap { $0.attachments ?? [] } ?? []
        
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) else {
            domainLabel.text = "No website URL found."
            statusLabel.text = "Open this from Safari's share sheet on a website."
            return
        }
        
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, error in
            DispatchQueue.main.async {
                guard let self else { return }
                
                if let error {
                    self.domainLabel.text = "Could not read URL."
                    self.statusLabel.text = error.localizedDescription
                    return
                }
                
                let url = item as? URL
                self.sharedURL = url
                
                do {
                    let domain = try SharedBlockStore.normalizedDomain(from: url?.absoluteString ?? "")
                    self.sharedDomain = domain
                    self.domainLabel.text = domain
                    self.statusLabel.text = self.store.hasPassword ? "This site will stay blocked until unlocked in Discipline." : "Create the unlock password first. Future Safari blocks will only need one tap."
                    self.blockButton.isEnabled = true
                    self.blockButton.alpha = 1
                } catch {
                    self.domainLabel.text = "Invalid website URL."
                    self.statusLabel.text = error.localizedDescription
                }
            }
        }
    }
    
    @objc private func blockCurrentWebsite() {
        guard let domain = sharedDomain else {
            statusLabel.text = "No website URL found."
            return
        }
        
        do {
            if !store.hasPassword {
                try store.savePassword(
                    passwordField.text ?? "",
                    confirmation: confirmPasswordField.text ?? ""
                )
            }
            
            try store.add(domain: domain)
            statusLabel.text = "\(domain) is blocked."
            blockButton.setTitle("Blocked", for: .normal)
            blockButton.isEnabled = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.extensionContext?.completeRequest(returningItems: nil)
            }
        } catch {
            statusLabel.text = error.localizedDescription
        }
    }
    
    @objc private func cancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "DiciplineShareExtension", code: 0))
    }
}

private struct SharedBlockedSite: Codable, Identifiable, Equatable {
    let id: UUID
    let domain: String
    let createdAt: Date
    
    init(id: UUID = UUID(), domain: String, createdAt: Date = Date()) {
        self.id = id
        self.domain = domain
        self.createdAt = createdAt
    }
}

private enum SharedBlockError: LocalizedError {
    case emptyLink
    case invalidLink
    case passwordRequired
    case passwordMismatch
    
    var errorDescription: String? {
        switch self {
        case .emptyLink:
            return "No website link was found."
        case .invalidLink:
            return "That does not look like a valid website link."
        case .passwordRequired:
            return "Create an unlock password with at least 4 characters."
        case .passwordMismatch:
            return "The password confirmation does not match."
        }
    }
}

private final class SharedBlockStore {
    private let userDefaults = UserDefaults(suiteName: "group.admin.DiciplineApp") ?? UserDefaults.standard
    private let managedSettingsStore = ManagedSettingsStore()
    private let sitesKey = "DisciplineCustomBlockedSites"
    private let passwordSaltKey = "DisciplineCustomBlockPasswordSalt"
    private let passwordHashKey = "DisciplineCustomBlockPasswordHash"
    
    var hasPassword: Bool {
        userDefaults.string(forKey: passwordSaltKey) != nil &&
        userDefaults.string(forKey: passwordHashKey) != nil
    }
    
    func add(domain: String) throws {
        var sites = loadSites()
        
        if !sites.contains(where: { $0.domain == domain }) {
            sites.append(SharedBlockedSite(domain: domain))
            sites.sort { $0.domain < $1.domain }
            try saveSites(sites)
        }
        
        applyFamilyControls(for: sites)
    }
    
    func savePassword(_ password: String, confirmation: String) throws {
        guard password.count >= 4 else {
            throw SharedBlockError.passwordRequired
        }
        
        guard password == confirmation else {
            throw SharedBlockError.passwordMismatch
        }
        
        let salt = UUID().uuidString
        userDefaults.set(salt, forKey: passwordSaltKey)
        userDefaults.set(Self.hash(password: password, salt: salt), forKey: passwordHashKey)
        userDefaults.synchronize()
    }
    
    private func loadSites() -> [SharedBlockedSite] {
        guard let data = userDefaults.data(forKey: sitesKey) else {
            return []
        }
        
        return (try? JSONDecoder().decode([SharedBlockedSite].self, from: data)) ?? []
    }
    
    private func saveSites(_ sites: [SharedBlockedSite]) throws {
        let data = try JSONEncoder().encode(sites)
        userDefaults.set(data, forKey: sitesKey)
        userDefaults.synchronize()
    }
    
    private func applyFamilyControls(for sites: [SharedBlockedSite]) {
        let domains = Set(sites.map { WebDomain(domain: $0.domain) })
        
        if domains.isEmpty {
            managedSettingsStore.clearAllSettings()
        } else {
            managedSettingsStore.webContent.blockedByFilter = .specific(domains)
        }
    }
    
    static func normalizedDomain(from input: String) throws -> String {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !value.isEmpty else {
            throw SharedBlockError.emptyLink
        }
        
        if !value.contains("://") {
            value = "https://\(value)"
        }
        
        guard let components = URLComponents(string: value),
              var host = components.host?.trimmingCharacters(in: .whitespacesAndNewlines),
              !host.isEmpty else {
            throw SharedBlockError.invalidLink
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
            throw SharedBlockError.invalidLink
        }
        
        return host
    }
    
    private static func hash(password: String, salt: String) -> String {
        let data = Data("\(salt):\(password)".utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}




