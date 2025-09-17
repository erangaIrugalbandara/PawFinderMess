import SwiftUI

struct SightingReportCard: View {
    let sighting: PetSighting
    let onShare: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with sighting info
            HStack(spacing: 12) {
                // Sighting icon with confidence color
                ZStack {
                    Circle()
                        .fill(confidenceColor.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "eye.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Pet Sighting")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        SightingConfidenceBadge(confidence: sighting.confidence)
                    }
                    
                    Text(sighting.sightingDate.timeAgoDisplay)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(sighting.location.address.truncated(to: 30))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
            .padding(16)
            
            // Description and Actions
            if !sighting.description.isEmpty {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(sighting.description)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(3)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        if sighting.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
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
    
    private var confidenceColor: Color {
        switch sighting.confidence {
        case .low: return .orange
        case .medium: return .yellow
        case .high: return .blue
        case .certain: return .green
        }
    }
}

// Renamed to avoid conflicts with any existing ConfidenceBadge
struct SightingConfidenceBadge: View {
    let confidence: SightingConfidence
    
    var body: some View {
        Text(confidence.rawValue)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(badgeColor)
            .cornerRadius(6)
    }
    
    private var badgeColor: Color {
        switch confidence {
        case .low: return .orange
        case .medium: return Color.yellow.opacity(0.8) // Fixed ambiguous opacity
        case .high: return .blue
        case .certain: return .green
        }
    }
}

// No extensions here - they should be in Extensions.swift only
