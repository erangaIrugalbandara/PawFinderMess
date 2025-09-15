import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    let email: String
    let fullName: String
    let profileImageURL: String?
    let notificationGeneral: Bool
    let notificationLostPets: Bool
    let notificationMessages: Bool

    init(
        id: String? = nil,
        email: String,
        fullName: String,
        profileImageURL: String? = nil,
        notificationGeneral: Bool = true,
        notificationLostPets: Bool = false,
        notificationMessages: Bool = true
    ) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.profileImageURL = profileImageURL
        self.notificationGeneral = notificationGeneral
        self.notificationLostPets = notificationLostPets
        self.notificationMessages = notificationMessages
    }

    static func == (lhs: AppUser, rhs: AppUser) -> Bool {
        return lhs.id == rhs.id &&
            lhs.email == rhs.email &&
            lhs.fullName == rhs.fullName &&
            lhs.profileImageURL == rhs.profileImageURL &&
            lhs.notificationGeneral == rhs.notificationGeneral &&
            lhs.notificationLostPets == rhs.notificationLostPets &&
            lhs.notificationMessages == rhs.notificationMessages
    }
}
