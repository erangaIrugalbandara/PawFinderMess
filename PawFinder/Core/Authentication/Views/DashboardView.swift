import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @StateObject private var profileViewModel = ProfileViewModel() // Add ProfileViewModel to track profile changes
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
                    
                    // Main Content (Dynamic Layout)
                    VStack(spacing: 32) {
                        // Stats Cards with real data
                        statsSection
                        
                        // Quick Actions Grid
                        quickActionsSection
                        
                        // Recent Activity Preview with real data
                        recentActivityPreview
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
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
                .environmentObject(profileViewModel) // Pass profileViewModel
        }
        .fullScreenCover(isPresented: $showingCommunityUpdatesView) {
            CommunityUpdatesView()
                .environmentObject(authViewModel)
        }
        .task {
            // Load dashboard data when view appears
            await dashboardViewModel.loadDashboardData()
            // Load profile data to get latest profile picture
            profileViewModel.fetchProfile()
        }
        .refreshable {
            // Pull to refresh functionality
            await dashboardViewModel.refreshData()
            profileViewModel.fetchProfile() // Refresh profile data too
        }
        .onChange(of: showingProfileView) { isShowing in
            // When profile view is dismissed, refresh profile data
            if !isShowing {
                profileViewModel.fetchProfile()
                // Also refresh auth user data
                Task {
                    await authViewModel.refreshCurrentUser()
                }
            }
        }
    }
    
    // MARK: - Header Section with Updated Profile Picture
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hi \(authViewModel.currentUser?.firstName ?? "User")!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                // Time-based greeting
                Text(currentTimeGreeting())
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            // Enhanced Profile Button with actual profile picture
            Button(action: {
                showingProfileView = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    if dashboardViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        // Try to show profile image, fallback to icon
                        if !profileViewModel.profileImageURL.isEmpty {
                            let profileImageURL = profileViewModel.profileImageURL
                            AsyncImage(url: URL(string: profileImageURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.6)
                            }
                            .frame(width: 46, height: 46)
                            .clipShape(Circle())
                        } else {
                            // Fallback to default icon
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.white)
                        }
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 50, height: 50)
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    // MARK: - Stats Section with Real Data
    private var statsSection: some View {
        HStack(spacing: 16) {
            DashboardStatCard(
                number: dashboardViewModel.dashboardStats.missing,
                title: "Missing",
                subtitle: "Active Cases",
                color: .red
            )
            DashboardStatCard(
                number: dashboardViewModel.dashboardStats.reports,
                title: "Reports",
                subtitle: "This Week",
                color: .orange
            )
            DashboardStatCard(
                number: dashboardViewModel.dashboardStats.reunited,
                title: "Reunited",
                subtitle: "Success Stories",
                color: .green
            )
        }
        .opacity(dashboardViewModel.isLoading ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: dashboardViewModel.isLoading)
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
                    icon: "magnifyinglass.circle.fill",
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
    
    // MARK: - Recent Activity Preview with Real Data
    private var recentActivityPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                if dashboardViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.7)
                }
                
                Spacer()
                
                Button("View All") {
                    showingCommunityUpdatesView = true
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            }
            
            // Show most recent activity or empty state
            if let mostRecentActivity = dashboardViewModel.mostRecentActivity {
                CompactActivityCard(activity: mostRecentActivity)
            } else if !dashboardViewModel.isLoading {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "pawprint")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("No recent activity")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("When pets are reported or found, they'll appear here")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            // Error message if needed
            if let errorMessage = dashboardViewModel.errorMessage {
                Text("⚠️ \(errorMessage)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.3))
                    )
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
}

// MARK: - Compact Activity Card (Enhanced for Real Data)
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
                    Text(activity.location.truncated(to: 30))
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

// MARK: - Community Updates View (Enhanced with Real Data)
struct CommunityUpdatesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var dashboardViewModel = DashboardViewModel()
    
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
                        // Recent Activities Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Pet Activity")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            if dashboardViewModel.recentActivities.isEmpty && !dashboardViewModel.isLoading {
                                // Empty state
                                VStack(spacing: 16) {
                                    Image(systemName: "pawprint")
                                        .font(.system(size: 48))
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    Text("No recent activity")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("Check back later for updates on lost and found pets")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(40)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .padding(.horizontal, 20)
                            } else {
                                ForEach(dashboardViewModel.recentActivities) { activity in
                                    EnhancedActivityCard(activity: activity)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        // Community Updates Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Community Updates")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            ForEach(sampleCommunityUpdates, id: \.id) { update in
                                CommunityUpdateCard(update: update)
                                    .padding(.horizontal, 20)
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
                
                // Loading overlay
                if dashboardViewModel.isLoading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Loading updates...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
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
        .task {
            await dashboardViewModel.loadDashboardData()
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
                title: "Success Story: Pet Reunited!",
                message: "Thanks to our amazing community, another pet is back home safe with their family",
                time: "3 hours ago",
                type: .success
            ),
            DashboardCommunityUpdate(
                id: UUID(),
                title: "Weather Alert",
                message: "Heavy rain expected this evening. Please keep your pets safe indoors and check on outdoor shelters",
                time: "5 hours ago",
                type: .weather
            )
        ]
    }
}

// MARK: - Enhanced Activity Card for Community Updates
struct EnhancedActivityCard: View {
    let activity: DashboardRecentActivity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(activity.status.backgroundColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: activity.petType.icon)
                        .font(.system(size: 24))
                        .foregroundColor(activity.status.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(activity.petName) \(activity.action)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(activity.time)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Circle()
                    .fill(activity.status.color)
                    .frame(width: 12, height: 12)
            }
            
            // Location info
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                
                Text(activity.location)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gray)
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        )
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
