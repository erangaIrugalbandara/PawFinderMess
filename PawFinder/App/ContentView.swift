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
                    // User is authenticated - show main app
                    DashboardView()
                        .environmentObject(authViewModel)
                } else {
                    // User is not authenticated - show welcome screen
                    WelcomeView()
                        .environmentObject(authViewModel)
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
            
            print("🔐 ContentView initialized - Authenticated: \(authViewModel.isAuthenticated)")
        }
    }
}

#Preview {
    ContentView()
}
