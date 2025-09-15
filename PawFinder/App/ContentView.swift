import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if authViewModel.isAuthenticated {
                    // User is signed into Firebase
                    if authViewModel.isBiometricEnabled && !authViewModel.isBiometricAuthenticated {
                        // User has biometric enabled but needs to authenticate with biometric
                        BiometricAuthView()
                            .environmentObject(authViewModel)
                    } else {
                        // User is fully authenticated, show dashboard
                        DashboardView()
                            .environmentObject(authViewModel)
                    }
                } else {
                    // User is not signed into Firebase
                    if authViewModel.isBiometricEnabled {
                        // User has biometric set up, show biometric auth
                        BiometricAuthView()
                            .environmentObject(authViewModel)
                    } else {
                        // First time user or no biometric, show welcome
                        WelcomeView()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Debug: Print current state
            print("🔐 ContentView - Authenticated: \(authViewModel.isAuthenticated), BiometricEnabled: \(authViewModel.isBiometricEnabled), BiometricAuthenticated: \(authViewModel.isBiometricAuthenticated)")
        }
        .onChange(of: authViewModel.isAuthenticated) { isAuth in
            print("🔐 Auth state changed: \(isAuth)")
        }
        .onChange(of: authViewModel.isBiometricEnabled) { isEnabled in
            print("🔐 Biometric enabled changed: \(isEnabled)")
        }
    }
}

#Preview {
    ContentView()
}
