import Foundation

enum PetSpecies: String, CaseIterable, Codable {
    case dog = "Dog"
    case cat = "Cat"
    case bird = "Bird"
    case rabbit = "Rabbit"
    case other = "Other"
    
    var emoji: String {
        switch self {
        case .dog: return "🐕"
        case .cat: return "🐱"
        case .bird: return "🦜"
        case .rabbit: return "🐰"
        case .other: return "🐾"
        }
    }
    
    var iconName: String {
        switch self {
        case .dog: return "dog.fill"
        case .cat: return "cat.fill"
        case .bird: return "bird.fill"
        case .rabbit: return "hare.fill"
        case .other: return "pawprint.fill"
        }
    }
}
