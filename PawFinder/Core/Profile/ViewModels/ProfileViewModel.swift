import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit

class ProfileViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var email: String = ""
    @Published var profileImageURL: String = ""
    @Published var notificationGeneral: Bool = true
    @Published var notificationLostPets: Bool = false
    @Published var notificationMessages: Bool = true
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var isSaved: Bool = false

    private var db = Firestore.firestore()
    private var auth = Auth.auth()
    private var firebaseService = FirebaseService()

    // Load user profile and notification settings from Firestore
    func fetchProfile() {
        guard let uid = auth.currentUser?.uid else { return }
        isLoading = true
        db.collection("users").document(uid).getDocument { [weak self] snap, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                if let data = snap?.data() {
                    self?.userName = data["fullName"] as? String ?? ""
                    self?.email = data["email"] as? String ?? ""
                    self?.profileImageURL = data["profileImageURL"] as? String ?? ""
                    self?.notificationGeneral = data["notificationGeneral"] as? Bool ?? true
                    self?.notificationLostPets = data["notificationLostPets"] as? Bool ?? false
                    self?.notificationMessages = data["notificationMessages"] as? Bool ?? true
                }
            }
        }
    }

    // Upload profile image to Firebase Storage and update user document
    func uploadProfileImage(_ image: UIImage) async throws {
        guard let uid = auth.currentUser?.uid else {
            throw ProfileError.userNotAuthenticated
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        do {
            // Upload image to Firebase Storage
            let imageURL = try await firebaseService.uploadProfileImage(image, userId: uid)
            
            // Update user document with new image URL
            try await db.collection("users").document(uid).updateData([
                "profileImageURL": imageURL
            ])
            
            DispatchQueue.main.async {
                self.profileImageURL = imageURL
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Failed to upload profile image: \(error.localizedDescription)"
            }
            throw error
        }
    }

    // Save profile changes to Firestore (and Auth for sensitive data)
    func saveProfile(newName: String, newPassword: String?, notificationGeneral: Bool, notificationLostPets: Bool, notificationMessages: Bool, completion: @escaping (Bool) -> Void) {
        guard let uid = auth.currentUser?.uid else { completion(false); return }
        isLoading = true
        
        var fields: [String: Any] = [
            "fullName": newName,
            "notificationGeneral": notificationGeneral,
            "notificationLostPets": notificationLostPets,
            "notificationMessages": notificationMessages
        ]
        
        // Only update profileImageURL if we have one
        if !profileImageURL.isEmpty {
            fields["profileImageURL"] = profileImageURL
        }
        
        db.collection("users").document(uid).updateData(fields) { [weak self] err in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let err = err {
                    self?.errorMessage = err.localizedDescription
                    completion(false)
                } else {
                    self?.userName = newName
                    self?.notificationGeneral = notificationGeneral
                    self?.notificationLostPets = notificationLostPets
                    self?.notificationMessages = notificationMessages
                    self?.isSaved = true
                    completion(true)
                }
            }
        }
        
        // Password update
        if let newPassword = newPassword, !newPassword.isEmpty {
            auth.currentUser?.updatePassword(to: newPassword) { [weak self] err in
                DispatchQueue.main.async {
                    if let err = err {
                        self?.errorMessage = "Password update error: \(err.localizedDescription)"
                    }
                }
            }
        }
    }

    // Optionally add an email update
    func updateEmail(newEmail: String, completion: @escaping (Bool) -> Void) {
        guard let user = auth.currentUser else { completion(false); return }
        user.updateEmail(to: newEmail) { [weak self] err in
            DispatchQueue.main.async {
                if let err = err {
                    self?.errorMessage = err.localizedDescription
                    completion(false)
                } else {
                    self?.email = newEmail
                    completion(true)
                }
            }
        }
    }
}

enum ProfileError: LocalizedError {
    case userNotAuthenticated
    case imageUploadFailed
    case profileUpdateFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .imageUploadFailed:
            return "Failed to upload profile image"
        case .profileUpdateFailed:
            return "Failed to update profile"
        }
    }
}
