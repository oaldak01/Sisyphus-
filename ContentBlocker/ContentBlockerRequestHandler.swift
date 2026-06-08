//
//  ContentBlockerRequestHandler.swift
//  ContentBlocker
//
//  Safari Content Blocker Extension for Discipline App
//

import Foundation
import SafariServices

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    
    func beginRequest(with context: NSExtensionContext) {
        // Check if blocking is currently active
        let isBlocking = checkIfBlockingActive()
        
        if isBlocking {
            // Load blocking rules
            loadBlockingRules { rules in
                let response = NSExtensionItem()
                response.attachments = [NSItemProvider(item: rules as NSSecureCoding, typeIdentifier: kUTTypeJSON as String)]
                context.completeRequest(returningItems: [response], completionHandler: nil)
            }
        } else {
            // Return empty rules (no blocking)
            let emptyRules = "[]"
            let response = NSExtensionItem()
            response.attachments = [NSItemProvider(item: emptyRules as NSSecureCoding, typeIdentifier: kUTTypeJSON as String)]
            context.completeRequest(returningItems: [response], completionHandler: nil)
        }
    }
    
    private func checkIfBlockingActive() -> Bool {
        // Check shared UserDefaults to see if blocking is active
        let userDefaults = UserDefaults(suiteName: "group.admin.DiciplineApp")
        
        guard let data = userDefaults?.data(forKey: "DisciplineBlockingState") else {
            return false
        }
        
        do {
            let decoder = JSONDecoder()
            let state = try decoder.decode(BlockingState.self, from: data)
            
            // Check if blocking is active and hasn't expired
            if state.isActive, let endDate = state.endDate {
                return Date() < endDate
            }
        } catch {
            print("Failed to decode blocking state in extension: \(error)")
        }
        
        return false
    }
    
    private func loadBlockingRules(completion: @escaping (String) -> Void) {
        // Load the blocking rules from the bundle
        guard let rulesURL = Bundle.main.url(forResource: "blockerList", withExtension: "json"),
              let rulesData = try? Data(contentsOf: rulesURL),
              let rulesString = String(data: rulesData, encoding: .utf8) else {
            completion("[]")
            return
        }
        
        completion(rulesString)
    }
}

// MARK: - BlockingState Model (Shared)

struct BlockingState: Codable {
    let isActive: Bool
    let startDate: Date?
    let endDate: Date?
    let duration: BlockingDuration?
    let installationId: UUID
}

enum BlockingDuration: Int, Codable {
    case oneDay = 1
    case threeDays = 3
    case sevenDays = 7
}
