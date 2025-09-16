import SwiftUI
import FirebaseAuth

struct BiometricSettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEnableAlert = false
    @State private var showingDisableAlert = false
    @State private var passwordForEnable = ""
    @State private var isEnabling = false
    @State private var isTestingBiometric = false
    @State private var testResult: String?
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Background gradient matching app theme
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.35, green: 0.25, blue: 0.8),
                    Color(red: 0.55, green: 0.35, blue: 0.9),
                    Color(red: 0.65, green: 0.45, blue: 0.95)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header Section
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: authViewModel.biometricIcon)
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(authViewModel.biometricName) Authentication")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Quick and secure access to your account")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            // Status indicator
                            ZStack {
                                Circle()
                                    .fill(authViewModel.isBiometricEnabled ? Color.green.opacity(0.3) : Color.gray.opacity(0.3))
                                    .frame(width: 16, height: 16)
                                
                                Circle()
                                    .fill(authViewModel.isBiometricEnabled ? Color.green : Color.gray)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    }
                    
                    // Content Card
                    VStack(spacing: 24) {
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        
                        if !authViewModel.isBiometricAvailable {
                            // Device doesn't support biometric
                            notSupportedCard
                        } else if authViewModel.isBiometricEnabled {
                            // Biometric is enabled
                            enabledCard
                            testButton
                            disableButton
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
                                .padding(.vertical, 8)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        self.testResult = nil
                                    }
                                }
                        }
                        
                        // Security Information
                        securityInfoCard
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThickMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Back")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .alert("Enable \(authViewModel.biometricName)?", isPresented: $showingEnableAlert) {
            SecureField("Enter your password", text: $passwordForEnable)
            Button("Cancel", role: .cancel) {
                passwordForEnable = ""
            }
            Button("Enable") {
                enableBiometric()
            }
            .disabled(passwordForEnable.isEmpty)
        } message: {
            Text("Please enter your current password to enable \(authViewModel.biometricName) authentication.")
        }
        .alert("Disable \(authViewModel.biometricName)?", isPresented: $showingDisableAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Disable", role: .destructive) {
                disableBiometric()
            }
        } message: {
            Text("You'll need to use your email and password to sign in. You can always re-enable this later.")
        }
    }
    
    // MARK: - UI Components
    private var notSupportedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                
                Text("Not Supported")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.orange)
            }
            
            Text("This device doesn't support biometric authentication. Please use email and password to sign in.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var enabledCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                
                Text("Enabled")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.green)
            }
            
            Text("\(authViewModel.biometricName) is active. You can use it to quickly sign into PawFinder.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var availableCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                Text("Available")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            Text("Enable \(authViewModel.biometricName) for quick and secure access while keeping email and password as backup.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var enableButton: some View {
        Button(action: {
            showingEnableAlert = true
        }) {
            HStack(spacing: 12) {
                if isEnabling {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: authViewModel.biometricIcon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(isEnabling ? "Enabling..." : "Enable \(authViewModel.biometricName)")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: Color.blue.opacity(0.3), radius: 15, x: 0, y: 8)
        }
        .disabled(isEnabling)
    }
    
    private var disableButton: some View {
        Button(action: {
            showingDisableAlert = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 16, weight: .medium))
                
                Text("Disable \(authViewModel.biometricName)")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private var testButton: some View {
        Button(action: {
            testBiometric()
        }) {
            HStack(spacing: 12) {
                if isTestingBiometric {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: authViewModel.biometricIcon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(isTestingBiometric ? "Testing..." : "Test \(authViewModel.biometricName)")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .disabled(isTestingBiometric)
    }
    
    private var securityInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("Security Information")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                SecurityInfoRow(text: "Your biometric data never leaves your device")
                SecurityInfoRow(text: "PawFinder cannot access your biometric information")
                SecurityInfoRow(text: "You can disable this feature at any time")
                SecurityInfoRow(text: "Email and password will always work as backup")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Methods
    private func enableBiometric() {
        guard let userEmail = authViewModel.currentUser?.email,
              !passwordForEnable.isEmpty else {
            errorMessage = "Email or password is missing"
            passwordForEnable = ""
            return
        }
        
        isEnabling = true
        errorMessage = nil
        
        Task {
            // First verify password
            do {
                let credential = EmailAuthProvider.credential(withEmail: userEmail, password: passwordForEnable)
                try await Auth.auth().currentUser?.reauthenticate(with: credential)
                
                // If password is correct, enable biometric
                let result = await authViewModel.enableBiometric(email: userEmail, password: passwordForEnable)
                
                await MainActor.run {
                    if result.success {
                        self.testResult = "✅ \(authViewModel.biometricName) enabled successfully!"
                    } else {
                        self.errorMessage = result.error
                    }
                    
                    self.passwordForEnable = ""
                    self.isEnabling = false
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Password verification failed"
                    self.passwordForEnable = ""
                    self.isEnabling = false
                }
            }
        }
    }
    
    private func disableBiometric() {
        authViewModel.disableBiometric()
        testResult = "Biometric authentication disabled"
        errorMessage = nil
    }
    
    private func testBiometric() {
        isTestingBiometric = true
        
        Task {
            let result = await authViewModel.testBiometric()
            
            await MainActor.run {
                self.isTestingBiometric = false
                
                if result.success {
                    self.testResult = "✅ \(authViewModel.biometricName) test successful!"
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                } else {
                    self.testResult = "❌ Test failed"
                    if let error = result.error {
                        self.errorMessage = error
                    }
                }
            }
        }
    }
}

struct SecurityInfoRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationView {
        BiometricSettingsView()
            .environmentObject(AuthViewModel())
    }
}
