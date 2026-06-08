import SwiftUI
import Lottie

struct OnboardingSlide: Identifiable {
    let id = UUID()
    let animationName: String
    let title: String
    let description: String
    let buttonText: String
}

struct OnboardingPageView: View {
    var onCompletion: (() -> Void)? = nil
    
    @State private var activeIndex: Int? = 0
    
    private let slides = [
        OnboardingSlide(
            animationName: "splash",
            title: "Welcome to Sisyphus",
            description: "Reclaim your focus and conquer digital distractions",
            buttonText: "Next"
        ),
        OnboardingSlide(
            animationName: "Artboard 1",
            title: "Block Distractions",
            description: "Secure and block distracting websites with password protection. Keep your focus uninterrupted.",
            buttonText: "Next"
        ),
        OnboardingSlide(
            animationName: "3",
            title: "Build Discipline Daily",
            description: "Freedom isn't removing temptation. It's choosing what matters most, one day at a time.",
            buttonText: "Get Started"
        )
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(#colorLiteral(red: 0.08235294118, green: 0.0862745098, blue: 0.1411764706, alpha: 1)),
                    Color(#colorLiteral(red: 0.1490196078, green: 0.1568627451, blue: 0.2784313725, alpha: 1))
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                            OnboardingPageViewItem(slide: slide)
                                .containerRelativeFrame(.horizontal)
                                .scrollTransition(topLeading: .interactive, bottomTrailing: .interactive) { view, phase in
                                    view
                                        .opacity(phase.isIdentity ? 1 : 0)
                                        .scaleEffect(phase.isIdentity ? 1 : 0.75)
                                        .blur(radius: phase.isIdentity ? 0 : 8)
                                        .offset(y: phase.isIdentity ? 0 : 60)
                                        .rotationEffect(.degrees(phase.value * -12))
                                }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $activeIndex)
                
                VStack(spacing: 24) {
                    HStack(spacing: 8) {
                        ForEach(0..<slides.count, id: \.self) { index in
                            Capsule()
                                .fill(activeIndex == index ? Color.white : Color.white.opacity(0.3))
                                .frame(width: activeIndex == index ? 24 : 8, height: 8)
                                .scaleEffect(activeIndex == index ? 1.15 : 1.0)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: activeIndex)
                    Button {
                        if let current = activeIndex, current < slides.count - 1 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                activeIndex = current + 1
                            }
                        } else {
                            onCompletion?()
                        }
                    } label: {
                        Text(slides[activeIndex ?? 0].buttonText)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(#colorLiteral(red: 0.08235294118, green: 0.0862745098, blue: 0.1411764706, alpha: 1)))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.white.opacity(0.15), radius: 10, x: 0, y: 5)
                            .padding(.horizontal, 24)
                    }
                    .animation(.easeInOut(duration: 0.25), value: activeIndex)
                    
                    if let current = activeIndex, current < slides.count - 1 {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                activeIndex = slides.count - 1
                            }
                        } label: {
                            Text("Skip")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .transition(.opacity.combined(with: .scale))
                    } else {
                        Text("")
                            .font(.system(size: 15, weight: .medium))
                            .frame(height: 18)
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
}

struct OnboardingPageViewItem: View {
    let slide: OnboardingSlide
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                RoundedRectangle(cornerRadius: 64)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 64)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                
                LottieView(animationName: slide.animationName)
                    .scaledToFill()
                    .padding(10)
                    .cornerRadius(120)
                    
            }
            .frame(height: 320)
            .padding(.all, 24)
            
            VStack(spacing: 12) {
                Text(slide.title)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                
                Text(slide.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingPageView()
}
