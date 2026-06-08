//
//  DisciplineApp.swift
//  Discipline
//
//  Main app entry point
//

import SwiftUI

@main
struct DiciplineApp: App {
    @StateObject private var blockingManager = BlockingManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    ContentView()
                        .transition(.opacity)
                } else {
                    OnboardingPageView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            hasCompletedOnboarding = true
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .environmentObject(blockingManager)
        }
    }
}

