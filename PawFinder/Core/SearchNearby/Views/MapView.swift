import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var pets: [LostPet]
    var userLocation: CLLocation?
    var onPetSelected: (LostPet) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)
        
        // Remove existing annotations (except user location)
        uiView.removeAnnotations(uiView.annotations.filter { !($0 is MKUserLocation) })
        
        // Create annotations from pets
        let annotations = pets.map { pet in
            PetAnnotation(
                coordinate: CLLocationCoordinate2D(
                    latitude: pet.lastSeenLocation.latitude,
                    longitude: pet.lastSeenLocation.longitude
                ),
                title: pet.name,
                subtitle: "\(pet.breed) • Missing"
            )
        }
        uiView.addAnnotations(annotations)
        
        // Store pets in coordinator for selection
        context.coordinator.pets = pets
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var pets: [LostPet] = []

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location annotation
            if annotation is MKUserLocation {
                return nil
            }
            
            guard let petAnnotation = annotation as? PetAnnotation else { return nil }

            let identifier = "PetAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            } else {
                annotationView?.annotation = annotation
            }

            // Find the corresponding pet for this annotation
            if let pet = pets.first(where: {
                $0.lastSeenLocation.latitude == petAnnotation.coordinate.latitude &&
                $0.lastSeenLocation.longitude == petAnnotation.coordinate.longitude
            }) {
                // Customize the pin based on pet species
                annotationView?.markerTintColor = pet.species == .dog ? .blue : .orange
                annotationView?.glyphText = pet.species.emoji
                
                // Add pet photo if available
                if let firstPhoto = pet.photos.first, !firstPhoto.isEmpty {
                    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                    imageView.backgroundColor = .systemGray5
                    imageView.layer.cornerRadius = 20
                    imageView.clipsToBounds = true
                    imageView.contentMode = .scaleAspectFill
                    
                    // Load image from URL if it's a valid URL
                    if let url = URL(string: firstPhoto) {
                        Task {
                            do {
                                let (data, _) = try await URLSession.shared.data(from: url)
                                if let image = UIImage(data: data) {
                                    DispatchQueue.main.async {
                                        imageView.image = image
                                    }
                                }
                            } catch {
                                // If loading fails, show a placeholder
                                DispatchQueue.main.async {
                                    imageView.image = UIImage(systemName: "pawprint.fill")
                                }
                            }
                        }
                    } else {
                        // If not a URL, try to load as asset name
                        imageView.image = UIImage(named: firstPhoto) ?? UIImage(systemName: "pawprint.fill")
                    }
                    
                    annotationView?.leftCalloutAccessoryView = imageView
                }
            }

            return annotationView
        }

        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let petAnnotation = view.annotation as? PetAnnotation else { return }
            
            // Find the corresponding pet
            if let pet = pets.first(where: {
                $0.lastSeenLocation.latitude == petAnnotation.coordinate.latitude &&
                $0.lastSeenLocation.longitude == petAnnotation.coordinate.longitude
            }) {
                parent.onPetSelected(pet)
            }
        }
    }
}
