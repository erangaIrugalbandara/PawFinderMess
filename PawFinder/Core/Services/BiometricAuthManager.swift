import LocalAuthentication
import SwiftUI

class BiometricAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var biometricType: LABiometryType = .none
    @Published var authenticationError: String?
    
    private let context = LAContext()
    
    init() {
        checkBiometricAvailability()
    }
    
    func checkBiometricAvailability() {
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
        }
    }
    
    func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use Password"
        
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            DispatchQueue.main.async {
                self.authenticationError = error?.localizedDescription ?? "Biometric authentication not available"
            }
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access PawFinder"
            )
            
            DispatchQueue.main.async {
                self.isAuthenticated = success
                self.authenticationError = nil
            }
            
            return success
        } catch {
            DispatchQueue.main.async {
                self.authenticationError = error.localizedDescription
                self.isAuthenticated = false
            }
            return false
        }
    }
    
    func authenticateWithDevicePasscode() async -> Bool {
        let context = LAContext()
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Authenticate to access PawFinder"
            )
            
            DispatchQueue.main.async {
                self.isAuthenticated = success
                self.authenticationError = nil
            }
            
            return success
        } catch {
            DispatchQueue.main.async {
                self.authenticationError = error.localizedDescription
                self.isAuthenticated = false
            }
            return false
        }
    }
    
    var biometricTypeName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Biometric Authentication"
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
            return "lock.fill"
        }
    }
}
