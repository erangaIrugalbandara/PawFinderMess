import SwiftUI

struct WelcomeView: View {
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
            
            VStack(spacing: 32) {
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                
                Text("PawFind")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Bringing lost pets home safely")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                NavigationLink(destination: WelcomeAuthContainerView()) {
                    HStack {
                        Spacer()
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
                        Spacer()
                    }
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(28)
                    .padding(.horizontal, 24)
                }
                
                Text("We respect your privacy. Location data stays on your device.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Welcome Auth Container
struct WelcomeAuthContainerView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showingLogin = false
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                DashboardView()
                    .environmentObject(authViewModel)
            } else {
                VStack(spacing: 20) {
                    if showingLogin {
                        LoginView(showingLogin: $showingLogin)
                            .environmentObject(authViewModel)
                    } else {
                        SignUpView(showingLogin: $showingLogin)
                            .environmentObject(authViewModel)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationView {
        WelcomeView()
    }
}
