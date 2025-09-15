import Foundation

enum SightingConfidence: String, CaseIterable, Codable {
    case low = "Might be the pet"
    case medium = "Looks similar"
    case high = "Very confident"
    case certain = "Definitely this pet"
    
    var color: String {
        switch self {
        case .low: return "orange"
        case .medium: return "yellow"
        case .high: return "blue"
        case .certain: return "green"
        }
    }
}
