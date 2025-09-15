import SwiftUI

// MARK: - Dashboard Stat Card
struct DashboardStatCard: View {
    let number: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(number)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Dashboard Action Card
struct DashboardActionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let backgroundColor: Color
    let borderColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                // Text
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Dashboard Recent Activity Models
struct DashboardRecentActivity: Identifiable {
    let id: UUID
    let petName: String
    let action: String
    let location: String
    let distance: String
    let time: String
    let petType: DashboardPetType
    let status: DashboardActivityStatus
    
    enum DashboardPetType {
        case dog, cat, other
        
        var icon: String {
            switch self {
            case .dog: return "dog.fill"
            case .cat: return "cat.fill"
            case .other: return "questionmark.circle.fill"
            }
        }
    }
    
    enum DashboardActivityStatus {
        case missing, found, sighting
        
        var color: Color {
            switch self {
            case .missing: return .red
            case .found: return .green
            case .sighting: return .orange
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .missing: return .red.opacity(0.1)
            case .found: return .green.opacity(0.1)
            case .sighting: return .orange.opacity(0.1)
            }
        }
    }
}

// MARK: - Dashboard Activity Card
struct DashboardActivityCard: View {
    let activity: DashboardRecentActivity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with pet icon and status
            HStack {
                ZStack {
                    Circle()
                        .fill(activity.status.backgroundColor)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: activity.petType.icon)
                        .font(.system(size: 20))
                        .foregroundColor(activity.status.color)
                }
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(activity.status.color)
                    .frame(width: 8, height: 8)
            }
            
            // Pet info
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.petName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                Text(activity.action)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                Text(activity.location)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            // Footer
            HStack {
                Text(activity.distance)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(activity.time)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Dashboard Community Update Models
struct DashboardCommunityUpdate: Identifiable {
    let id: UUID
    let title: String
    let message: String
    let time: String
    let type: DashboardUpdateType
    
    enum DashboardUpdateType {
        case volunteers, success, weather, alert
        
        var icon: String {
            switch self {
            case .volunteers: return "person.3.fill"
            case .success: return "heart.fill"
            case .weather: return "cloud.rain.fill"
            case .alert: return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .volunteers: return .blue
            case .success: return .green
            case .weather: return .cyan
            case .alert: return .orange
            }
        }
    }
}

// MARK: - Dashboard Community Card
struct DashboardCommunityCard: View {
    let update: DashboardCommunityUpdate
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(update.type.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: update.type.icon)
                    .font(.system(size: 18))
                    .foregroundColor(update.type.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(update.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Text(update.time)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Text(update.message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.9))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Previews
#Preview("Dashboard Stat Card") {
    DashboardStatCard(number: "12", title: "Pets", subtitle: "Currently Missing", color: .red)
        .background(Color.purple)
        .padding()
}

#Preview("Dashboard Action Card") {
    DashboardActionCard(
        icon: "location.fill",
        iconColor: .red,
        title: "Report",
        subtitle: "Lost Pet",
        backgroundColor: Color.red.opacity(0.15),
        borderColor: Color.red.opacity(0.3)
    ) {
        print("Tapped")
    }
    .background(Color.purple)
    .padding()
}
