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

// MARK: - Biometric Manager (Crash-Proof)
class BiometricManager {
    static let shared = BiometricManager()
    private let context = LAContext()
    
    private let biometricEnabledKey = "pawfinder_biometric_enabled_v2"
    private let storedEmailKey = "pawfinder_stored_email_v2"
    private let storedPasswordKey = "pawfinder_stored_password_v2"
    private let biometricPromptShownKey = "pawfinder_biometric_prompt_shown_v2"
    
    var biometricType: LABiometryType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        return context.biometryType
    }
    
    var isAvailable: Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    var isEnabled: Bool {
        guard isAvailable else { return false }
        
        let enabled = UserDefaults.standard.bool(forKey: biometricEnabledKey)
        let hasEmail = UserDefaults.standard.string(forKey: storedEmailKey) != nil
        let hasPassword = UserDefaults.standard.string(forKey: storedPasswordKey) != nil
        
        // All conditions must be true
        return enabled && hasEmail && hasPassword
    }
    
    // MARK: - Safe Enable Biometric
    func enableBiometric(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        guard isAvailable else {
            completion(false, "Biometric authentication is not available on this device")
            return
        }
        
        guard !email.isEmpty && !password.isEmpty else {
            completion(false, "Email and password are required")
            return
        }
        
        let reason = "Enable biometric authentication for PawFinder"
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        
        // Test biometric first
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if success {
                    // Store credentials safely
                    do {
                        UserDefaults.standard.set(true, forKey: self.biometricEnabledKey)
                        UserDefaults.standard.set(email, forKey: self.storedEmailKey)
                        UserDefaults.standard.set(password, forKey: self.storedPasswordKey)
                        UserDefaults.standard.set(true, forKey: self.biometricPromptShownKey)
                        
                        // Force synchronization
                        UserDefaults.standard.synchronize()
                        
                        completion(true, nil)
                        print("✅ Biometric enabled successfully for: \(email)")
                    } catch {
                        completion(false, "Failed to save biometric settings: \(error.localizedDescription)")
                    }
                } else {
                    if let laError = error as? LAError {
                        switch laError.code {
                        case .userCancel:
                            completion(false, nil) // Don't show error for user cancel
                        case .biometryNotAvailable:
                            completion(false, "Biometric authentication is not available")
                        case .biometryNotEnrolled:
                            completion(false, "Please set up biometric authentication in Settings")
                        case .biometryLockout:
                            completion(false, "Biometric authentication is locked")
                        default:
                            completion(false, "Failed to enable biometric authentication")
                        }
                    } else {
                        completion(false, "Failed to enable biometric authentication")
                    }
                }
            }
        }
    }
    
    // MARK: - Safe Disable Biometric
    func disableBiometric() {
        UserDefaults.standard.removeObject(forKey: biometricEnabledKey)
        UserDefaults.standard.removeObject(forKey: storedEmailKey)
        UserDefaults.standard.removeObject(forKey: storedPasswordKey)
        UserDefaults.standard.synchronize()
        print("🔐 Biometric authentication disabled")
    }
    
    // MARK: - Safe Authenticate
    func authenticate(completion: @escaping (String?, String?, Error?) -> Void) {
        guard isEnabled else {
            completion(nil, nil, NSError(domain: "BiometricError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Biometric authentication is not enabled"]))
            return
        }
        
        guard let email = UserDefaults.standard.string(forKey: storedEmailKey),
              let password = UserDefaults.standard.string(forKey: storedPasswordKey),
              !email.isEmpty,
              !password.isEmpty else {
            
            // Clean up corrupted data
            disableBiometric()
            completion(nil, nil, NSError(domain: "BiometricError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Biometric credentials are missing or corrupted"]))
            return
        }
        
        let reason = "Sign in to PawFinder"
        let context = LAContext()
        context.localizedCancelTitle = "Use Password"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(email, password, nil)
                } else {
                    completion(nil, nil, error)
                }
            }
        }
    }
    
    // MARK: - Test Authentication
    func testAuthentication(completion: @escaping (Bool, Error?) -> Void) {
        guard isAvailable else {
            completion(false, NSError(domain: "BiometricError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Biometric authentication is not available"]))
            return
        }
        
        let context = LAContext()
        let reason = "Test biometric authentication"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    var biometricTypeName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Biometric"
        }
    }
    
    var biometricIcon: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default: return "person.badge.key.fill"
        }
    }
}

// MARK: - Auth View Model (Crash-Proof)
@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    @Published var shouldShowBiometricPrompt = false
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let biometricManager = BiometricManager.shared
    
    // Biometric properties
    var biometricType: LABiometryType {
        biometricManager.biometricType
    }
    
    var isBiometricEnabled: Bool {
        biometricManager.isEnabled
    }
    
    var biometricTypeName: String {
        biometricManager.biometricTypeName
    }
    
    var biometricIcon: String {
        biometricManager.biometricIcon
    }
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Authentication State
    private func setupAuthStateListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self = self else { return }
                
                self.isAuthenticated = user != nil
                
                if let user = user {
                    await self.loadCurrentUser(firebaseUser: user)
                } else {
                    self.currentUser = nil
                }
            }
        }
    }
    
    private func loadCurrentUser(firebaseUser: FirebaseAuth.User) async {
        do {
            let snapshot = try await db.collection("users").document(firebaseUser.uid).getDocument()
            
            if let data = snapshot.data(),
               let fullName = data["fullName"] as? String {
                self.currentUser = User(
                    firebaseUser: firebaseUser,
                    fullName: fullName,
                    profileImageURL: data["profileImageURL"] as? String,
                    phoneNumber: data["phoneNumber"] as? String
                )
            } else {
                self.currentUser = User(
                    firebaseUser: firebaseUser,
                    fullName: firebaseUser.displayName ?? "User"
                )
            }
        } catch {
            print("Error loading user data: \(error)")
            self.currentUser = User(
                firebaseUser: firebaseUser,
                fullName: firebaseUser.displayName ?? "User"
            )
        }
    }
    
    // MARK: - Biometric Methods (Crash-Proof)
    func enableBiometricAuthentication(email: String, password: String) {
        biometricManager.enableBiometric(email: email, password: password) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if success {
                    self.objectWillChange.send() // Trigger UI update
                    self.errorMessage = nil
                } else if let error = error {
                    self.errorMessage = error
                }
            }
        }
    }
    
    func disableBiometricAuthentication() {
        biometricManager.disableBiometric()
        self.objectWillChange.send() // Trigger UI update
    }
    
    func signInWithBiometrics() async -> Bool {
        return await withCheckedContinuation { continuation in
            biometricManager.authenticate { [weak self] email, password, error in
                guard let self = self else {
                    continuation.resume(returning: false)
                    return
                }
                
                if let email = email, let password = password {
                    // Attempt Firebase sign in
                    Task {
                        do {
                            let _ = try await self.auth.signIn(withEmail: email, password: password)
                            await MainActor.run {
                                self.errorMessage = nil
                            }
                            continuation.resume(returning: true)
                        } catch {
                            await MainActor.run {
                                self.errorMessage = "Sign-in failed. Please use email and password."
                            }
                            continuation.resume(returning: false)
                        }
                    }
                } else {
                    // Handle biometric error
                    if let error = error as? LAError {
                        switch error.code {
                        case .userCancel:
                            self.errorMessage = nil
                        case .biometryNotAvailable, .biometryNotEnrolled:
                            self.disableBiometricAuthentication()
                            self.errorMessage = "Biometric authentication is not available. Please use email and password."
                        default:
                            self.errorMessage = "Authentication failed. Please try again."
                        }
                    } else if let error = error {
                        self.errorMessage = error.localizedDescription
                    }
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    func testBiometricAuthentication() async -> Bool {
        return await withCheckedContinuation { continuation in
            biometricManager.testAuthentication { success, error in
                continuation.resume(returning: success)
            }
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
            
            if enableBiometric {
                enableBiometricAuthentication(email: email, password: password)
            }
            
        } catch {
            errorMessage = handleFirebaseError(error)
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
            
            let userData: [String: Any] = [
                "fullName": fullName,
                "email": email,
                "createdAt": Timestamp(date: Date()),
                "isEmailVerified": result.user.isEmailVerified
            ]
            
            try await db.collection("users").document(result.user.uid).setData(userData)
            
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = fullName
            try await changeRequest.commitChanges()
            
        } catch {
            errorMessage = handleFirebaseError(error)
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try auth.signOut()
            errorMessage = nil
        } catch {
            errorMessage = "Error signing out: \(error.localizedDescription)"
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
                    self.errorMessage = self.handleFirebaseError(error)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleFirebaseError(_ error: Error) -> String {
        if let authError = error as NSError? {
            switch authError.code {
            case AuthErrorCode.wrongPassword.rawValue:
                return "Incorrect password. Please try again."
            case AuthErrorCode.userNotFound.rawValue:
                return "No account found with this email address."
            case AuthErrorCode.userDisabled.rawValue:
                return "This account has been disabled."
            case AuthErrorCode.invalidEmail.rawValue:
                return "Please enter a valid email address."
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                return "An account already exists with this email address."
            case AuthErrorCode.weakPassword.rawValue:
                return "Password must be at least 6 characters long."
            case AuthErrorCode.networkError.rawValue:
                return "Network error. Please check your connection."
            default:
                return authError.localizedDescription
            }
        }
        return error.localizedDescription
    }
}
