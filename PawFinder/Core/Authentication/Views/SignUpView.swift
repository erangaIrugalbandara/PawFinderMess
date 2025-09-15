import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)
            
            Spacer()
            
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: signUp) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Create Account")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading || !isValidForm())
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            Button("Already have an account? Sign In") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.blue)
            .padding(.bottom, 30)
        }
        .navigationBarHidden(true)
        .alert("Sign Up Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func isValidForm() -> Bool {
        return !email.isEmpty &&
               !password.isEmpty &&
               !confirmPassword.isEmpty &&
               password == confirmPassword &&
               password.count >= 6
    }
    
    private func signUp() {
        guard isValidForm() else {
            alertMessage = "Please fill all fields correctly"
            showingAlert = true
            return
        }
        
        isLoading = true
        
        // Add your sign up logic here
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            // On successful signup, navigate to profile or main app
            // You might want to save the email for potential biometric use
            UserDefaults.standard.savedUserEmail = email
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
