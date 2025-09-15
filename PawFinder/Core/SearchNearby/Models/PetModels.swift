//import Foundation
//import MapKit
//
//// MARK: - Lost Pet Model
//struct LostPet: Identifiable, Codable {
//    let id: String
//    let name: String
//    let breed: String
//    let species: PetSpecies
//    let age: Int
//    let color: String
//    let size: PetSize
//    let description: String
//    let lastSeenLocation: LocationData
//    let lastSeenDate: Date
//    let contactInfo: ContactInfo
//    let ownerName: String
//    let photos: [String] // Photo URLs or names
//    let isActive: Bool
//    let reportedDate: Date
//    let rewardAmount: Double?
//    let distinctiveFeatures: [String]
//    let temperament: String
//    
//    // Computed coordinate for MapKit
//    var coordinate: CLLocationCoordinate2D {
//        CLLocationCoordinate2D(
//            latitude: lastSeenLocation.latitude,
//            longitude: lastSeenLocation.longitude
//        )
//    }
//    
//    // Time since last seen
//    var timeSinceLastSeen: String {
//        let formatter = RelativeDateTimeFormatter()
//        formatter.unitsStyle = .full
//        return formatter.localizedString(for: lastSeenDate, relativeTo: Date())
//    }
//    
//    // Distance helper (will be calculated dynamically)
//    var distanceFromUser: Double = 0.0
//}
//
//// MARK: - Pet Species
//enum PetSpecies: String, CaseIterable, Codable {
//    case dog = "Dog"
//    case cat = "Cat"
//    case bird = "Bird"
//    case rabbit = "Rabbit"
//    case other = "Other"
//    
//    var emoji: String {
//        switch self {
//        case .dog: return "🐕"
//        case .cat: return "🐱"
//        case .bird: return "🦜"
//        case .rabbit: return "🐰"
//        case .other: return "🐾"
//        }
//    }
//    
//    var iconName: String {
//        switch self {
//        case .dog: return "dog.fill"
//        case .cat: return "cat.fill"
//        case .bird: return "bird.fill"
//        case .rabbit: return "hare.fill"
//        case .other: return "pawprint.fill"
//        }
//    }
//}
//
//// MARK: - Pet Size
//enum PetSize: String, CaseIterable, Codable {
//    case small = "Small"
//    case medium = "Medium"
//    case large = "Large"
//    case extraLarge = "Extra Large"
//    
//    var description: String {
//        switch self {
//        case .small: return "Under 25 lbs"
//        case .medium: return "25-60 lbs"
//        case .large: return "60-100 lbs"
//        case .extraLarge: return "Over 100 lbs"
//        }
//    }
//}
//
//// MARK: - Location Data
//struct LocationData: Codable {
//    let latitude: Double
//    let longitude: Double
//    let address: String
//    let city: String
//    let state: String
//    
//    var coordinate: CLLocationCoordinate2D {
//        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//    }
//}
//
//// MARK: - Contact Info
//struct ContactInfo: Codable {
//    let phone: String
//    let email: String
//    let preferredContactMethod: ContactMethod
//}
//
//enum ContactMethod: String, CaseIterable, Codable {
//    case phone = "Phone"
//    case email = "Email"
//    case both = "Both"
//}
//
//// MARK: - Pet Sighting
//struct PetSighting: Identifiable, Codable {
//    let id: String
//    let petId: String
//    let reporterName: String
//    let reporterContact: String
//    let location: LocationData
//    let sightingDate: Date
//    let description: String
//    let confidence: SightingConfidence
//    let photos: [String]
//    let isVerified: Bool
//    
//    var timeSinceSighting: String {
//        let formatter = RelativeDateTimeFormatter()
//        formatter.unitsStyle = .abbreviated
//        return formatter.localizedString(for: sightingDate, relativeTo: Date())
//    }
//}
//
//enum SightingConfidence: String, CaseIterable, Codable {
//    case low = "Might be the pet"
//    case medium = "Looks similar"
//    case high = "Very confident"
//    case certain = "Definitely this pet"
//    
//    var color: String {
//        switch self {
//        case .low: return "orange"
//        case .medium: return "yellow"
//        case .high: return "blue"
//        case .certain: return "green"
//        }
//    }
//}
//
//// MARK: - Map Annotation
//class PetAnnotation: NSObject, MKAnnotation {
//    let coordinate: CLLocationCoordinate2D
//    let title: String?
//    let subtitle: String?
//    let pet: LostPet
//    
//    init(pet: LostPet) {
//        self.pet = pet
//        self.coordinate = pet.coordinate
//        self.title = pet.name
//        self.subtitle = "\(pet.breed) • \(pet.timeSinceLastSeen)"
//        super.init()
//    }
//}
//
//struct PetWithDistance: Identifiable {
//    let pet: LostPet
//    let distanceFromUser: Double
//    
//    var id: String { pet.id }
//    
//    // Convenience properties
//    var name: String { pet.name }
//    var breed: String { pet.breed }
//    var species: PetSpecies { pet.species }
//    var coordinate: CLLocationCoordinate2D { pet.coordinate }
//}
