import SwiftUI
import Foundation
import FirebaseAuth
import FirebaseFirestore
import UserNotifications
import LocalAuthentication

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String
    let createdAt: Date
    let profileImageURL: String?
    let phoneNumber: String?
    let isEmailVerified: Bool
    
    var firstName: String {
        fullName.components(separatedBy: " ").first ?? fullName
    }
    
    init(firebaseUser: FirebaseAuth.User, fullName: String, profileImageURL: String? = nil, phoneNumber: String? = nil) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.fullName = fullName
        self.createdAt = Date()
        self.profileImageURL = profileImageURL
        self.phoneNumber = phoneNumber
        self.isEmailVerified = firebaseUser.isEmailVerified
    }
}

// MARK: - Auth View Model
@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isBiometricAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    @Published var biometricType: LABiometryType = .none
    @Published var isBiometricEnabled = false
    @Published var shouldShowBiometricPrompt = false
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let context = LAContext()
    
    // Keys for storing biometric preferences
    private let biometricEnabledKey = "biometric_enabled"
    private let storedEmailKey = "stored_email_for_biometric"
    private let storedPasswordKey = "stored_password_for_biometric"
    private let biometricPromptShownKey = "biometric_prompt_shown"
    
    init() {
        Task {
            await initializeViewModel()
        }
    }
    
    private func initializeViewModel() async {
        do {
            checkBiometricAvailability()
            loadBiometricSettings()
            setupAuthStateListener()
        } catch {
            print("Error initializing AuthViewModel: \(error)")
        }
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Biometric Properties
    var biometricTypeName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Biometric"
        }
    }
    
    var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        default:
            return "person.badge.key.fill"
        }
    }
    
    // MARK: - Authentication State
    private func setupAuthStateListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
                
                if let user = user {
                    self?.loadCurrentUser(firebaseUser: user)
                } else {
                    self?.currentUser = nil
                    self?.isBiometricAuthenticated = false
                }
            }
        }
    }
    
    private func loadCurrentUser(firebaseUser: FirebaseAuth.User) {
        Task {
            do {
                let snapshot = try await db.collection("users").document(firebaseUser.uid).getDocument()
                
                await MainActor.run {
                    if let data = snapshot.data(),
                       let fullName = data["fullName"] as? String {
                        self.currentUser = User(
                            firebaseUser: firebaseUser,
                            fullName: fullName,
                            profileImageURL: data["profileImageURL"] as? String,
                            phoneNumber: data["phoneNumber"] as? String
                        )
                    } else {
                        // Fallback user creation
                        self.currentUser = User(
                            firebaseUser: firebaseUser,
                            fullName: firebaseUser.displayName ?? "User"
                        )
                    }
                }
            } catch {
                print("Error loading user data: \(error)")
                await MainActor.run {
                    self.currentUser = User(
                        firebaseUser: firebaseUser,
                        fullName: firebaseUser.displayName ?? "User"
                    )
                }
            }
        }
    }
    
    // MARK: - Biometric Setup & Management
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            self.biometricType = context.biometryType
        } else {
            self.biometricType = .none
            print("Biometric not available: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    private func loadBiometricSettings() {
        let enabled = UserDefaults.standard.bool(forKey: biometricEnabledKey)
        let hasStoredEmail = UserDefaults.standard.string(forKey: storedEmailKey) != nil
        
        self.isBiometricEnabled = enabled && hasStoredEmail
        print("🔐 Loaded biometric settings - enabled: \(enabled), hasEmail: \(hasStoredEmail)")
    }
    
    func enableBiometricAuthentication(email: String, password: String? = nil) {
        guard biometricType != .none else {
            errorMessage = "Biometric authentication is not available on this device"
            return
        }
        
        let reason = "Enable \(biometricTypeName) for quick and secure access to PawFinder"
        let context = LAContext()
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
            Task { @MainActor in
                if success {
                    // Store the credentials
                    UserDefaults.standard.set(true, forKey: self?.biometricEnabledKey ?? "")
                    UserDefaults.standard.set(email, forKey: self?.storedEmailKey ?? "")
                    
                    if let password = password {
                        UserDefaults.standard.set(password, forKey: self?.storedPasswordKey ?? "")
                    }
                    
                    UserDefaults.standard.set(true, forKey: self?.biometricPromptShownKey ?? "")
                    
                    self?.isBiometricEnabled = true
                    self?.shouldShowBiometricPrompt = false
                    self?.errorMessage = nil
                    
                    print("✅ Biometric authentication enabled successfully for \(email)")
                } else {
                    if let error = error as? LAError, error.code != .userCancel {
                        self?.errorMessage = "Failed to enable \(self?.biometricTypeName ?? "biometric") authentication"
                    }
                }
            }
        }
    }
    
    func disableBiometricAuthentication() {
        UserDefaults.standard.set(false, forKey: biometricEnabledKey)
        UserDefaults.standard.removeObject(forKey: storedEmailKey)
        UserDefaults.standard.removeObject(forKey: storedPasswordKey)
        
        self.isBiometricEnabled = false
        self.isBiometricAuthenticated = false
        print("🔐 Biometric authentication disabled")
    }
    
    func checkShouldShowBiometricPrompt() -> Bool {
        let hasShownPrompt = UserDefaults.standard.bool(forKey: biometricPromptShownKey)
        let shouldShow = !isBiometricEnabled && biometricType != .none && !hasShownPrompt
        return shouldShow
    }
    
    func markBiometricPromptShown() {
        UserDefaults.standard.set(true, forKey: biometricPromptShownKey)
        shouldShowBiometricPrompt = false
    }
    
    // MARK: - Biometric Authentication
    func signInWithBiometrics() async -> Bool {
        guard isBiometricEnabled,
              let storedEmail = UserDefaults.standard.string(forKey: storedEmailKey),
              let storedPassword = UserDefaults.standard.string(forKey: storedPasswordKey) else {
            await MainActor.run {
                self.errorMessage = "Biometric authentication is not set up properly"
            }
            return false
        }
        
        let reason = "Sign in to PawFinder with \(biometricTypeName)"
        let context = LAContext()
        
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            
            if success {
                // Sign in with Firebase using stored credentials
                do {
                    let _ = try await auth.signIn(withEmail: storedEmail, password: storedPassword)
                    
                    await MainActor.run {
                        self.isBiometricAuthenticated = true
                        self.errorMessage = nil
                    }
                    print("✅ Biometric sign-in successful")
                    return true
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Sign-in failed. Please use email and password."
                    }
                    print("❌ Firebase sign-in failed: \(error.localizedDescription)")
                    return false
                }
            }
            return false
        } catch {
            await MainActor.run {
                if let laError = error as? LAError {
                    switch laError.code {
                    case .userCancel:
                        self.errorMessage = nil
                    case .userFallback:
                        self.errorMessage = "Please use your device passcode"
                    case .biometryNotAvailable:
                        self.errorMessage = "\(self.biometricTypeName) is not available"
                    case .biometryNotEnrolled:
                        self.errorMessage = "Please set up \(self.biometricTypeName) in Settings"
                    default:
                        self.errorMessage = "Authentication failed. Please try again."
                    }
                }
            }
            return false
        }
    }
    
    func authenticateWithBiometrics(reason: String) async -> Bool {
        let context = LAContext()
        
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch {
            return false
        }
    }
    
    // MARK: - Firebase Authentication Methods
    func signIn(email: String, password: String, enableBiometric: Bool = false) {
        Task {
            await performSignIn(email: email, password: password, enableBiometric: enableBiometric)
        }
    }
    
    @MainActor
    private func performSignIn(email: String, password: String, enableBiometric: Bool) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let _ = try await auth.signIn(withEmail: email, password: password)
            print("✅ Email sign-in successful")
            
            if enableBiometric {
                enableBiometricAuthentication(email: email, password: password)
            } else if checkShouldShowBiometricPrompt() {
                shouldShowBiometricPrompt = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, fullName: String) {
        Task {
            await performSignUp(email: email, password: password, fullName: fullName)
        }
    }
    
    @MainActor
    private func performSignUp(email: String, password: String, fullName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Store user data in Firestore
            let userData: [String: Any] = [
                "fullName": fullName,
                "email": email,
                "createdAt": Timestamp(date: Date()),
                "isEmailVerified": result.user.isEmailVerified
            ]
            
            try await db.collection("users").document(result.user.uid).setData(userData)
            
            // Update user profile
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = fullName
            try await changeRequest.commitChanges()
            
            // Check if we should prompt for biometric setup
            if checkShouldShowBiometricPrompt() {
                shouldShowBiometricPrompt = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try auth.signOut()
            isBiometricAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func resetPassword(email: String) {
        Task {
            do {
                try await auth.sendPasswordReset(withEmail: email)
                await MainActor.run {
                    self.errorMessage = "Password reset email sent!"
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    func setBiometricAuthenticated(_ value: Bool) {
        isBiometricAuthenticated = value
    }
}
