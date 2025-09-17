import Foundation
import SwiftUI
import FirebaseAuth

class MyReportsViewModel: ObservableObject {
    @Published var userPets: [LostPet] = []
    @Published var userSightings: [PetSighting] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService()
    
    func loadUserData(userId: String) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        print("🔄 Starting to load user data for userId: \(userId)")
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.loadUserPets(userId: userId)
            }
            
            group.addTask {
                await self.loadUserSightings(userId: userId)
            }
        }
        
        await MainActor.run {
            self.isLoading = false
            print("✅ Finished loading user data. Pets: \(self.userPets.count), Sightings: \(self.userSightings.count)")
        }
    }
    
    @MainActor
    private func loadUserPets(userId: String) async {
        print("🐾 Loading pets for user: \(userId)")
        
        do {
            userPets = try await firebaseService.fetchUserPets(userId: userId)
            print("✅ Successfully loaded \(userPets.count) pets for user")
            
            // Debug: Print pet details
            for pet in userPets {
                print("📋 Pet: \(pet.name) - Active: \(pet.isActive) - ID: \(pet.id)")
            }
        } catch {
            print("❌ Error loading user pets: \(error)")
            print("🔍 Error details: \(error.localizedDescription)")
            
            if let firestoreError = error as NSError? {
                print("🔍 Firestore error code: \(firestoreError.code)")
                print("🔍 Firestore error domain: \(firestoreError.domain)")
            }
            
            errorMessage = "Failed to load your pets. Please check your connection and try again."
            userPets = []
        }
    }
    
    @MainActor
    private func loadUserSightings(userId: String) async {
        print("👁️ Loading sightings for user: \(userId)")
        
        do {
            userSightings = try await firebaseService.fetchUserSightings(userId: userId)
            print("✅ Successfully loaded \(userSightings.count) sightings for user")
            
            // Debug: Print sighting details
            for sighting in userSightings {
                print("📋 Sighting: \(sighting.id) - Date: \(sighting.sightingDate)")
            }
        } catch {
            print("❌ Error loading user sightings: \(error)")
            print("🔍 Error details: \(error.localizedDescription)")
            
            // Don't overwrite pet error message if it exists
            if errorMessage == nil {
                errorMessage = "Failed to load your sightings. Please check your connection and try again."
            }
            userSightings = []
        }
    }
    
    @MainActor
    func markPetAsFound(petId: String) async {
        print("🔄 Marking pet as found: \(petId)")
        
        do {
            try await firebaseService.updatePetStatus(petId: petId, isActive: false)
            
            // Update local data
            if let index = userPets.firstIndex(where: { $0.id == petId }) {
                let updatedPet = userPets[index]
                userPets[index] = LostPet(
                    id: updatedPet.id,
                    ownerId: updatedPet.ownerId,
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
                    isActive: false, // This is what we're changing
                    reportedDate: updatedPet.reportedDate,
                    rewardAmount: updatedPet.rewardAmount,
                    distinctiveFeatures: updatedPet.distinctiveFeatures,
                    temperament: updatedPet.temperament
                )
                print("✅ Successfully updated local pet data")
            }
        } catch {
            print("❌ Error marking pet as found: \(error.localizedDescription)")
            errorMessage = "Failed to update pet status. Please try again."
        }
    }
    
    @MainActor
    func refreshData(userId: String) async {
        print("🔄 Refreshing data for user: \(userId)")
        await loadUserData(userId: userId)
    }
    
    // MARK: - Debug Helper
    func debugCurrentUser() {
        if let currentUser = Auth.auth().currentUser {
            print("🔍 Current Firebase user ID: \(currentUser.uid)")
            print("🔍 Current Firebase user email: \(currentUser.email ?? "No email")")
        } else {
            print("❌ No authenticated Firebase user found")
        }
    }
}
