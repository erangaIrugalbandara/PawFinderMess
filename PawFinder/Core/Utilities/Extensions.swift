// PawFinder/Core/Utilities/Extensions.swift

import Foundation
import SwiftUI

// MARK: - Date Extensions
extension Date {
    var timeAgoDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    var daysSince: Int {
        Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
    }
    
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions
extension String {
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count <= length {
            return self
        }
        return String(self.prefix(length)) + trailing
    }
    
    var isNotEmpty: Bool {
        return !self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Color Extensions
extension Color {
    static let pawFinderPrimary = Color(red: 0.4, green: 0.3, blue: 0.8)
    static let pawFinderSecondary = Color(red: 0.6, green: 0.4, blue: 0.9)
    
    // Additional app colors
    static let pawFinderAccent = Color(red: 0.5, green: 0.35, blue: 0.85)
    static let pawFinderBackground = LinearGradient(
        gradient: Gradient(colors: [pawFinderPrimary, pawFinderSecondary]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - View Extensions
extension View {
    func pawFinderGradientBackground() -> some View {
        self.background(
            LinearGradient(
                gradient: Gradient(colors: [Color.pawFinderPrimary, Color.pawFinderSecondary]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
    
    func pawFinderCardStyle() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    func pawFinderButton() -> some View {
        self
            .padding()
            .background(Color.pawFinderPrimary)
            .foregroundColor(.white)
            .cornerRadius(12)
    }
}

// MARK: - Double Extensions
extension Double {
    var formattedDistance: String {
        if self < 1000 {
            return String(format: "%.0f m", self)
        } else {
            return String(format: "%.1f km", self / 1000)
        }
    }
    
    var formattedCurrency: String {
        return String(format: "$%.0f", self)
    }
}

// MARK: - Int Extensions
extension Int {
    var pluralSuffix: String {
        return self == 1 ? "" : "s"
    }
}
