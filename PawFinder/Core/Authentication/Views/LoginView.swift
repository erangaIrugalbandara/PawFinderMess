import SwiftUI

struct LoginView: View {
    @Binding var showingLogin: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isAuthenticatingBiometric = false
    
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
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.1))
                            )
                    }
                    
                    // Biometric Authentication Button (Only show if enabled)
                    if authViewModel.isBiometricEnabled {
                        VStack(spacing: 20) {
                            Button(action: {
                                authenticateWithBiometric()
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
                                    
                                    Text(isAuthenticatingBiometric ? "Authenticating..." : "Sign in using \(authViewModel.biometricName)")
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
                                    .textContentType(.emailAddress)
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
                                    .textContentType(.password)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.2))
                            )
                        }
                        
                        // Forgot Password
                        HStack {
                            Spacer()
                            
                            Button("Forgot Password?") {
                                resetPassword()
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 24)
                    
                    // Biometric Setup Promotion (Only if biometric available but not enabled)
                    if authViewModel.isBiometricAvailable && !authViewModel.isBiometricEnabled {
                        VStack(spacing: 16) {
                            VStack(spacing: 12) {
                                Image(systemName: authViewModel.biometricIcon)
                                    .font(.system(size: 30))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("Enable \(authViewModel.biometricName) for faster login?")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Text("You can set this up in Profile settings after signing in")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    // Sign In Button
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
                            Text("Sign in with Email")
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
            // Clear any errors when view appears
            authViewModel.errorMessage = nil
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            hideKeyboard()
        }
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@") && email.contains(".")
    }
    
    // MARK: - Methods
    private func authenticateWithBiometric() {
        guard !isAuthenticatingBiometric else { return }
        
        isAuthenticatingBiometric = true
        authViewModel.errorMessage = nil
        
        Task {
            let success = await authViewModel.signInWithBiometric()
            
            await MainActor.run {
                self.isAuthenticatingBiometric = false
                if !success {
                    print("❌ Biometric authentication failed")
                }
            }
        }
    }
    
    private func signInWithEmail() {
        guard isFormValid && !authViewModel.isLoading else { return }
        
        hideKeyboard()
        authViewModel.signIn(email: email, password: password)
    }
    
    private func resetPassword() {
        guard !email.isEmpty else {
            authViewModel.errorMessage = "Please enter your email address first"
            return
        }
        
        authViewModel.resetPassword(email: email)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    LoginView(showingLogin: .constant(true))
        .environmentObject(AuthViewModel())
}
