import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit
import CoreLocation

class FirebaseService: ObservableObject {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    func saveLostPet(_ pet: LostPet) async throws {
        try await db.collection("lostPets").document(pet.id).setData(from: pet)
    }
    
    func submitLostPetReport(report: LostPet) async throws {
        // Use setData(from:) to ensure proper Codable encoding
        try await db.collection("lostPets").document(report.id).setData(from: report)
    }
    
    func fetchLostPets() async throws -> [LostPet] {
        let snapshot = try await db.collection("lostPets")
            .whereField("isActive", isEqualTo: true)
            .order(by: "reportedDate", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: LostPet.self)
        }
    }
    
    func fetchLostPets(nearLocation: LocationData, radius: Double) async throws -> [LostPet] {
        let snapshot = try await db.collection("lostPets")
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        
        let pets = try snapshot.documents.compactMap { document -> LostPet? in
            do {
                return try document.data(as: LostPet.self)
            } catch {
                print("Error decoding pet document \(document.documentID): \(error)")
                return nil
            }
        }
        
        return pets.filter { pet in
            let distance = calculateDistance(
                from: CLLocationCoordinate2D(latitude: nearLocation.latitude, longitude: nearLocation.longitude),
                to: CLLocationCoordinate2D(latitude: pet.lastSeenLocation.latitude, longitude: pet.lastSeenLocation.longitude)
            )
            return distance <= radius * 1000 // Convert km to meters
        }
    }

    func fetchAllLostPets() async throws -> [LostPet] {
        let snapshot = try await db.collection("lostPets")
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        
        print("🔍 Found \(snapshot.documents.count) documents in lostPets collection")
        
        let pets = try snapshot.documents.compactMap { document -> LostPet? in
            do {
                let pet = try document.data(as: LostPet.self)
                print("✅ Successfully decoded pet: \(pet.name)")
                return pet
            } catch {
                print("❌ Error decoding pet document \(document.documentID): \(error)")
                print("📄 Document data: \(document.data())")
                return nil
            }
        }
        
        print("🐾 Returning \(pets.count) decoded pets")
        return pets
    }
    
    // MARK: - My Reports Methods (Fixed - No Index Requirements)
    
    /// Fetch all lost pets reported by a specific user
    func fetchUserPets(userId: String) async throws -> [LostPet] {
        print("🔄 Fetching pets for user: \(userId)")
        
        // Simplified query - no ordering to avoid index requirement
        let snapshot1 = try await db.collection("lostPets")
            .whereField("ownerId", isEqualTo: userId)
            .getDocuments()
        
        let snapshot2 = try await db.collection("lostPets")
            .whereField("ownerID", isEqualTo: userId)
            .getDocuments()
        
        print("📊 Found \(snapshot1.documents.count) pets with 'ownerId' field")
        print("📊 Found \(snapshot2.documents.count) pets with 'ownerID' field")
        
        // Combine results from both queries
        var allDocuments = snapshot1.documents
        allDocuments.append(contentsOf: snapshot2.documents)
        
        // Remove duplicates based on document ID
        let uniqueDocuments = Dictionary(grouping: allDocuments, by: { $0.documentID })
            .compactMap { $0.value.first }
        
        var pets = try uniqueDocuments.compactMap { document -> LostPet? in
            do {
                let pet = try document.data(as: LostPet.self)
                print("✅ Successfully decoded user pet: \(pet.name) (ID: \(pet.id))")
                return pet
            } catch {
                print("❌ Error decoding user pet document \(document.documentID): \(error)")
                print("📄 Document data: \(document.data())")
                return nil
            }
        }
        
        // Sort in memory by reported date (descending - most recent first)
        pets.sort { $0.reportedDate > $1.reportedDate }
        
        print("🐾 Returning \(pets.count) pets for user")
        return pets
    }
    
    /// Fetch all pet sightings reported by a specific user
    func fetchUserSightings(userId: String) async throws -> [PetSighting] {
        print("🔄 Fetching sightings for user: \(userId)")
        
        // Check multiple collection names - simplified queries without ordering
        let collectionNames = ["petSightings", "sightings"]
        var allSightings: [PetSighting] = []
        
        for collectionName in collectionNames {
            do {
                let snapshot = try await db.collection(collectionName)
                    .whereField("reporterId", isEqualTo: userId)
                    .getDocuments() // Removed ordering to avoid index requirement
                
                print("📊 Found \(snapshot.documents.count) sightings in '\(collectionName)' collection")
                
                let sightings = try snapshot.documents.compactMap { document -> PetSighting? in
                    do {
                        let sighting = try document.data(as: PetSighting.self)
                        print("✅ Successfully decoded sighting: \(sighting.id)")
                        return sighting
                    } catch {
                        print("❌ Error decoding sighting document \(document.documentID): \(error)")
                        return nil
                    }
                }
                
                allSightings.append(contentsOf: sightings)
            } catch {
                print("⚠️ Collection '\(collectionName)' query failed: \(error.localizedDescription)")
                // Continue to next collection instead of stopping
            }
        }
        
        // Remove duplicates and sort by date in memory
        let uniqueSightings = Dictionary(grouping: allSightings, by: { $0.id })
            .compactMap { $0.value.first }
            .sorted { $0.sightingDate > $1.sightingDate }
        
        print("🐾 Returning \(uniqueSightings.count) sightings for user")
        return uniqueSightings
    }
    
    /// Update the status of a lost pet (mark as found/unfound)
    func updatePetStatus(petId: String, isActive: Bool) async throws {
        print("🔄 Updating pet \(petId) status to \(isActive ? "active" : "found")")
        
        try await db.collection("lostPets").document(petId).updateData([
            "isActive": isActive,
            "foundDate": isActive ? FieldValue.delete() : FieldValue.serverTimestamp(),
            "lastUpdated": FieldValue.serverTimestamp()
        ])
        
        print("✅ Pet \(petId) status updated successfully")
    }
    
    /// Delete a lost pet report
    func deletePetReport(petId: String) async throws {
        try await db.collection("lostPets").document(petId).delete()
        print("✅ Pet report \(petId) deleted")
    }
    
    /// Delete a sighting report
    func deleteSightingReport(sightingId: String) async throws {
        // Try both collection names
        let collectionNames = ["petSightings", "sightings"]
        
        for collectionName in collectionNames {
            do {
                try await db.collection(collectionName).document(sightingId).delete()
                print("✅ Sighting report \(sightingId) deleted from \(collectionName)")
                return
            } catch {
                print("⚠️ Could not delete from \(collectionName): \(error)")
            }
        }
    }
    
    /// Submit a new pet sighting report
    func submitSightingReport(sighting: PetSighting) async throws {
        try await db.collection("petSightings").document(sighting.id).setData(from: sighting)
        print("✅ Sighting report submitted with ID: \(sighting.id)")
    }
    
    // MARK: - Debug Helper
    
    /// Debug function to check what's actually in your Firebase database
    func debugFirebaseData(userId: String) async {
        print("🔍 === FIREBASE DEBUG ANALYSIS ===")
        print("🔍 User ID being searched: \(userId)")
        
        // Check if lostPets collection exists and what's in it
        do {
            let allPetsSnapshot = try await db.collection("lostPets").limit(to: 10).getDocuments()
            print("📊 Total documents in lostPets collection (first 10): \(allPetsSnapshot.documents.count)")
            
            if allPetsSnapshot.documents.isEmpty {
                print("❌ No documents found in lostPets collection!")
                return
            }
            
            // Print all documents and their owner fields
            for (index, document) in allPetsSnapshot.documents.enumerated() {
                let data = document.data()
                print("📄 Document \(index + 1) - ID: \(document.documentID)")
                
                // Check for different possible owner field names
                if let ownerId = data["ownerId"] as? String {
                    print("   ✅ ownerId: '\(ownerId)' (matches: \(ownerId == userId))")
                } else {
                    print("   ❌ No 'ownerId' field found")
                }
                
                if let ownerID = data["ownerID"] as? String {
                    print("   ✅ ownerID: '\(ownerID)' (matches: \(ownerID == userId))")
                } else {
                    print("   ❌ No 'ownerID' field found")
                }
                
                // Print pet name for identification
                if let name = data["name"] as? String {
                    print("   🐾 Pet name: '\(name)'")
                }
                
                // Print all available fields
                print("   📋 All fields: \(data.keys.sorted().joined(separator: ", "))")
                print("   ---")
            }
            
        } catch {
            print("❌ Error during Firebase debug: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
        
        print("🔍 === END DEBUG ANALYSIS ===\n")
    }
    
    // MARK: - Other Methods
    
    func uploadPetImages(_ images: [UIImage], petId: String) async throws -> [String] {
        var imageURLs: [String] = []
        
        for (index, image) in images.enumerated() {
            let path = "pet_photos/\(petId)/image_\(index).jpg"
            let url = try await uploadImage(image, path: path)
            imageURLs.append(url)
        }
        
        return imageURLs
    }
    
    func fetchNearbyLostPets(userLocation: CLLocationCoordinate2D, radiusInKm: Double = 50.0) async throws -> [LostPet] {
        // For now, fetch all active pets and filter by distance
        // In production, consider using GeoFirestore for better performance
        let allPets = try await fetchLostPets()
        
        return allPets.filter { pet in
            let distance = calculateDistance(
                from: userLocation,
                to: CLLocationCoordinate2D(latitude: pet.lastSeenLocation.latitude, longitude: pet.lastSeenLocation.longitude)
            )
            return distance <= radiusInKm * 1000 // Convert km to meters
        }
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    func submitSighting(_ sighting: PetSighting) async throws {
        try await db.collection("petSightings").document(sighting.id).setData(from: sighting)
        
        let petRef = db.collection("lostPets").document(sighting.petId)
        try await petRef.updateData([
            "sightingCount": FieldValue.increment(Int64(1)),
            "lastSightingDate": sighting.sightingDate
        ])
    }
    
    func fetchSightings(for petId: String) async throws -> [PetSighting] {
        let snapshot = try await db.collection("petSightings")
            .whereField("petId", isEqualTo: petId)
            .getDocuments() // Removed ordering
        
        let sightings = try snapshot.documents.compactMap { document in
            try document.data(as: PetSighting.self)
        }
        
        // Sort in memory instead
        return sightings.sorted { $0.sightingDate > $1.sightingDate }
    }
    
    func updateUserProfile(_ user: AppUser) async throws {
        try await db.collection("users").document(user.id ?? "").setData(from: user, merge: true)
    }
    
    func uploadProfileImage(_ image: UIImage, userId: String) async throws -> String {
        let path = "profile_photos/\(userId)/profile.jpg"
        return try await uploadImage(image, path: path)
    }
    
    private func uploadImage(_ image: UIImage, path: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw FirebaseServiceError.imageCompressionFailed
        }
        
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await ref.downloadURL()
        
        return downloadURL.absoluteString
    }
}

enum FirebaseServiceError: LocalizedError {
    case imageCompressionFailed
    case uploadFailed
    case dataNotFound
    
    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "Failed to compress image"
        case .uploadFailed:
            return "Failed to upload to server"
        case .dataNotFound:
            return "Requested data not found"
        }
    }
}
