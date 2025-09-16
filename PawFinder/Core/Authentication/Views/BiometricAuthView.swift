import SwiftUI

struct BiometricAuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingMainAuth = false
    @State private var isAuthenticating = false
    @State private var hasAttemptedAutoAuth = false
    @State private var retryCount = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.3, blue: 0.8),
                    Color(red: 0.6, green: 0.4, blue: 0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Logo
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 16) {
                    Text("Welcome Back!")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if authViewModel.isBiometricEnabled {
                        Text("Use \(authViewModel.biometricTypeName) to sign in securely")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    } else {
                        Text("Quick and secure access to PawFinder")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                
                // Authentication Options
                VStack(spacing: 24) {
                    // Main Biometric Button
                    if authViewModel.isBiometricEnabled && authViewModel.biometricType != .none {
                        Button(action: {
                            authenticateWithBiometrics()
                        }) {
                            VStack(spacing: 12) {
                                if isAuthenticating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.5)
                                } else {
                                    Image(systemName: authViewModel.biometricIcon)
                                        .font(.system(size: 60))
                                        .foregroundColor(.white)
                                }
                                
                                Text(isAuthenticating ? "Authenticating..." : "Sign in with \(authViewModel.biometricTypeName)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 220, height: 140)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .disabled(isAuthenticating)
                        .scaleEffect(isAuthenticating ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isAuthenticating)
                    } else {
                        // No biometric enabled - show setup info
                        VStack(spacing: 20) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("No biometric authentication set up")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Please sign in with email to set up biometric authentication")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    
                    // Alternative Options
                    VStack(spacing: 16) {
                        // Email/Password option
                        Button(action: {
                            showingMainAuth = true
                        }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 16))
                                Text("Sign in with Email")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Retry button - only show after failed attempt
                        if !isAuthenticating && authViewModel.errorMessage != nil && authViewModel.isBiometricEnabled {
                            Button(action: {
                                authenticateWithBiometrics()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 14))
                                    Text("Try \(authViewModel.biometricTypeName) Again")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                
                // Error message with better styling
                if let error = authViewModel.errorMessage {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.red.opacity(0.8))
                            
                            Text(error)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        
                        if error.contains("credentials") {
                            Button("Reset biometric authentication") {
                                resetBiometricAuth()
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 40)
                    .onAppear {
                        // Auto-clear error after 8 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                            if authViewModel.errorMessage == error {
                                authViewModel.errorMessage = nil
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showingMainAuth) {
            WelcomeAuthContainerView()
        }
        .onAppear {
            setupAutoAuth()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Reset retry count when app becomes active
            retryCount = 0
        }
    }
    
    // MARK: - Methods
    private func setupAutoAuth() {
        // Only auto-trigger if conditions are met
        guard authViewModel.isBiometricEnabled,
              authViewModel.biometricType != .none,
              !isAuthenticating,
              !hasAttemptedAutoAuth,
              retryCount < 3 else { return }
        
        hasAttemptedAutoAuth = true
        
        // Small delay to ensure UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            authenticateWithBiometrics()
        }
    }
    
    private func authenticateWithBiometrics() {
        guard !isAuthenticating,
              authViewModel.isBiometricEnabled,
              retryCount < 5 else { return }
        
        isAuthenticating = true
        authViewModel.errorMessage = nil
        retryCount += 1
        
        Task {
            let success = await authViewModel.signInWithBiometrics()
            
            await MainActor.run {
                self.isAuthenticating = false
                
                if success {
                    print("✅ Biometric authentication successful")
                    // Reset retry count on success
                    self.retryCount = 0
                } else {
                    print("❌ Biometric authentication failed (attempt \(self.retryCount))")
                    
                    // If too many failures, suggest email login
                    if self.retryCount >= 3 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            if self.authViewModel.errorMessage != nil {
                                self.authViewModel.errorMessage = "Too many attempts. Please use email and password to sign in."
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func resetBiometricAuth() {
        authViewModel.disableBiometricAuthentication()
        authViewModel.errorMessage = nil
        
        // Show confirmation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showingMainAuth = true
        }
    }
}

#Preview {
    BiometricAuthView()
        .environmentObject(AuthViewModel())
}
