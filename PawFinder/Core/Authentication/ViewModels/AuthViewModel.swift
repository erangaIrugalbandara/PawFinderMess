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

// MARK: - Enhanced Biometric Manager (Crash-Proof)
class BiometricManager {
    static let shared = BiometricManager()
    
    private let biometricEnabledKey = "pawfinder_biometric_enabled_v3"
    private let storedEmailKey = "pawfinder_stored_email_v3"
    private let storedPasswordKey = "pawfinder_stored_password_v3"
    private let biometricPromptShownKey = "pawfinder_biometric_prompt_shown_v3"
    
    // Use a dedicated queue for biometric operations
    private let biometricQueue = DispatchQueue(label: "com.pawfinder.biometric", qos: .userInitiated)
    
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
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    var isEnabled: Bool {
        guard isAvailable else { return false }
        
        let enabled = UserDefaults.standard.bool(forKey: biometricEnabledKey)
        let hasEmail = UserDefaults.standard.string(forKey: storedEmailKey) != nil
        let hasPassword = UserDefaults.standard.string(forKey: storedPasswordKey) != nil
        
        return enabled && hasEmail && hasPassword
    }
    
    // MARK: - Safe Enable Biometric with Enhanced Error Handling
    func enableBiometric(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        // Validate inputs first
        guard !email.isEmpty && !password.isEmpty else {
            DispatchQueue.main.async {
                completion(false, "Email and password are required")
            }
            return
        }
        
        guard isAvailable else {
            DispatchQueue.main.async {
                completion(false, "Biometric authentication is not available on this device")
            }
            return
        }
        
        // Perform biometric operation on dedicated queue
        biometricQueue.async {
            let context = LAContext()
            
            // Configure context for better user experience
            context.localizedCancelTitle = "Cancel"
            context.localizedFallbackTitle = "Use Password"
            
            let reason = "Enable biometric authentication for PawFinder"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
                DispatchQueue.main.async {
                    guard let self = self else {
                        completion(false, "Internal error occurred")
                        return
                    }
                    
                    if success {
                        do {
                            // Store credentials safely with error handling
                            UserDefaults.standard.set(true, forKey: self.biometricEnabledKey)
                            UserDefaults.standard.set(email, forKey: self.storedEmailKey)
                            UserDefaults.standard.set(password, forKey: self.storedPasswordKey)
                            UserDefaults.standard.set(true, forKey: self.biometricPromptShownKey)
                            
                            // Force synchronization with error checking
                            let syncSuccess = UserDefaults.standard.synchronize()
                            
                            if syncSuccess {
                                completion(true, nil)
                                print("✅ Biometric enabled successfully for: \(email)")
                            } else {
                                // Rollback if sync failed
                                self.disableBiometric()
                                completion(false, "Failed to save biometric settings")
                            }
                        } catch {
                            completion(false, "Failed to save biometric settings: \(error.localizedDescription)")
                        }
                    } else {
                        let errorMessage = self.handleLAError(error)
                        completion(false, errorMessage)
                    }
                }
            }
        }
    }
    
    // MARK: - Enhanced Error Handling for LAError
    private func handleLAError(_ error: Error?) -> String? {
        guard let error = error else { return "Unknown error occurred" }
        
        if let laError = error as? LAError {
            switch laError.code {
            case .userCancel:
                return nil // Don't show error for user cancel
            case .biometryNotAvailable:
                return "Biometric authentication is not available on this device"
            case .biometryNotEnrolled:
                return "Please set up biometric authentication in Settings first"
            case .biometryLockout:
                return "Biometric authentication is temporarily locked. Please use device passcode"
            case .appCancel:
                return "Authentication was cancelled by the app"
            case .systemCancel:
                return "Authentication was cancelled by the system"
            case .passcodeNotSet:
                return "Please set up a device passcode first"
            case .authenticationFailed:
                return "Biometric authentication failed. Please try again"
            case .invalidContext:
                return "Authentication context is invalid"
            case .notInteractive:
                return "Authentication cannot be performed in non-interactive mode"
            default:
                return "Biometric authentication failed: \(laError.localizedDescription)"
            }
        } else {
            return "Authentication failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Safe Disable Biometric
    func disableBiometric() {
        UserDefaults.standard.removeObject(forKey: biometricEnabledKey)
        UserDefaults.standard.removeObject(forKey: storedEmailKey)
        UserDefaults.standard.removeObject(forKey: storedPasswordKey)
        UserDefaults.standard.synchronize()
        print("🔐 Biometric authentication disabled and cleaned up")
    }
    
    // MARK: - Safe Authenticate with Enhanced Error Handling
    func authenticate(completion: @escaping (String?, String?, Error?) -> Void) {
        guard isEnabled else {
            completion(nil, nil, NSError(domain: "BiometricError", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Biometric authentication is not enabled"]))
            return
        }
        
        guard let email = UserDefaults.standard.string(forKey: storedEmailKey),
              let password = UserDefaults.standard.string(forKey: storedPasswordKey),
              !email.isEmpty,
              !password.isEmpty else {
            
            // Clean up corrupted data
            disableBiometric()
            completion(nil, nil, NSError(domain: "BiometricError", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "Biometric credentials are missing or corrupted"]))
            return
        }
        
        biometricQueue.async {
            let context = LAContext()
            context.localizedCancelTitle = "Use Password"
            context.localizedFallbackTitle = "Enter Password"
            
            let reason = "Sign in to PawFinder"
            
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
    }
    
    // MARK: - Test Authentication with Better Error Handling
    func testAuthentication(completion: @escaping (Bool, Error?) -> Void) {
        guard isAvailable else {
            completion(false, NSError(domain: "BiometricError", code: 3,
                      userInfo: [NSLocalizedDescriptionKey: "Biometric authentication is not available"]))
            return
        }
        
        biometricQueue.async {
            let context = LAContext()
            context.localizedCancelTitle = "Cancel"
            
            let reason = "Test biometric authentication"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
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

// MARK: - Enhanced Auth View Model (Crash-Proof)
@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    @Published var shouldShowBiometricPrompt = false
    @Published var isBiometricAuthenticated = false
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let biometricManager = BiometricManager.shared
    
    // Operation state tracking
    @Published var isPerformingBiometricOperation = false
    
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
                    self.isBiometricAuthenticated = false
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
    
    // MARK: - Enhanced Biometric Methods with Crash Prevention
    func enableBiometricAuthentication(email: String, password: String) {
        guard !isPerformingBiometricOperation else {
            print("⚠️ Biometric operation already in progress")
            return
        }
        
        guard !email.isEmpty && !password.isEmpty else {
            DispatchQueue.main.async {
                self.errorMessage = "Email and password are required"
            }
            return
        }
        
        isPerformingBiometricOperation = true
        
        biometricManager.enableBiometric(email: email, password: password) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isPerformingBiometricOperation = false
                
                if success {
                    self.objectWillChange.send() // Trigger UI update
                    self.errorMessage = nil
                    print("✅ Biometric authentication enabled successfully")
                } else if let error = error {
                    self.errorMessage = error
                    print("❌ Failed to enable biometric: \(error)")
                }
            }
        }
    }
    
    func disableBiometricAuthentication() {
        guard !isPerformingBiometricOperation else {
            print("⚠️ Biometric operation already in progress")
            return
        }
        
        isPerformingBiometricOperation = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.biometricManager.disableBiometric()
            
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isPerformingBiometricOperation = false
                self.isBiometricAuthenticated = false
                self.objectWillChange.send() // Trigger UI update
                print("✅ Biometric authentication disabled")
            }
        }
    }
    
    func signInWithBiometrics() async -> Bool {
        guard !isPerformingBiometricOperation else {
            print("⚠️ Biometric operation already in progress")
            return false
        }
        
        isPerformingBiometricOperation = true
        
        let result = await withCheckedContinuation { continuation in
            biometricManager.authenticate { [weak self] email, password, error in
                guard let self = self else {
                    continuation.resume(returning: false)
                    return
                }
                
                if let email = email, let password = password {
                    // Attempt Firebase sign in
                    Task { @MainActor in
                        do {
                            let _ = try await self.auth.signIn(withEmail: email, password: password)
                            self.errorMessage = nil
                            self.isBiometricAuthenticated = true
                            self.isPerformingBiometricOperation = false
                            continuation.resume(returning: true)
                        } catch {
                            self.errorMessage = "Sign-in failed. Please use email and password."
                            self.isPerformingBiometricOperation = false
                            print("❌ Firebase sign-in failed: \(error)")
                            continuation.resume(returning: false)
                        }
                    }
                } else {
                    // Handle biometric error
                    Task { @MainActor in
                        self.isPerformingBiometricOperation = false
                        
                        if let error = error as? LAError {
                            switch error.code {
                            case .userCancel:
                                self.errorMessage = nil
                            case .biometryNotAvailable, .biometryNotEnrolled:
                                self.disableBiometricAuthentication()
                                self.errorMessage = "Biometric authentication is not available. Please use email and password."
                            case .biometryLockout:
                                self.errorMessage = "Biometric authentication is locked. Please use device passcode and try again."
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
        
        return result
    }
    
    func testBiometricAuthentication() async -> Bool {
        guard !isPerformingBiometricOperation else {
            print("⚠️ Biometric operation already in progress")
            return false
        }
        
        return await withCheckedContinuation { continuation in
            biometricManager.testAuthentication { success, error in
                if let error = error {
                    print("❌ Biometric test failed: \(error)")
                }
                continuation.resume(returning: success)
            }
        }
    }
    
    // MARK: - Firebase Authentication Methods with Enhanced Error Handling
    func signIn(email: String, password: String, enableBiometric: Bool = false) {
        guard !isLoading else { return }
        
        Task {
            await performSignIn(email: email, password: password, enableBiometric: enableBiometric)
        }
    }
    
    private func performSignIn(email: String, password: String, enableBiometric: Bool) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let _ = try await auth.signIn(withEmail: email, password: password)
            
            if enableBiometric && biometricManager.isAvailable {
                enableBiometricAuthentication(email: email, password: password)
            }
            
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
        guard !isPerformingBiometricOperation else {
            print("⚠️ Cannot sign out during biometric operation")
            return
        }
        
        do {
            try auth.signOut()
            isBiometricAuthenticated = false
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
                    print("❌ Password reset failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Enhanced Error Handling
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
