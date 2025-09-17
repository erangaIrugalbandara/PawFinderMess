import Foundation
import CoreLocation

struct PetSighting: Identifiable, Codable {
    let id: String
    let petId: String
    let reporterId: String // Make sure this field exists for user association
    let reporterName: String
    let reporterContact: String
    let location: LocationData
    let sightingDate: Date
    let description: String
    let confidence: SightingConfidence
    let photos: [String]
    let isVerified: Bool
    
    var timeSinceSighting: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: sightingDate, relativeTo: Date())
    }
}
