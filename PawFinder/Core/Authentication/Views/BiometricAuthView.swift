import SwiftUI
import LocalAuthentication

struct BiometricAuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingMainAuth = false
    @State private var isAuthenticating = false
    @State private var showingBiometricSetup = false
    @State private var hasAttemptedAutoAuth = false
    
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
                    // Biometric Authentication (if enabled and available)
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
                        
                        // Alternative authentication methods
                        VStack(spacing: 16) {
                            if authViewModel.biometricType != .none {
                                Button(action: {
                                    authenticateWithPasscode()
                                }) {
                                    HStack {
                                        Image(systemName: "key.fill")
                                            .font(.system(size: 16))
                                        Text("Use Device Passcode")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.white.opacity(0.2))
                                    )
                                }
                            }
                        }
                    } else if authViewModel.biometricType != .none && !authViewModel.isBiometricEnabled {
                        // Show setup biometric option
                        VStack(spacing: 20) {
                            Image(systemName: authViewModel.biometricIcon)
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("\(authViewModel.biometricTypeName) Available")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Enable \(authViewModel.biometricTypeName) for quick and secure access")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                showingBiometricSetup = true
                            }) {
                                Text("Set up \(authViewModel.biometricTypeName)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .cornerRadius(25)
                            }
                            .padding(.horizontal, 40)
                        }
                    }
                    
                    // Always show option to sign in with email/password
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
                    
                    // 🔥 NEW: Quick retry button if authentication fails
                    if !isAuthenticating && authViewModel.isBiometricEnabled && authViewModel.biometricType != .none {
                        Button(action: {
                            authenticateWithBiometrics()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14))
                                Text("Try Again")
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
                
                // Error message
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                authViewModel.errorMessage = nil
                            }
                        }
                }
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showingMainAuth) {
            WelcomeAuthContainerView()
        }
        .alert("Enable \(authViewModel.biometricTypeName)?", isPresented: $showingBiometricSetup) {
            Button("Enable") {
                if let email = UserDefaults.standard.string(forKey: "stored_email_for_biometric") {
                    authViewModel.enableBiometricAuthentication(email: email)
                } else {
                    showingMainAuth = true
                }
            }
            Button("Not Now", role: .cancel) {
                authViewModel.markBiometricPromptShown()
            }
        } message: {
            Text("Use \(authViewModel.biometricTypeName) for quick and secure access to PawFinder.")
        }
        .onAppear {
            // Auto-trigger biometric authentication if enabled and haven't tried yet
            if authViewModel.isBiometricEnabled &&
               authViewModel.biometricType != .none &&
               !isAuthenticating &&
               !hasAttemptedAutoAuth {
                
                hasAttemptedAutoAuth = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    authenticateWithBiometrics()
                }
            }
        }
    }
    
    private func authenticateWithBiometrics() {
        isAuthenticating = true
        
        Task {
            let success = await authViewModel.signInWithBiometrics()
            
            DispatchQueue.main.async {
                self.isAuthenticating = false
                if success {
                    authViewModel.setBiometricAuthenticated(true)
                }
            }
        }
    }
    
    private func authenticateWithPasscode() {
        isAuthenticating = true
        
        Task {
            let success = await authViewModel.authenticateWithBiometrics(reason: "Use device passcode to sign in to PawFinder")
            
            DispatchQueue.main.async {
                self.isAuthenticating = false
                if success {
                    authViewModel.setBiometricAuthenticated(true)
                }
            }
        }
    }
}

#Preview {
    BiometricAuthView()
        .environmentObject(AuthViewModel())
}
