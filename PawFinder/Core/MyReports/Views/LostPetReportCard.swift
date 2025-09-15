import SwiftUI

struct LostPetReportCard: View {
    let pet: LostPet
    let onShare: () -> Void
    let onMarkAsFound: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Pet Image and Basic Info
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: pet.photos.first ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .overlay(
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.6))
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(pet.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        StatusBadge(isActive: pet.isActive)
                    }
                    
                    Text(pet.breed)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Missing for \(daysMissing) days")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(16)
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
            
            // Stats and Actions
            HStack {
                // Stats
                HStack(spacing: 20) {
                    StatItem(icon: "eye.fill", value: "156", label: "Views")
                    StatItem(icon: "location.fill", value: "7", label: "Sightings")
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 12) {
                    if pet.isActive {
                        Button(action: onMarkAsFound) {
                            Text("Mark Found")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white)
                                .cornerRadius(15)
                        }
                    }
                    
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(16)
                    }
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var daysMissing: Int {
        Calendar.current.dateComponents([.day], from: pet.lastSeenDate, to: Date()).day ?? 0
    }
}

struct StatusBadge: View {
    let isActive: Bool
    
    var body: some View {
        Text(isActive ? "Missing" : "Found")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? Color.red : Color.green)
            .cornerRadius(8)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.8))
                Text(value)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}
