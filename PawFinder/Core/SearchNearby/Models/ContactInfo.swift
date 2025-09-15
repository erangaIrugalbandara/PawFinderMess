import Foundation

struct ContactInfo: Codable {
    let phone: String
    let email: String
    let preferredContactMethod: ContactMethod
}

enum ContactMethod: String, CaseIterable, Codable {
    case phone = "Phone"
    case email = "Email"
    case both = "Both"
}
