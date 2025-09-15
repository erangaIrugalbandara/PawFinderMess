import SwiftUI

struct BiometricSettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingConfirmation = false
    @State private var pendingToggle = false
    @State private var showingSetupPrompt = false
    
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
                // Current Status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Status")
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
                            if newValue {
                                enableBiometric()
                            } else {
                                showingConfirmation = true
                            }
                        }
                    ))
                    .disabled(authViewModel.biometricType == .none)
                }
                .padding(.vertical, 8)
                
                if authViewModel.biometricType == .none {
                    // Device doesn't support biometric
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.orange)
                            
                            Text("Not Available")
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
                } else if authViewModel.isBiometricEnabled {
                    // Biometric is enabled
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                            
                            Text("Active")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        
                        Text("You can now use \(authViewModel.biometricTypeName) to quickly sign into PawFinder. Your authentication data is stored securely on your device.")
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
                    
                    // Test Button
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
                    
                } else {
                    // Biometric is available but not enabled
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                            
                            Text("Available")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        
                        Text("Enable \(authViewModel.biometricTypeName) for quick and secure access. You'll still be able to use your email and password.")
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
                    
                    // Setup Button
                    Button(action: {
                        showingSetupPrompt = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: authViewModel.biometricIcon)
                                .font(.system(size: 16))
                            
                            Text("Enable \(authViewModel.biometricTypeName)")
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
                }
                
                // Security Information
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
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .navigationTitle("Biometric Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Disable \(authViewModel.biometricTypeName)?", isPresented: $showingConfirmation) {
            Button("Keep Enabled", role: .cancel) { }
            Button("Disable", role: .destructive) {
                authViewModel.disableBiometricAuthentication()
            }
        } message: {
            Text("You'll need to use your email and password to sign in. You can always re-enable this later.")
        }
        .alert("Enable \(authViewModel.biometricTypeName)?", isPresented: $showingSetupPrompt) {
            Button("Cancel", role: .cancel) { }
            Button("Enable") {
                enableBiometric()
            }
        } message: {
            Text("Use \(authViewModel.biometricTypeName) for quick and secure access to PawFinder.")
        }
    }
    
    private var statusText: String {
        if authViewModel.biometricType == .none {
            return "Not supported on this device"
        } else if authViewModel.isBiometricEnabled {
            return "Enabled - Quick sign in active"
        } else {
            return "Available - Tap to enable"
        }
    }
    
    private func enableBiometric() {
        guard let userEmail = authViewModel.currentUser?.email else {
            authViewModel.errorMessage = "User email not available"
            return
        }
        
        authViewModel.enableBiometricAuthentication(email: userEmail)
    }
    
    private func testBiometric() {
        Task {
            let success = await authViewModel.authenticateWithBiometrics(reason: "Test \(authViewModel.biometricTypeName) authentication")
            
            DispatchQueue.main.async {
                if success {
                    // Could show a success message or haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
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
