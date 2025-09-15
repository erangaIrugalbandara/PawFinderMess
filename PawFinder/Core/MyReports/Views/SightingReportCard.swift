import SwiftUI

struct SightingReportCard: View {
    let sighting: PetSighting
    let onShare: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with sighting info
            HStack(spacing: 12) {
                // Sighting icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "eye.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pet Sighting Reported")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(DateFormatter.shortDate.string(from: sighting.sightingDate))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(sighting.location.address)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Confidence badge
                ConfidenceBadge(confidence: sighting.confidence)
            }
            .padding(16)
            
            // Description
            if !sighting.description.isEmpty {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
                
                HStack {
                    Text("Description:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(sighting.description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(14)
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
}

struct ConfidenceBadge: View {
    let confidence: SightingConfidence
    
    var body: some View {
        Text(confidence.rawValue)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor)
            .cornerRadius(8)
    }
    
    private var badgeColor: Color {
        switch confidence {
        case .low: return .orange
        case .medium: return .yellow
        case .high: return .blue
        case .certain: return .green
        }
    }
}
