//import SwiftUI
//
//struct AuthContainerView: View {
//    @StateObject private var authViewModel = AuthViewModel()
//    @State private var showingLogin = false
//    
//    var body: some View {
//        Group {
//            if authViewModel.isAuthenticated {
//                DashboardView()
//                    .environmentObject(authViewModel)
//            } else {
//                VStack(spacing: 20) {
//                    if showingLogin {
//                        LoginView(showingLogin: $showingLogin)
//                            .environmentObject(authViewModel)
//                    } else {
//                        SignUpView(showingLogin: $showingLogin)
//                            .environmentObject(authViewModel)
//                    }
//                }
//            }
//        }
//        .navigationBarHidden(true)
//    }
//}
//
//#Preview {
//    NavigationView {
//        AuthContainerView()
//    }
//}
