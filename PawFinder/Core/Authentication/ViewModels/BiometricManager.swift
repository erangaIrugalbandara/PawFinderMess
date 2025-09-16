//import LocalAuthentication
//import Foundation
//
//class BiometricManager: ObservableObject {
//    private let context = LAContext()
//    
//    enum BiometricType {
//        case none
//        case touchID
//        case faceID
//        case opticID
//    }
//    
//    enum BiometricError: LocalizedError {
//        case biometryNotAvailable
//        case biometryNotEnrolled
//        case biometryLockout
//        case authenticationFailed
//        case userCancel
//        case userFallback
//        case systemCancel
//        case passcodeNotSet
//        case unknown
//        
//        var errorDescription: String? {
//            switch self {
//            case .biometryNotAvailable:
//                return "Biometric authentication is not available on this device"
//            case .biometryNotEnrolled:
//                return "No biometric data is enrolled on this device"
//            case .biometryLockout:
//                return "Biometric authentication is locked. Please use passcode"
//            case .authenticationFailed:
//                return "Biometric authentication failed"
//            case .userCancel:
//                return "Authentication was cancelled by user"
//            case .userFallback:
//                return "User chose to use passcode instead"
//            case .systemCancel:
//                return "Authentication was cancelled by system"
//            case .passcodeNotSet:
//                return "Passcode is not set on this device"
//            case .unknown:
//                return "An unknown error occurred"
//            }
//        }
//    }
//    
//    func getBiometricType() -> BiometricType {
//        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
//            return .none
//        }
//        
//        switch context.biometryType {
//        case .none:
//            return .none
//        case .touchID:
//            return .touchID
//        case .faceID:
//            return .faceID
//        case .opticID:
//            return .opticID
//        @unknown default:
//            return .none
//        }
//    }
//    
//    func isBiometricAvailable() -> Bool {
//        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
//    }
//    
//    func authenticateUser(completion: @escaping (Result<Bool, BiometricError>) -> Void) {
//        guard isBiometricAvailable() else {
//            completion(.failure(.biometryNotAvailable))
//            return
//        }
//        
//        let reason = "Use biometric authentication to access your account"
//        
//        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
//            DispatchQueue.main.async {
//                if success {
//                    completion(.success(true))
//                } else {
//                    if let error = authenticationError as? LAError {
//                        completion(.failure(self.mapLAError(error)))
//                    } else {
//                        completion(.failure(.unknown))
//                    }
//                }
//            }
//        }
//    }
//    
//    private func mapLAError(_ error: LAError) -> BiometricError {
//        switch error.code {
//        case .biometryNotAvailable:
//            return .biometryNotAvailable
//        case .biometryNotEnrolled:
//            return .biometryNotEnrolled
//        case .biometryLockout:
//            return .biometryLockout
//        case .authenticationFailed:
//            return .authenticationFailed
//        case .userCancel:
//            return .userCancel
//        case .userFallback:
//            return .userFallback
//        case .systemCancel:
//            return .systemCancel
//        case .passcodeNotSet:
//            return .passcodeNotSet
//        default:
//            return .unknown
//        }
//    }
//}
