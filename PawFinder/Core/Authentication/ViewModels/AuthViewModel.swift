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

// MARK: - Simple Biometric Manager
class BiometricAuthManager: ObservableObject {
    static let shared = BiometricAuthManager()
    
    private let biometricEnabledKey = "pawfinder_biometric_enabled"
    private let storedEmailKey = "pawfinder_biometric_email"
    private let storedPasswordKey = "pawfinder_biometric_password"
    
    init() {}
    
    // MARK: - Biometric Availability
    var biometricType: LABiometryType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        return context.biometryType
    }
    
    var isAvailable: Bool {
        biometricType != .none
    }
    
    var biometricName: String {
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
    
    // MARK: - Biometric State
    var isEnabled: Bool {
        guard isAvailable else { return false }
        
        let enabled = UserDefaults.standard.bool(forKey: biometricEnabledKey)
        let hasEmail = UserDefaults.standard.string(forKey: storedEmailKey) != nil
        let hasPassword = UserDefaults.standard.string(forKey: storedPasswordKey) != nil
        
        return enabled && hasEmail && hasPassword
    }
    
    // MARK: - Enable Biometric
    func enableBiometric(email: String, password: String) async -> (success: Bool, error: String?) {
        guard isAvailable else {
            return (false, "Biometric authentication is not available")
        }
        
        guard !email.isEmpty && !password.isEmpty else {
            return (false, "Email and password are required")
        }
        
        return await withCheckedContinuation { continuation in
            let context = LAContext()
            let reason = "Enable \(biometricName) for PawFinder"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        UserDefaults.standard.set(true, forKey: self.biometricEnabledKey)
                        UserDefaults.standard.set(email, forKey: self.storedEmailKey)
                        UserDefaults.standard.set(password, forKey: self.storedPasswordKey)
                        UserDefaults.standard.synchronize()
                        
                        continuation.resume(returning: (true, nil))
                    } else {
                        let errorMessage = self.handleBiometricError(error)
                        continuation.resume(returning: (false, errorMessage))
                    }
                }
            }
        }
    }
    
    // MARK: - Disable Biometric
    func disableBiometric() {
        UserDefaults.standard.removeObject(forKey: biometricEnabledKey)
        UserDefaults.standard.removeObject(forKey: storedEmailKey)
        UserDefaults.standard.removeObject(forKey: storedPasswordKey)
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Authenticate with Biometric
    func authenticateWithBiometric() async -> (email: String?, password: String?, error: String?) {
        guard isEnabled else {
            return (nil, nil, "Biometric authentication is not enabled")
        }
        
        guard let email = UserDefaults.standard.string(forKey: storedEmailKey),
              let password = UserDefaults.standard.string(forKey: storedPasswordKey) else {
            disableBiometric() // Clean up corrupted data
            return (nil, nil, "Biometric credentials not found")
        }
        
        return await withCheckedContinuation { continuation in
            let context = LAContext()
            let reason = "Sign in to PawFinder"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        continuation.resume(returning: (email, password, nil))
                    } else {
                        let errorMessage = self.handleBiometricError(error)
                        continuation.resume(returning: (nil, nil, errorMessage))
                    }
                }
            }
        }
    }
    
    // MARK: - Test Biometric
    func testBiometric() async -> (success: Bool, error: String?) {
        guard isAvailable else {
            return (false, "Biometric authentication is not available")
        }
        
        return await withCheckedContinuation { continuation in
            let context = LAContext()
            let reason = "Test biometric authentication"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        continuation.resume(returning: (true, nil))
                    } else {
                        let errorMessage = self.handleBiometricError(error)
                        continuation.resume(returning: (false, errorMessage))
                    }
                }
            }
        }
    }
    
    // MARK: - Error Handling
    private func handleBiometricError(_ error: Error?) -> String? {
        guard let error = error as? LAError else {
            return "Biometric authentication failed"
        }
        
        switch error.code {
        case .userCancel:
            return nil // User cancelled - don't show error
        case .biometryNotAvailable:
            return "Biometric authentication is not available"
        case .biometryNotEnrolled:
            return "Please set up biometric authentication in Settings"
        case .biometryLockout:
            return "Biometric authentication is locked. Please use device passcode"
        case .authenticationFailed:
            return "Biometric authentication failed. Please try again"
        default:
            return "Biometric authentication failed"
        }
    }
}

// MARK: - Clean Auth View Model
@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let biometricManager = BiometricAuthManager.shared
    
    // MARK: - Biometric Properties
    var biometricType: LABiometryType {
        biometricManager.biometricType
    }
    
    var isBiometricAvailable: Bool {
        biometricManager.isAvailable
    }
    
    var isBiometricEnabled: Bool {
        biometricManager.isEnabled
    }
    
    var biometricName: String {
        biometricManager.biometricName
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
    
    // MARK: - Authentication State Management
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
    
    // MARK: - Firebase Authentication Methods
    func signIn(email: String, password: String) {
        guard !isLoading else { return }
        
        Task {
            await performSignIn(email: email, password: password)
        }
    }
    
    private func performSignIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let _ = try await auth.signIn(withEmail: email, password: password)
            print("✅ Sign-in successful")
        } catch {
            errorMessage = handleFirebaseError(error)
            print("❌ Sign-in failed: \(error)")
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, fullName: String) {
        guard !isLoading else { return }
        
        Task {
            await performSignUp(email: email, password: password, fullName: fullName)
        }
    }
    
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
            
            print("✅ User created successfully")
            
        } catch {
            errorMessage = handleFirebaseError(error)
            print("❌ Sign-up failed: \(error)")
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try auth.signOut()
            errorMessage = nil
            print("✅ User signed out successfully")
        } catch {
            errorMessage = "Error signing out: \(error.localizedDescription)"
            print("❌ Sign-out failed: \(error)")
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
    
    // MARK: - Biometric Methods
    func enableBiometric(email: String, password: String) async -> (success: Bool, error: String?) {
        return await biometricManager.enableBiometric(email: email, password: password)
    }
    
    func disableBiometric() {
        biometricManager.disableBiometric()
        objectWillChange.send() // Trigger UI update
    }
    
    func signInWithBiometric() async -> Bool {
        let result = await biometricManager.authenticateWithBiometric()
        
        if let email = result.email, let password = result.password {
            // Sign in with Firebase
            do {
                let _ = try await auth.signIn(withEmail: email, password: password)
                return true
            } catch {
                await MainActor.run {
                    self.errorMessage = "Sign-in failed. Please use email and password."
                }
                return false
            }
        } else if let error = result.error {
            await MainActor.run {
                self.errorMessage = error
            }
        }
        
        return false
    }
    
    func testBiometric() async -> (success: Bool, error: String?) {
        return await biometricManager.testBiometric()
    }
    
    // MARK: - Error Handling
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
            case AuthErrorCode.tooManyRequests.rawValue:
                return "Too many requests. Please try again later."
            case AuthErrorCode.operationNotAllowed.rawValue:
                return "This sign-in method is not enabled."
            default:
                return authError.localizedDescription
            }
        }
        return error.localizedDescription
    }
    
    // MARK: - Utility Methods
    func clearErrorMessage() {
        errorMessage = nil
    }
    
    func refreshCurrentUser() async {
        if let firebaseUser = auth.currentUser {
            await loadCurrentUser(firebaseUser: firebaseUser)
        }
    }
}
