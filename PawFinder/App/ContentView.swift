import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var isInitialized = false
    
    var body: some View {
        NavigationView {
            Group {
                if !isInitialized {
                    // Loading screen while initializing
                    splashScreen
                } else if authViewModel.isAuthenticated {
                    // User is signed into Firebase - show main app
                    DashboardView()
                        .environmentObject(authViewModel)
                } else {
                    // User is not signed in
                    if authViewModel.isBiometricEnabled {
                        // User has biometric set up - show biometric auth
                        BiometricAuthView()
                            .environmentObject(authViewModel)
                    } else {
                        // No biometric or first time - show welcome
                        WelcomeView()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            initializeApp()
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuth in
            print("🔐 Auth state changed: \(isAuth)")
        }
        .onChange(of: authViewModel.isBiometricEnabled) { _, isEnabled in
            print("🔐 Biometric enabled changed: \(isEnabled)")
        }
    }
    
    // MARK: - Splash Screen
    private var splashScreen: some View {
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
            
            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                
                Text("PawFinder")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            }
        }
    }
    
    // MARK: - Methods
    private func initializeApp() {
        // Small delay to show splash screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isInitialized = true
            }
            
            // Debug current state
            print("🔐 ContentView initialized - Authenticated: \(authViewModel.isAuthenticated), BiometricEnabled: \(authViewModel.isBiometricEnabled)")
        }
    }
}

#Preview {
    ContentView()
}
