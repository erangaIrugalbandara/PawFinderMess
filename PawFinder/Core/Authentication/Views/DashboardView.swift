import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingReportView = false
    @State private var showingSearchView = false
    @State private var showingMyReportsView = false
    @State private var showingProfileView = false
    @State private var showingCommunityUpdatesView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.4, green: 0.3, blue: 0.8),
                        Color(red: 0.6, green: 0.4, blue: 0.9)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Section
                    headerSection
                    
                    // Main Content (Fixed Layout)
                    VStack(spacing: 32) {
                        // Stats Cards
                        statsSection
                        
                        // Quick Actions Grid
                        quickActionsSection
                        
                        // Recent Activity Preview
                        recentActivityPreview
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        // Replace .sheet with .fullScreenCover for full-screen presentation
        .fullScreenCover(isPresented: $showingReportView) {
            ReportLostPetView()
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showingSearchView) {
            SearchNearbyView()
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showingMyReportsView) {
            MyReportsView()
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showingProfileView) {
            ProfileView()
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showingCommunityUpdatesView) {
            CommunityUpdatesView()
                .environmentObject(authViewModel)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hi \(authViewModel.currentUser?.firstName ?? "User")!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                // Only show the time-based greeting (should show "Good afternoon! ☀️" at 12:05 UTC)
                Text(currentTimeGreeting())
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            // Profile Button
            Button(action: {
                showingProfileView = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 16) {
            DashboardStatCard(
                number: "12",
                title: "Missing",
                subtitle: "Active Cases",
                color: .red
            )
            DashboardStatCard(
                number: "28",
                title: "Reports",
                subtitle: "This Week",
                color: .orange
            )
            DashboardStatCard(
                number: "156",
                title: "Reunited",
                subtitle: "Success Stories",
                color: .green
            )
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Quick Actions")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                // Report Lost Pet
                DashboardActionCard(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .red,
                    title: "Report",
                    subtitle: "Lost Pet",
                    backgroundColor: Color.red.opacity(0.15),
                    borderColor: Color.red.opacity(0.3)
                ) {
                    showingReportView = true
                }
                
                // Search Nearby
                DashboardActionCard(
                    icon: "magnifyingglass.circle.fill",
                    iconColor: .blue,
                    title: "Search",
                    subtitle: "Nearby",
                    backgroundColor: Color.blue.opacity(0.15),
                    borderColor: Color.blue.opacity(0.3)
                ) {
                    showingSearchView = true
                }
                
                // My Reports
                DashboardActionCard(
                    icon: "doc.text.fill",
                    iconColor: .green,
                    title: "My",
                    subtitle: "Reports",
                    backgroundColor: Color.green.opacity(0.15),
                    borderColor: Color.green.opacity(0.3)
                ) {
                    showingMyReportsView = true
                }
                
                // Community Updates
                DashboardActionCard(
                    icon: "person.3.fill",
                    iconColor: .yellow,
                    title: "Community",
                    subtitle: "Updates",
                    backgroundColor: Color.yellow.opacity(0.15),
                    borderColor: Color.yellow.opacity(0.3)
                ) {
                    showingCommunityUpdatesView = true
                }
            }
        }
    }
    
    // MARK: - Recent Activity Preview (Non-scrollable)
    private var recentActivityPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                
                Button("View All") {
                    // Navigate to full activity view
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            }
            
            // Show only the most recent activity (no scrolling)
            if let recentActivity = sampleRecentActivities.first {
                CompactActivityCard(activity: recentActivity)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func currentTimeGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:
            return "Good morning! 🌅"
        case 12..<17:
            return "Good afternoon! ☀️"
        case 17..<21:
            return "Good evening! 🌆"
        default:
            return "Good night! 🌙"
        }
    }
    
    // MARK: - Sample Data
    private var sampleRecentActivities: [DashboardRecentActivity] {
        [
            DashboardRecentActivity(
                id: UUID(),
                petName: "Buddy",
                action: "was reported missing",
                location: "Downtown Park",
                distance: "0.8 miles away",
                time: "2 hours ago",
                petType: .dog,
                status: .missing
            ),
            DashboardRecentActivity(
                id: UUID(),
                petName: "Whiskers",
                action: "was found safe!",
                location: "Oak Street",
                distance: "1.2 miles away",
                time: "4 hours ago",
                petType: .cat,
                status: .found
            )
        ]
    }
}

// MARK: - Compact Activity Card (for fixed layout)
struct CompactActivityCard: View {
    let activity: DashboardRecentActivity
    
    var body: some View {
        HStack(spacing: 16) {
            // Pet icon with status
            ZStack {
                Circle()
                    .fill(activity.status.backgroundColor)
                    .frame(width: 50, height: 50)
                
                Image(systemName: activity.petType.icon)
                    .font(.system(size: 24))
                    .foregroundColor(activity.status.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.petName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Text(activity.time)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Text(activity.action)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                HStack {
                    Text(activity.location)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text(activity.distance)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            // Status indicator
            Circle()
                .fill(activity.status.color)
                .frame(width: 8, height: 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Community Updates View (Full Screen with iOS Back Button)
struct CommunityUpdatesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.4, green: 0.3, blue: 0.8),
                        Color(red: 0.6, green: 0.4, blue: 0.9)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Updates List
                        VStack(spacing: 16) {
                            ForEach(sampleCommunityUpdates, id: \.id) { update in
                                CommunityUpdateCard(update: update)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Community Updates")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    private var sampleCommunityUpdates: [DashboardCommunityUpdate] {
        [
            DashboardCommunityUpdate(
                id: UUID(),
                title: "New Search Team Formed",
                message: "25 volunteers joined the weekend search effort for missing pets in downtown area",
                time: "1 hour ago",
                type: .volunteers
            ),
            DashboardCommunityUpdate(
                id: UUID(),
                title: "Success Story: Luna Reunited!",
                message: "Thanks to our amazing community, Luna the Golden Retriever is back home after 3 days",
                time: "3 hours ago",
                type: .success
            ),
            DashboardCommunityUpdate(
                id: UUID(),
                title: "Weather Alert",
                message: "Heavy rain expected this evening. Please keep your pets safe indoors and check on outdoor shelters",
                time: "5 hours ago",
                type: .weather
            ),
            DashboardCommunityUpdate(
                id: UUID(),
                title: "Pet Safety Workshop",
                message: "Join us this Saturday for a free pet safety and identification workshop at the community center",
                time: "1 day ago",
                type: .volunteers
            ),
            DashboardCommunityUpdate(
                id: UUID(),
                title: "Found: Orange Tabby Cat",
                message: "Friendly orange tabby found near Central Park. Currently at the local vet clinic",
                time: "2 days ago",
                type: .success
            )
        ]
    }
}

// MARK: - Enhanced Community Update Card
struct CommunityUpdateCard: View {
    let update: DashboardCommunityUpdate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(update.type.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: update.type.icon)
                        .font(.system(size: 20))
                        .foregroundColor(update.type.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(update.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(update.time)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Content
            Text(update.message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.gray)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        )
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel())
}
