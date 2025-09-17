import SwiftUI

struct MyReportsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = MyReportsViewModel()
    @State private var selectedTab: MyReportsTab = .lostPets
    @State private var showingShareSuccess = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.4, green: 0.3, blue: 0.8),
                                           Color(red: 0.6, green: 0.4, blue: 0.9)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Custom Back Button
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Back")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        Spacer()
                        
                        // Refresh Button
                        Button(action: { refreshData() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .padding(.top, 30)
                    .padding(.horizontal, 16)

                    // Header
                    VStack(spacing: 8) {
                        Text("My Reports")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("Helping \(viewModel.userPets.count) pets • \(viewModel.userSightings.count) Contributions")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.top, 10)

                    // Tabs
                    HStack(spacing: 0) {
                        ForEach(MyReportsTab.allCases, id: \.self) { tab in
                            Button(action: {
                                selectedTab = tab
                            }) {
                                Text(tab.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(selectedTab == tab ? Color(red: 0.4, green: 0.3, blue: 0.8) : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(selectedTab == tab ? Color.white : Color.white.opacity(0.1))
                                    )
                            }
                        }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(24)
                    .padding(.horizontal, 32)

                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        VStack {
                            Text("⚠️ \(errorMessage)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.red.opacity(0.3))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                    }

                    // Content Section
                    if viewModel.isLoading {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            Text("Loading your reports...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.top, 8)
                        }
                        .padding(.top, 50)
                    } else {
                        VStack(spacing: 16) {
                            if selectedTab == .lostPets {
                                lostPetsSection
                            } else {
                                sightingsSection
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .refreshable {
                await refreshDataAsync()
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadInitialData()
        }
        .alert("Report Shared! 🎉", isPresented: $showingShareSuccess) {
            Button("OK") { }
        } message: {
            Text("Your report has been shared! 🐾 Keep faith, every share brings us closer to reuniting pets with their families! 💕✨")
        }
    }
    
    // MARK: - Lost Pets Section
    private var lostPetsSection: some View {
        LazyVStack(spacing: 16) {
            if viewModel.userPets.isEmpty {
                emptyStateView(
                    icon: "pawprint.fill",
                    title: "No Lost Pets Reported",
                    subtitle: "When you report a lost pet, it will appear here"
                )
            } else {
                ForEach(viewModel.userPets) { pet in
                    LostPetReportCard(
                        pet: pet,
                        onShare: {
                            shareReport(pet: pet)
                        },
                        onMarkAsFound: {
                            Task {
                                await viewModel.markPetAsFound(petId: pet.id)
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Sightings Section
    private var sightingsSection: some View {
        LazyVStack(spacing: 16) {
            if viewModel.userSightings.isEmpty {
                emptyStateView(
                    icon: "eye.fill",
                    title: "No Sightings Reported",
                    subtitle: "When you report a pet sighting, it will appear here"
                )
            } else {
                ForEach(viewModel.userSightings) { sighting in
                    SightingReportCard(
                        sighting: sighting,
                        onShare: {
                            shareSighting(sighting: sighting)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Empty State View
    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Data Loading Functions
    private func loadInitialData() async {
        guard let userId = authViewModel.currentUser?.id else {
            return
        }
        await viewModel.loadUserData(userId: userId)
    }
    
    private func refreshData() {
        Task {
            await refreshDataAsync()
        }
    }
    
    private func refreshDataAsync() async {
        guard let userId = authViewModel.currentUser?.id else {
            return
        }
        await viewModel.refreshData(userId: userId)
    }
    
    // MARK: - Share Functions
    private func shareReport(pet: LostPet) {
        let shareText = """
        🆘 MISSING PET ALERT 🆘
        
        Name: \(pet.name)
        Breed: \(pet.breed)
        Color: \(pet.color)
        Size: \(pet.size.rawValue)
        Last seen: \(pet.lastSeenLocation.address)
        Date missing: \(DateFormatter.shortDate.string(from: pet.lastSeenDate))
        
        Description: \(pet.description)
        
        Contact: \(pet.contactInfo.phone)
        
        Please help us find \(pet.name)! 🙏 #MissingPet #PawFinder
        """
        
        shareContent(shareText)
    }
    
    private func shareSighting(sighting: PetSighting) {
        let shareText = """
        🐾 PET SIGHTING REPORT 🐾
        
        Sighted: \(DateFormatter.shortDate.string(from: sighting.sightingDate))
        Location: \(sighting.location.address)
        Confidence: \(sighting.confidence.rawValue)
        
        Description: \(sighting.description)
        
        Helping reunite pets with their families! 💕 #PetSighting #PawFinder
        """
        
        shareContent(shareText)
    }
    
    private func shareContent(_ content: String) {
        let activityVC = UIActivityViewController(activityItems: [content], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true) {
                showingShareSuccess = true
            }
        }
    }
}

// MARK: - Supporting Enums
enum MyReportsTab: CaseIterable {
    case lostPets, sightings
    
    var title: String {
        switch self {
        case .lostPets: return "Lost Pets"
        case .sightings: return "Sightings"
        }
    }
}
