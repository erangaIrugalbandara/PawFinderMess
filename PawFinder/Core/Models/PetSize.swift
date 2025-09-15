import Foundation

enum PetSize: String, CaseIterable, Codable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"
    
    var description: String {
        switch self {
        case .small: return "Under 25 lbs"
        case .medium: return "25-60 lbs"
        case .large: return "60-100 lbs"
        case .extraLarge: return "Over 100 lbs"
        }
    }
}
