import Foundation
import CoreLocation

struct LostPet: Identifiable, Codable {
    let id: String
    let ownerId: String // Make sure this field exists for user association
    let name: String
    let breed: String
    let species: PetSpecies
    let age: Int
    let color: String
    let size: PetSize
    let description: String
    let lastSeenLocation: LocationData
    let lastSeenDate: Date
    let contactInfo: ContactInfo
    let ownerName: String
    let photos: [String]
    let isActive: Bool
    let reportedDate: Date
    let rewardAmount: Double?
    let distinctiveFeatures: [String]
    let temperament: String
    
    var distanceFromUser: Double?
    
    // Computed coordinate for MapKit compatibility
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: lastSeenLocation.latitude,
            longitude: lastSeenLocation.longitude
        )
    }
}
