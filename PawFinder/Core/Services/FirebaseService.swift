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

    // Add this method that was missing - this is what SearchNearbyViewModel is calling
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
    
    func fetchUserPets(userId: String) async throws -> [LostPet] {
        // Fix: Use "lostPets" collection name to match where data is saved
        let snapshot = try await db.collection("lostPets")
            .whereField("ownerID", isEqualTo: userId)
            .order(by: "reportedDate", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: LostPet.self)
        }
    }
    
    func updatePetStatus(petId: String, isActive: Bool) async throws {
        // Fix: Use "lostPets" collection name
        try await db.collection("lostPets").document(petId).updateData([
            "isActive": isActive,
            "foundDate": isActive ? FieldValue.delete() : FieldValue.serverTimestamp()
        ])
    }
    
    func fetchUserSightings(userId: String) async throws -> [PetSighting] {
            // This would implement Firebase query to get sightings reported by user
            // For now returning empty array - implement based on your Firebase structure
            return []
        }

    func submitSighting(_ sighting: PetSighting) async throws {
        try await db.collection("sightings").document(sighting.id).setData(from: sighting)
        
        let petRef = db.collection("lostPets").document(sighting.petId)
        try await petRef.updateData([
            "sightingCount": FieldValue.increment(Int64(1)),
            "lastSightingDate": sighting.sightingDate
        ])
    }
    
    func fetchSightings(for petId: String) async throws -> [PetSighting] {
        let snapshot = try await db.collection("sightings")
            .whereField("petId", isEqualTo: petId)
            .order(by: "sightingDate", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: PetSighting.self)
        }
    }
    
    func updateUserProfile(_ user: User) async throws {
        try await db.collection("users").document(user.id).setData(from: user, merge: true)
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
