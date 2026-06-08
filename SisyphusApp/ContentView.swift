//
//  ContentView.swift
//  Discipline
//
//  Main user interface for persistent website blocking
//

import SwiftUI
import FamilyControls
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var showSplash: Bool = true
    @EnvironmentObject var blockingManager: BlockingManager
    
    @State private var linkText = ""
    @State private var unlockPassword = ""
    @State private var confirmUnlockPassword = ""
    @State private var sitePendingRemoval: CustomBlockedSite?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @State private var showingChangePassword = false
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var isBlockedListExpanded = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
            } else {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)), Color(#colorLiteral(red: 0.4119305611, green: 0.4156535268, blue: 0.5603827834, alpha: 1))]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        LottieView(animationName: "Artboard 1", loopMode: .autoReverse, contentMode: .scaleAspectFill)
                            .frame(height: 400)
                            .frame(width: .infinity)
                            .ignoresSafeArea()
                    }
                    .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(alignment: .center, spacing: 30) {
                            blockForm
                            blockedSites
                            Button {
                                showingChangePassword = true
                            } label: {
                                HStack {
                                    Image(systemName: "key.fill")
                                    Text("Change Password")
                                }
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .cornerRadius(12)
                            }
                        }
                        .padding(24)
                    }
                }
                .alert("Error", isPresented: $showingError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(errorMessage)
                }
                .sheet(item: $sitePendingRemoval) { site in
                    RemoveCustomSiteView(site: site) { password in
                        removeBlockedSite(site, password: password)
                    }
                }
                .sheet(isPresented: $showingChangePassword) {
                    ChangePasswordView(
                        isPresented: $showingChangePassword,
                        oldPassword: $oldPassword,
                        newPassword: $newPassword,
                        confirmNewPassword: $confirmNewPassword,
                        errorMessage: $errorMessage,
                        showingError: $showingError
                    )
                    .environmentObject(blockingManager)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
    
    private var blockForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add Link To Block")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            
            TextField("https://example.com", text: $linkText)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .padding(16)
                .glassEffect()

            
            if !blockingManager.hasUnlockPassword {
                SecureField("Create unlock password", text: $unlockPassword)
                    .textContentType(.newPassword)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(24)
                    .glassEffect()

                
                SecureField("Confirm unlock password", text: $confirmUnlockPassword)
                    .textContentType(.newPassword)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(24)
                    .glassEffect()

            }
            
            Button {
                Task {
                    await blockLink()
                }
            } label: {
                HStack {
                    Image(systemName: "lock.fill")
                    Text("Block Website")
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.red.opacity(0.99))
                .cornerRadius(16)

            }
            .disabled(linkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(linkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        }
    }

    
    private var blockedSites: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isBlockedListExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("Blocked")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .rotationEffect(.degrees(isBlockedListExpanded ? 90 : 0))
                    
                    Spacer()
                    
                    Text("\(blockingManager.customBlockedSites.count)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .clipShape(Capsule())
                        .glassEffect()
                }
            }
            .buttonStyle(.plain)
            
            if isBlockedListExpanded {
                if blockingManager.customBlockedSites.isEmpty {
                    Text("No websites blocked yet.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .cornerRadius(16)
                        .padding(16)
                        .glassEffect()
                } else {
                    ForEach(blockingManager.customBlockedSites) { site in
                        HStack(spacing: 12) {
                            Image(systemName: "globe.badge.chevron.backward")
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(site.domain)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            
                            Spacer()
                            
                            Button {
                                sitePendingRemoval = site
                            } label: {
                                Image(systemName: "lock.open.fill")
                                    .foregroundColor(.white)
                                    .frame(width: 38, height: 38)
                                    .background(Color.white.opacity(0.16))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private func blockLink() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            _ = try blockingManager.addCustomBlockedSite(
                from: linkText,
                password: unlockPassword,
                confirmPassword: confirmUnlockPassword
            )
            
            await MainActor.run {
                linkText = ""
                unlockPassword = ""
                confirmUnlockPassword = ""
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func removeBlockedSite(_ site: CustomBlockedSite, password: String) {
        do {
            try blockingManager.removeCustomBlockedSite(site, password: password)
            sitePendingRemoval = nil
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

struct RemoveCustomSiteView: View {
    let site: CustomBlockedSite
    let onRemove: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    
    var body: some View {
            VStack(alignment: .leading, spacing: 18) {
                Text("Unlock Website")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(site.domain)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                
                SecureField("Unlock password", text: $password)
                    .textContentType(.password)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(14)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(12)
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.14))
                    .cornerRadius(12)
                    
                    Button("Unlock") {
                        onRemove(password)
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.red.opacity(0.75))
                    .cornerRadius(12)
                    .disabled(password.isEmpty)
                    .opacity(password.isEmpty ? 0.5 : 1)
                }
            }
            .padding(24)
        }
    }


struct ChangePasswordView: View {
    @EnvironmentObject var blockingManager: BlockingManager
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    @Binding var oldPassword: String
    @Binding var newPassword: String
    @Binding var confirmNewPassword: String
    @Binding var errorMessage: String
    @Binding var showingError: Bool

    var body: some View {
        VStack(spacing: 10) {
            SecureField("Current password", text: $oldPassword)
                .textContentType(.password)
                .font(.system(size: 16, weight: .medium))
                .padding(24)
                .cornerRadius(16)

            SecureField("New password", text: $newPassword)
                .textContentType(.newPassword)
                .font(.system(size: 16, weight: .medium))
                .padding(24)
                .cornerRadius(16)

            SecureField("Confirm new password", text: $confirmNewPassword)
                .textContentType(.newPassword)
                .font(.system(size: 16, weight: .medium))
                .padding(24)
                .cornerRadius(16)

            Button("Change Password") {
                do {
                    try blockingManager.changePassword(
                        previous: oldPassword,
                        newPassword: newPassword,
                        confirmation: confirmNewPassword
                    )
                    oldPassword = ""
                    newPassword = ""
                    confirmNewPassword = ""
                    isPresented = false
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
            .font(.system(size: 17, weight: .bold))
            .cornerRadius(16)
            .padding(16)
            .glassEffect()
            .disabled(oldPassword.isEmpty || newPassword.isEmpty || confirmNewPassword.isEmpty)
            .opacity((oldPassword.isEmpty || newPassword.isEmpty || confirmNewPassword.isEmpty) ? 0.5 : 1)

            Button("Cancel") {
                isPresented = false
            }
            .font(.system(size: 17, weight: .bold))
            .padding(30)

        }
        .padding(30)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(BlockingManager.shared)
    }
}

