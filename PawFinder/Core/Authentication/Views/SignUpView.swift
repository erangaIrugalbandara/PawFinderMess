import SwiftUI

struct SignUpView: View {
    @Binding var showingLogin: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    
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
                        
                        Text("Join PawFinder")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Help reunite pets with their families")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 20)
                    
                    // Error Message
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 24)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        // Full Name Field
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 20)
                                
                                TextField("Full Name", text: $fullName)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .autocapitalization(.words)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.2))
                            )
                        }
                        
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
                                
                                SecureField("Password (min 6 characters)", text: $password)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                !password.isEmpty && password.count < 6 ?
                                                Color.red.opacity(0.6) :
                                                Color.clear,
                                                lineWidth: 1
                                            )
                                    )
                            )
                            
                            if !password.isEmpty && password.count < 6 {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                    Text("Password must be at least 6 characters")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.red)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 4)
                            }
                        }
                        
                        // Confirm Password Field
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 20)
                                
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                !confirmPassword.isEmpty && confirmPassword != password ?
                                                Color.red.opacity(0.6) :
                                                Color.clear,
                                                lineWidth: 1
                                            )
                                    )
                            )
                            
                            if !confirmPassword.isEmpty && confirmPassword != password {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                    Text("Passwords do not match")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.red)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 4)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Create Account Button
                    Button(action: {
                        signUp()
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.4, green: 0.3, blue: 0.8)))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(28)
                        } else {
                            Text("Create Account")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .cornerRadius(28)
                        }
                    }
                    .disabled(!isFormValid || authViewModel.isLoading)
                    .opacity(isFormValid && !authViewModel.isLoading ? 1.0 : 0.6)
                    .padding(.horizontal, 24)
                    
                    // Sign In Link
                    HStack {
                        Text("Already have an account?")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button("Sign In") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingLogin = true
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onChange(of: authViewModel.shouldShowBiometricPrompt) { _, shouldShow in
            if shouldShow && authViewModel.isAuthenticated {
                // User just signed up successfully, show biometric setup prompt
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    // This will be handled by the main ContentView flow
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        return !fullName.isEmpty &&
               !email.isEmpty &&
               !password.isEmpty &&
               !confirmPassword.isEmpty &&
               password == confirmPassword &&
               password.count >= 6 &&
               email.contains("@")
    }
    
    private func signUp() {
        guard isFormValid && !authViewModel.isLoading else { return }
        
        authViewModel.signUp(email: email, password: password, fullName: fullName)
    }
}

#Preview {
    SignUpView(showingLogin: .constant(false))
        .environmentObject(AuthViewModel())
}
