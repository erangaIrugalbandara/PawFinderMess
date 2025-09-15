import Foundation
import CoreLocation

struct LocationData: Codable {
    let latitude: Double
    let longitude: Double
    let address: String
    let city: String
    let state: String
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
