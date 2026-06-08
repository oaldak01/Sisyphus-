//
//  SplashScreenView.swift
//  DiciplineApp
//
//  Created by Omar Aldakheel on 07/06/2026.
//

import SwiftUI
import Lottie

struct  SplashScreenView: View {
    @State private var splashOpacity: Double = 1

    var body: some View {
        VStack {
            VStack {
                Color(.systemBackground)
                Text("“The struggle itself toward the heights is enough to fill a man’s heart. One must imagine Sisyphus happy.”\n\n — Albert Camus")
                    .italic()
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 40)
                    .phaseAnimator([0.0, 1.0]) { content, phase in
                        content.opacity(phase)
                    } animation: { _ in
                        .easeIn(duration: 2)
                    }
            }

            SplashScreenLayout()
                .opacity(splashOpacity)
                .allowsHitTesting(splashOpacity > 0)
                .onAppear {
                    // Your timer logic to dismiss splash (splashOpacity = 0) goes here
                }
        }
    }
}

struct SplashScreenLayout: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            LottieView(animationName: "splash", loopMode: .loop)
                .scaledToFill()
            
            
                .ignoresSafeArea()
        }
    }
}

#Preview {
    SplashScreenView()
}
