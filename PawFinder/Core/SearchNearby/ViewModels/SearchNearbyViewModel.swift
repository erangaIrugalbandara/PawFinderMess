import Foundation
import MapKit
import CoreLocation

class SearchNearbyViewModel: NSObject, ObservableObject {
    // Singleton instance
    static let shared = SearchNearbyViewModel()

    @Published var lostPets: [LostPet] = []
    @Published var pets: [LostPet] = []
    @Published var filteredPets: [LostPet] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userLocation: CLLocation?
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    @Published var selectedPet: LostPet?
    @Published var showingPetDetail = false
    @Published var showingSightingReport = false
    @Published var showingSightingSuccess = false

    // Filter properties
    @Published var searchRadius: Double = 10.0 // km
    @Published var selectedSpecies: PetSpecies?
    @Published var selectedSizes: Set<PetSize> = []
    @Published var showRecentOnly = false
    @Published var showWithRewardOnly = false

    private let locationManager = CLLocationManager()
    private let firebaseService = FirebaseService()

    private override init() {
        super.init()
        setupLocationManager()
        loadPetsFromDatabase()
    }

    // MARK: - Setup Location Manager
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func centerMapOnUser() {
        guard let location = userLocation else { return }

        mapRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }

    // Fixed method name to match the usage in SearchNearbyView
    func selectPet(_ pet: LostPet) {
        selectedPet = pet
        showingPetDetail = true
    }

    func showPetDetail(_ pet: LostPet) {
        selectedPet = pet
        showingPetDetail = true
    }

    func showSightingReport(for pet: LostPet) {
        selectedPet = pet
        showingSightingReport = true
    }

    func reportSighting(for pet: LostPet) {
        print("🎯 Sighting reported for pet: \(pet.name)")
        // Here you would typically send the sighting data to your backend
        // The success notification is now handled within SightingReportView
    }

    // MARK: - Data Loading
    func loadPetsFromDatabase() {
        isLoading = true
        errorMessage = nil
        
        print("🔄 Starting to load pets from database...")
        
        Task {
            do {
                // Use the new fetchAllLostPets method for better debugging
                let fetchedPets = try await firebaseService.fetchAllLostPets()
                
                DispatchQueue.main.async {
                    print("✅ Successfully loaded \(fetchedPets.count) pets from database")
                    self.lostPets = fetchedPets
                    self.pets = fetchedPets
                    self.applyFilters()
                    self.isLoading = false
                    
                    // Debug print
                    for pet in fetchedPets {
                        print("🐾 Pet: \(pet.name) at \(pet.lastSeenLocation.address)")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("❌ Failed to load pets: \(error.localizedDescription)")
                    self.errorMessage = "Failed to load pets: \(error.localizedDescription)"
                    self.isLoading = false
                    // Load sample data as fallback
                    self.loadSampleData()
                }
            }
        }
    }

    private func loadSampleData() {
        print("📦 Loading sample data as fallback...")
        
        let samplePets = [
            LostPet(
                id: "sample-1",
                name: "Max",
                breed: "Golden Retriever",
                species: .dog,
                age: 3,
                color: "Golden",
                size: .large,
                description: "Friendly golden retriever, very social",
                lastSeenLocation: LocationData(
                    latitude: 37.7749,
                    longitude: -122.4194,
                    address: "San Francisco, CA",
                    city: "San Francisco",
                    state: "CA"
                ),
                lastSeenDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                contactInfo: ContactInfo(
                    phone: "555-0123",
                    email: "owner@example.com",
                    preferredContactMethod: .phone
                ),
                ownerName: "John Doe",
                photos: [],
                isActive: true,
                reportedDate: Date(),
                rewardAmount: 500,
                distinctiveFeatures: ["White patch on chest", "Friendly with children"],
                temperament: "Very friendly"
            ),
            LostPet(
                id: "sample-2",
                name: "Luna",
                breed: "Husky",
                species: .dog,
                age: 2,
                color: "Gray and White",
                size: .medium,
                description: "Energetic husky with blue eyes",
                lastSeenLocation: LocationData(
                    latitude: 37.7849,
                    longitude: -122.4094,
                    address: "Oakland, CA",
                    city: "Oakland",
                    state: "CA"
                ),
                lastSeenDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                contactInfo: ContactInfo(
                    phone: "555-0456",
                    email: "owner2@example.com",
                    preferredContactMethod: .phone
                ),
                ownerName: "Jane Smith",
                photos: [],
                isActive: true,
                reportedDate: Date(),
                rewardAmount: 200,
                distinctiveFeatures: ["Blue eyes", "Small scar on left ear"],
                temperament: "Shy"
            )
        ]
        
        self.lostPets = samplePets
        self.pets = samplePets
        self.applyFilters()
        print("📦 Sample data loaded: \(samplePets.count) pets")
    }

    func updateSearchRadius(_ radius: Double) {
        searchRadius = radius
        applyFilters()
    }

    func updateSpeciesFilter(_ species: PetSpecies?) {
        selectedSpecies = species
        applyFilters()
    }

    func updateSizeFilter(_ sizes: Set<PetSize>) {
        selectedSizes = sizes
        applyFilters()
    }

    func updateRecentFilter(_ showRecent: Bool) {
        showRecentOnly = showRecent
        applyFilters()
    }

    func updateRewardFilter(_ showWithReward: Bool) {
        showWithRewardOnly = showWithReward
        applyFilters()
    }

    private func applyFilters() {
        filteredPets = pets.filter { pet in
            // Species filter
            if let selectedSpecies = selectedSpecies, pet.species != selectedSpecies {
                return false
            }

            // Size filter
            if !selectedSizes.isEmpty && !selectedSizes.contains(pet.size) {
                return false
            }

            // Recent filter (last 7 days)
            if showRecentOnly {
                let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                if pet.lastSeenDate < sevenDaysAgo {
                    return false
                }
            }

            // Reward filter
            if showWithRewardOnly && (pet.rewardAmount == nil || pet.rewardAmount == 0) {
                return false
            }

            // Distance filter (if user location is available)
            if let userLocation = userLocation {
                let petLocation = CLLocation(
                    latitude: pet.lastSeenLocation.latitude,
                    longitude: pet.lastSeenLocation.longitude
                )
                let distance = userLocation.distance(from: petLocation) / 1000 // Convert to km
                if distance > searchRadius {
                    return false
                }
            }

            return true
        }
        
        print("🔍 Applied filters: \(filteredPets.count) pets match criteria")
    }
}

// MARK: - CLLocationManagerDelegate
extension SearchNearbyViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
        
        mapRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        applyFilters()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
    }
}
