import SwiftUI

struct LostPetReportCard: View {
    let pet: LostPet
    let onShare: () -> Void
    let onMarkAsFound: () -> Void
    @State private var showingConfirmation = false
    
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
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(pet.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        PetStatusBadge(isActive: pet.isActive)
                    }
                    
                    Text(pet.breed)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack {
                        Text("Missing for \(daysMissing) \(daysMissing == 1 ? "day" : "days")")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        if let reward = pet.rewardAmount, reward > 0 {
                            Spacer()
                            Text("Reward: $\(Int(reward))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .padding(16)
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
            
            // Stats and Actions
            HStack {
                // Last seen location (truncated)
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(pet.lastSeenLocation.address.truncated(to: 25))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 8) {
                    if pet.isActive {
                        Button(action: {
                            showingConfirmation = true
                        }) {
                            Text("Mark Found")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white)
                                .cornerRadius(15)
                        }
                    }
                    
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(14)
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
        .alert("Mark as Found?", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Yes, Found!", role: .destructive) {
                onMarkAsFound()
            }
        } message: {
            Text("Are you sure \(pet.name) has been found? This will mark the report as inactive.")
        }
    }
    
    private var daysMissing: Int {
        max(1, Calendar.current.dateComponents([.day], from: pet.lastSeenDate, to: Date()).day ?? 1)
    }
}

// Renamed to avoid conflicts with any existing StatusBadge
struct PetStatusBadge: View {
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.red : Color.green)
                .frame(width: 6, height: 6)
            
            Text(isActive ? "Missing" : "Found")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isActive ? Color.red.opacity(0.3) : Color.green.opacity(0.3))
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

// No extensions here - they should be in Extensions.swift only
