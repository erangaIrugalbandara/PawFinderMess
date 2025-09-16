import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct BiometricSettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDisableConfirmation = false
    @State private var showingEnablePrompt = false
    @State private var passwordForBiometric = ""
    @State private var isEnabling = false
    @State private var showingPasswordAlert = false
    @State private var testResult: String?
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: authViewModel.biometricIcon)
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                        
                        Text("\(authViewModel.biometricTypeName) Authentication")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Text("Quick and secure access to your account")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                ZStack {
                    Circle()
                        .fill(authViewModel.isBiometricEnabled ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 12, height: 12)
                    
                    Circle()
                        .fill(authViewModel.isBiometricEnabled ? Color.green : Color.gray)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.vertical, 16)
            
            Divider()
            
            // Settings Content
            VStack(spacing: 20) {
                // Error Message Display
                if let errorMessage = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                        Spacer()
                        Button("Dismiss") {
                            self.errorMessage = nil
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                // Toggle Switch
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable \(authViewModel.biometricTypeName)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(statusText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { authViewModel.isBiometricEnabled },
                        set: { newValue in
                            handleToggleChange(newValue)
                        }
                    ))
                    .disabled(authViewModel.biometricType == .none || isEnabling)
                }
                .padding(.vertical, 8)
                
                if authViewModel.biometricType == .none {
                    // Device doesn't support biometric
                    notSupportedCard
                } else if authViewModel.isBiometricEnabled {
                    // Biometric is enabled
                    enabledCard
                    testButton
                } else {
                    // Biometric is available but not enabled
                    availableCard
                    enableButton
                }
                
                // Test Result
                if let testResult = testResult {
                    Text(testResult)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(testResult.contains("successful") ? .green : .red)
                        .padding(.top, 8)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                self.testResult = nil
                            }
                        }
                }
                
                // Security Information
                securityInfoCard
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .navigationTitle("Biometric Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .alert("Disable \(authViewModel.biometricTypeName)?", isPresented: $showingDisableConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Disable", role: .destructive) {
                handleDisableBiometric()
            }
        } message: {
            Text("You'll need to use your email and password to sign in. You can always re-enable this later.")
        }
        .alert("Enable \(authViewModel.biometricTypeName)?", isPresented: $showingEnablePrompt) {
            Button("Cancel", role: .cancel) { }
            Button("Continue") {
                showingPasswordAlert = true
            }
        } message: {
            Text("You'll need to confirm your password to set up \(authViewModel.biometricTypeName) authentication.")
        }
        .alert("Confirm Password", isPresented: $showingPasswordAlert) {
            SecureField("Enter your password", text: $passwordForBiometric)
            Button("Cancel", role: .cancel) {
                handlePasswordAlertCancel()
            }
            Button("Enable") {
                handleEnableBiometric()
            }
            .disabled(passwordForBiometric.isEmpty)
        } message: {
            Text("Please enter your current password to enable \(authViewModel.biometricTypeName).")
        }
    }
    
    // MARK: - UI Components
    private var notSupportedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
                
                Text("Not Supported")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orange)
            }
            
            Text("This device doesn't support biometric authentication. Please use email and password to sign in.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var enabledCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
                
                Text("Enabled")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.green)
            }
            
            Text("\(authViewModel.biometricTypeName) is active. You can use it to quickly sign into PawFinder.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var availableCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                
                Text("Available")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            Text("Enable \(authViewModel.biometricTypeName) for quick and secure access while keeping email and password as backup.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var enableButton: some View {
        Button(action: {
            showingEnablePrompt = true
        }) {
            HStack(spacing: 12) {
                if isEnabling {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: authViewModel.biometricIcon)
                        .font(.system(size: 16))
                }
                
                Text(isEnabling ? "Enabling..." : "Enable \(authViewModel.biometricTypeName)")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
            )
        }
        .disabled(isEnabling)
    }
    
    private var testButton: some View {
        Button(action: {
            testBiometric()
        }) {
            HStack(spacing: 12) {
                Image(systemName: authViewModel.biometricIcon)
                    .font(.system(size: 16))
                
                Text("Test \(authViewModel.biometricTypeName)")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private var securityInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text("Security Information")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            Text("• Your biometric data never leaves your device\n• PawFinder cannot access your biometric information\n• You can disable this feature at any time\n• Email and password will always work as backup")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Computed Properties
    private var statusText: String {
        if authViewModel.biometricType == .none {
            return "Not supported on this device"
        } else if authViewModel.isBiometricEnabled {
            return "Quick sign-in is active"
        } else {
            return "Tap to enable quick access"
        }
    }
    
    // MARK: - Action Handlers (Crash Prevention)
    private func handleToggleChange(_ newValue: Bool) {
        // Clear any existing errors
        errorMessage = nil
        
        // Validate prerequisites
        guard authViewModel.currentUser != nil else {
            errorMessage = "User not signed in"
            return
        }
        
        guard authViewModel.biometricType != .none else {
            errorMessage = "Biometric authentication not supported"
            return
        }
        
        if newValue {
            showingEnablePrompt = true
        } else {
            showingDisableConfirmation = true
        }
    }
    
    private func handleDisableBiometric() {
        do {
            authViewModel.disableBiometricAuthentication()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to disable biometric: \(error.localizedDescription)"
        }
    }
    
    private func handlePasswordAlertCancel() {
        passwordForBiometric = ""
        errorMessage = nil
    }
    
    private func handleEnableBiometric() {
        // Validate inputs
        guard let userEmail = authViewModel.currentUser?.email,
              !userEmail.isEmpty else {
            errorMessage = "User email not available"
            passwordForBiometric = ""
            return
        }
        
        guard !passwordForBiometric.isEmpty else {
            errorMessage = "Password is required"
            return
        }
        
        // Validate password format (basic check)
        guard passwordForBiometric.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        // Clear any existing errors
        errorMessage = nil
        isEnabling = true
        
        // Use a Task to handle the async operation safely
        Task { @MainActor in
            do {
                // First verify the password with Firebase
                try await verifyPassword(email: userEmail, password: passwordForBiometric)
                
                // If password is correct, enable biometric
                authViewModel.enableBiometricAuthentication(email: userEmail, password: passwordForBiometric)
                
                // Monitor for any errors from the AuthViewModel
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if let authError = authViewModel.errorMessage {
                        self.errorMessage = authError
                    }
                    
                    // Clean up
                    self.passwordForBiometric = ""
                    self.isEnabling = false
                }
                
            } catch {
                self.errorMessage = "Password verification failed: \(error.localizedDescription)"
                self.passwordForBiometric = ""
                self.isEnabling = false
            }
        }
    }
    
    // MARK: - Helper Methods
    @MainActor
    private func verifyPassword(email: String, password: String) async throws {
        // Create a temporary credential to test the password
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        
        // Try to reauthenticate the current user
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        try await currentUser.reauthenticate(with: credential)
    }
    
    private func testBiometric() {
        Task { @MainActor in
            do {
                let success = await authViewModel.testBiometricAuthentication()
                
                if success {
                    testResult = "✅ \(authViewModel.biometricTypeName) test successful!"
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                } else {
                    testResult = "❌ \(authViewModel.biometricTypeName) test failed"
                }
            } catch {
                testResult = "❌ Test failed: \(error.localizedDescription)"
                print("Biometric test error: \(error)")
            }
        }
    }
}

#Preview {
    NavigationView {
        BiometricSettingsView()
            .environmentObject(AuthViewModel())
    }
}
