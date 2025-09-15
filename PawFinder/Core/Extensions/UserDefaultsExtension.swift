import Foundation

extension UserDefaults {
    private enum Keys {
        static let biometricEnabled = "biometric_enabled"
        static let userEmail = "user_email"
    }
    
    var isBiometricEnabled: Bool {
        get {
            return bool(forKey: Keys.biometricEnabled)
        }
        set {
            set(newValue, forKey: Keys.biometricEnabled)
        }
    }
    
    var savedUserEmail: String? {
        get {
            return string(forKey: Keys.userEmail)
        }
        set {
            set(newValue, forKey: Keys.userEmail)
        }
    }
}
