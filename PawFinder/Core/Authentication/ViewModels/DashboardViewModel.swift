import Foundation
import SwiftUI
import FirebaseAuth

class DashboardViewModel: ObservableObject {
    // Published properties for UI updates
    @Published var totalMissingPets: Int = 0
    @Published var totalReportsThisWeek: Int = 0
    @Published var totalReunitedPets: Int = 0
    @Published var recentActivities: [DashboardRecentActivity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService()
    
    // MARK: - Load Dashboard Data
    
    func loadDashboardData() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        print("🔄 Loading dashboard data...")
        
        await withTaskGroup(of: Void.self) { group in
            // Load statistics
            group.addTask { await self.loadMissingPetsCount() }
            group.addTask { await self.loadWeeklyReportsCount() }
            group.addTask { await self.loadReunitedPetsCount() }
            group.addTask { await self.loadRecentActivities() }
        }
        
        await MainActor.run {
            self.isLoading = false
            print("✅ Dashboard data loaded successfully")
        }
    }
    
    // MARK: - Individual Data Loading Methods
    
    @MainActor
    private func loadMissingPetsCount() async {
        do {
            let allPets = try await firebaseService.fetchAllLostPets()
            let activePets = allPets.filter { $0.isActive }
            totalMissingPets = activePets.count
            print("📊 Missing pets: \(totalMissingPets)")
        } catch {
            print("❌ Error loading missing pets count: \(error)")
            totalMissingPets = 0
        }
    }
    
    @MainActor
    private func loadWeeklyReportsCount() async {
        do {
            let allPets = try await firebaseService.fetchAllLostPets()
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let weeklyReports = allPets.filter { $0.reportedDate >= oneWeekAgo }
            totalReportsThisWeek = weeklyReports.count
            print("📊 Reports this week: \(totalReportsThisWeek)")
        } catch {
            print("❌ Error loading weekly reports count: \(error)")
            totalReportsThisWeek = 0
        }
    }
    
    @MainActor
    private func loadReunitedPetsCount() async {
        do {
            let allPets = try await firebaseService.fetchAllLostPets()
            // Count pets that were reported but are now inactive (presumably found)
            let reunitedPets = allPets.filter { !$0.isActive }
            totalReunitedPets = reunitedPets.count
            print("📊 Reunited pets: \(totalReunitedPets)")
        } catch {
            print("❌ Error loading reunited pets count: \(error)")
            totalReunitedPets = 0
        }
    }
    
    @MainActor
    private func loadRecentActivities() async {
        do {
            let allPets = try await firebaseService.fetchAllLostPets()
            
            // Convert pets to activities and sort by most recent
            let activities = allPets
                .sorted { $0.reportedDate > $1.reportedDate }
                .prefix(10) // Get most recent 10
                .map { pet -> DashboardRecentActivity in
                    let timeAgo = timeAgoString(from: pet.reportedDate)
                    let status: DashboardRecentActivity.DashboardActivityStatus = pet.isActive ? .missing : .found
                    let action = pet.isActive ? "was reported missing" : "was found safe!"
                    
                    return DashboardRecentActivity(
                        id: UUID(),
                        petName: pet.name,
                        action: action,
                        location: pet.lastSeenLocation.address,
                        distance: "Location: \(pet.lastSeenLocation.city)",
                        time: timeAgo,
                        petType: mapSpeciesToDashboardType(pet.species),
                        status: status
                    )
                }
            
            recentActivities = Array(activities)
            print("📊 Recent activities loaded: \(recentActivities.count)")
            
        } catch {
            print("❌ Error loading recent activities: \(error)")
            recentActivities = []
        }
    }
    
    // MARK: - User-Specific Data
    
    func loadUserStats(userId: String) async -> (myPets: Int, mySightings: Int) {
        do {
            async let userPets = firebaseService.fetchUserPets(userId: userId)
            async let userSightings = firebaseService.fetchUserSightings(userId: userId)
            
            let pets = try await userPets
            let sightings = try await userSightings
            
            return (pets.count, sightings.count)
        } catch {
            print("❌ Error loading user stats: \(error)")
            return (0, 0)
        }
    }
    
    // MARK: - Refresh Methods
    
    func refreshData() async {
        await loadDashboardData()
    }
    
    // MARK: - Helper Methods
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func mapSpeciesToDashboardType(_ species: PetSpecies) -> DashboardRecentActivity.DashboardPetType {
        switch species {
        case .dog: return .dog
        case .cat: return .cat
        default: return .other
        }
    }
    
    // MARK: - Computed Properties
    
    var dashboardStats: (missing: String, reports: String, reunited: String) {
        return (
            missing: "\(totalMissingPets)",
            reports: "\(totalReportsThisWeek)",
            reunited: "\(totalReunitedPets)"
        )
    }
    
    var mostRecentActivity: DashboardRecentActivity? {
        return recentActivities.first
    }
    
    var hasData: Bool {
        return totalMissingPets > 0 || totalReportsThisWeek > 0 || totalReunitedPets > 0
    }
}
