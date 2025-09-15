import Foundation
import SwiftUI

class MyReportsViewModel: ObservableObject {
    @Published var userPets: [LostPet] = []
    @Published var userSightings: [PetSighting] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService()
    
    func loadUserData(userId: String) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.loadUserPets(userId: userId)
            }
            
            group.addTask {
                await self.loadUserSightings(userId: userId)
            }
        }
    }
    
    @MainActor
    private func loadUserPets(userId: String) async {
        isLoading = true
        
        do {
            userPets = try await firebaseService.fetchUserPets(userId: userId)
        } catch {
            errorMessage = "Failed to load your pets: \(error.localizedDescription)"
            // Load sample data for demo purposes
            loadSamplePets()
        }
        
        isLoading = false
    }
    
    @MainActor
    private func loadUserSightings(userId: String) async {
        do {
            userSightings = try await firebaseService.fetchUserSightings(userId: userId)
        } catch {
            errorMessage = "Failed to load your sightings: \(error.localizedDescription)"
            // Load sample data for demo purposes
            loadSampleSightings()
        }
    }
    
    @MainActor
    func markPetAsFound(petId: String) async {
        do {
            try await firebaseService.updatePetStatus(petId: petId, isActive: false)
            
            // Update local data
            if let index = userPets.firstIndex(where: { $0.id == petId }) {
                var updatedPet = userPets[index]
                userPets[index] = LostPet(
                    id: updatedPet.id,
                    name: updatedPet.name,
                    breed: updatedPet.breed,
                    species: updatedPet.species,
                    age: updatedPet.age,
                    color: updatedPet.color,
                    size: updatedPet.size,
                    description: updatedPet.description,
                    lastSeenLocation: updatedPet.lastSeenLocation,
                    lastSeenDate: updatedPet.lastSeenDate,
                    contactInfo: updatedPet.contactInfo,
                    ownerName: updatedPet.ownerName,
                    photos: updatedPet.photos,
                    isActive: false,
                    reportedDate: updatedPet.reportedDate,
                    rewardAmount: updatedPet.rewardAmount,
                    distinctiveFeatures: updatedPet.distinctiveFeatures,
                    temperament: updatedPet.temperament
                )
            }
        } catch {
            errorMessage = "Failed to update pet status: \(error.localizedDescription)"
        }
    }
    
    // Sample data for demo purposes
    @MainActor
    private func loadSamplePets() {
        userPets = [
            LostPet(
                id: "1",
                name: "Tommy",
                breed: "Golden Retriever",
                species: .dog,
                age: 3,
                color: "Golden",
                size: .large,
                description: "Friendly dog with a red collar",
                lastSeenLocation: LocationData(
                    latitude: 37.7749,
                    longitude: -122.4194,
                    address: "Golden Gate Park, San Francisco",
                    city: "San Francisco",
                    state: "CA"
                ),
                lastSeenDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                contactInfo: ContactInfo(
                    phone: "+1234567890",
                    email: "owner@example.com",
                    preferredContactMethod: .phone
                ),
                ownerName: "John Doe",
                photos: ["https://example.com/tommy.jpg"],
                isActive: true,
                reportedDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                rewardAmount: 500.0,
                distinctiveFeatures: ["Red collar", "White patch on chest"],
                temperament: "Friendly"
            ),
            LostPet(
                id: "2",
                name: "Max",
                breed: "German Shepherd",
                species: .dog,
                age: 5,
                color: "Brown and Black",
                size: .large,
                description: "Well-trained police dog",
                lastSeenLocation: LocationData(
                    latitude: 37.7849,
                    longitude: -122.4094,
                    address: "Mission District, San Francisco",
                    city: "San Francisco",
                    state: "CA"
                ),
                lastSeenDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                contactInfo: ContactInfo(
                    phone: "+1987654321",
                    email: "owner2@example.com",
                    preferredContactMethod: .both
                ),
                ownerName: "Jane Smith",
                photos: ["https://example.com/max.jpg"],
                isActive: false,
                reportedDate: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
                rewardAmount: 1000.0,
                distinctiveFeatures: ["Blue collar with badge", "Scar on left ear"],
                temperament: "Calm and obedient"
            )
        ]
    }
    
    @MainActor
    private func loadSampleSightings() {
        userSightings = [
            PetSighting(
                id: "s1",
                petId: "pet1",
                reporterName: "Current User",
                reporterContact: "user@example.com",
                location: LocationData(
                    latitude: 37.7649,
                    longitude: -122.4194,
                    address: "Dolores Park, San Francisco",
                    city: "San Francisco",
                    state: "CA"
                ),
                sightingDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                description: "Saw a husky-like dog running near the playground area",
                confidence: .medium,
                photos: ["https://example.com/sighting1.jpg"],
                isVerified: false
            ),
            PetSighting(
                id: "s2",
                petId: "pet2",
                reporterName: "Current User",
                reporterContact: "user@example.com",
                location: LocationData(
                    latitude: 37.7749,
                    longitude: -122.4294,
                    address: "Castro District, San Francisco",
                    city: "San Francisco",
                    state: "CA"
                ),
                sightingDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
                description: "Persian cat sitting under a parked car, looked well-fed",
                confidence: .high,
                photos: ["https://example.com/sighting2.jpg"],
                isVerified: true
            )
        ]
    }
}
