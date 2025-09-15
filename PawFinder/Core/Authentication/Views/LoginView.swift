import SwiftUI

struct LoginView: View {
    @Binding var showingLogin: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var isAuthenticatingBiometric = false
    @State private var showingBiometricSetupAlert = false
    
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
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 35))
                                .foregroundColor(.white)
                        }
                        
                        Text("Welcome Back")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Sign in to continue helping pets")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 20)
                    
                    // Error Message
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 24)
                    }
                    
                    // 🔥 MAIN BIOMETRIC LOGIN BUTTON - This will show if biometric is enabled
                    if authViewModel.isBiometricEnabled && authViewModel.biometricType != .none {
                        VStack(spacing: 20) {
                            // Large Biometric Button
                            Button(action: {
                                authenticateWithBiometrics()
                            }) {
                                VStack(spacing: 16) {
                                    if isAuthenticatingBiometric {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(1.5)
                                    } else {
                                        Image(systemName: authViewModel.biometricIcon)
                                            .font(.system(size: 50))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(isAuthenticatingBiometric ? "Authenticating..." : "Sign in with \(authViewModel.biometricTypeName)")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                        )
                                )
                            }
                            .disabled(isAuthenticatingBiometric || authViewModel.isLoading)
                            .padding(.horizontal, 24)
                            
                            // Divider
                            HStack {
                                VStack { Divider().background(Color.white.opacity(0.3)) }
                                Text("or continue with email")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                VStack { Divider().background(Color.white.opacity(0.3)) }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    // 🔥 SETUP PROMOTION - Show this if biometric is available but not enabled
                    else if authViewModel.biometricType != .none && !authViewModel.isBiometricEnabled {
                        VStack(spacing: 20) {
                            // Biometric Setup Promotion
                            VStack(spacing: 12) {
                                Image(systemName: authViewModel.biometricIcon)
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("Quick Access Available")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Set up \(authViewModel.biometricTypeName) for faster, secure login")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 24)
                            
                            // Divider
                            HStack {
                                VStack { Divider().background(Color.white.opacity(0.3)) }
                                Text("sign in with email to enable")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                VStack { Divider().background(Color.white.opacity(0.3)) }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    // Email/Password Form
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 20)
                                
                                TextField("Email", text: $email)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.2))
                            )
                        }
                        
                        // Password Field
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 20)
                                
                                SecureField("Password", text: $password)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.2))
                            )
                        }
                        
                        // Remember Me & Forgot Password
                        HStack {
                            // 🔥 SETUP BIOMETRIC CHECKBOX - This is key!
                            Button(action: {
                                rememberMe.toggle()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    
                                    if authViewModel.biometricType != .none && !authViewModel.isBiometricEnabled {
                                        Text("Enable \(authViewModel.biometricTypeName)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                    } else {
                                        Text("Remember me")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Button("Forgot Password?") {
                                if !email.isEmpty {
                                    authViewModel.resetPassword(email: email)
                                } else {
                                    authViewModel.errorMessage = "Please enter your email first"
                                }
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 24)
                    
                    // Email Sign In Button
                    Button(action: {
                        signInWithEmail()
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.4, green: 0.3, blue: 0.8)))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(28)
                        } else {
                            // 🔥 DYNAMIC BUTTON TEXT
                            Text(buttonText)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(28)
                        }
                    }
                    .disabled(!isFormValid || authViewModel.isLoading || isAuthenticatingBiometric)
                    .opacity(isFormValid && !authViewModel.isLoading && !isAuthenticatingBiometric ? 1.0 : 0.6)
                    .padding(.horizontal, 24)
                    
                    // Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button("Sign Up") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingLogin = false
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            loadSavedEmail()
        }
        .onChange(of: authViewModel.shouldShowBiometricPrompt) { _, shouldShow in
            if shouldShow {
                showingBiometricSetupAlert = true
            }
        }
        .alert("Set up \(authViewModel.biometricTypeName)?", isPresented: $showingBiometricSetupAlert) {
            Button("Not Now", role: .cancel) {
                authViewModel.markBiometricPromptShown()
            }
            Button("Set Up") {
                rememberMe = true
            }
        } message: {
            Text("Enable \(authViewModel.biometricTypeName) for quick and secure access to PawFinder. You can always change this later in Settings.")
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private var buttonText: String {
        if authViewModel.biometricType != .none && !authViewModel.isBiometricEnabled && rememberMe {
            return "Sign In & Enable \(authViewModel.biometricTypeName)"
        } else {
            return "Sign In with Email"
        }
    }
    
    private func loadSavedEmail() {
        if let savedEmail = UserDefaults.standard.string(forKey: "remembered_email") {
            email = savedEmail
            rememberMe = true
        }
        
        // Debug print
        print("🔐 LoginView appeared - BiometricEnabled: \(authViewModel.isBiometricEnabled), BiometricType: \(authViewModel.biometricType)")
    }
    
    private func authenticateWithBiometrics() {
        guard !isAuthenticatingBiometric else { return }
        
        isAuthenticatingBiometric = true
        authViewModel.errorMessage = nil
        
        Task {
            let success = await authViewModel.signInWithBiometrics()
            
            await MainActor.run {
                self.isAuthenticatingBiometric = false
                if success {
                    print("✅ Biometric authentication successful!")
                } else {
                    print("❌ Biometric authentication failed")
                }
            }
        }
    }
    
    private func signInWithEmail() {
        guard isFormValid && !authViewModel.isLoading else { return }
        
        let shouldEnableBiometric = rememberMe && authViewModel.biometricType != .none && !authViewModel.isBiometricEnabled
        
        print("🔐 Signing in - EnableBiometric: \(shouldEnableBiometric), RememberMe: \(rememberMe)")
        
        authViewModel.signIn(email: email, password: password, enableBiometric: shouldEnableBiometric)
        
        // Save email for remember me (traditional remember me functionality)
        if rememberMe && !shouldEnableBiometric {
            UserDefaults.standard.set(email, forKey: "remembered_email")
        } else if !rememberMe {
            UserDefaults.standard.removeObject(forKey: "remembered_email")
        }
    }
}

#Preview {
    LoginView(showingLogin: .constant(true))
        .environmentObject(AuthViewModel())
}
