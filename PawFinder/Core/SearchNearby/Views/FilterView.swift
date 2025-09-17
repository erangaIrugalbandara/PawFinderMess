import SwiftUI

struct ModernFilterView: View {
    let viewModel = SearchNearbyViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @State private var tempRadius: Double
    @State private var tempSpecies: PetSpecies?
    @State private var showRecentOnly = false
    @State private var showWithRewardOnly = false
    @State private var selectedSizes: Set<PetSize> = []

    init() {
        self._tempRadius = State(initialValue: SearchNearbyViewModel.shared.searchRadius)
        self._tempSpecies = State(initialValue: SearchNearbyViewModel.shared.selectedSpecies)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
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
                        // Header Info with glassmorphism
                        headerInfoSection
                        
                        // Search Radius Section
                        searchRadiusSection
                        
                        // Pet Species Filter
                        petSpeciesSection
                        
                        // Pet Size Filter
                        petSizeSection
                        
                        // Additional Filters
                        additionalFiltersSection
                        
                        // Quick Filter Buttons
                        quickFiltersSection
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Filter Results")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomActionBar
            }
        }
    }
    
    // MARK: - Header Info Section
    private var headerInfoSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Customize Your Search")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Find pets more effectively")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            
            Text("Adjust filters to find missing pets in your area. All changes are applied in real-time to help you discover pets that need your help.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Search Radius Section
    private var searchRadiusSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.4, green: 0.3, blue: 0.8).opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
                        .font(.system(size: 18, weight: .bold))
                }
                
                Text("Search Radius")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Radius display with modern styling
                HStack {
                    Text("1 mi")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("\(Int(tempRadius))")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
                        
                        Text("miles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("50 mi")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                // Modern slider
                VStack(spacing: 12) {
                    Slider(value: $tempRadius, in: 1...50, step: 1) {
                        Text("Radius")
                    } minimumValueLabel: {
                        Image(systemName: "location")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    } maximumValueLabel: {
                        Image(systemName: "location.fill")
                            .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
                            .font(.system(size: 14))
                    }
                    .accentColor(Color(red: 0.4, green: 0.3, blue: 0.8))
                    
                    // Quick radius buttons
                    HStack(spacing: 12) {
                        ForEach([5, 10, 25, 50], id: \.self) { radius in
                            Button("\(radius) mi") {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    tempRadius = Double(radius)
                                }
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Int(tempRadius) == radius ? .white : Color(red: 0.4, green: 0.3, blue: 0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Int(tempRadius) == radius ? Color(red: 0.4, green: 0.3, blue: 0.8) : Color(red: 0.4, green: 0.3, blue: 0.8).opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Int(tempRadius) == radius ? Color.clear : Color(red: 0.4, green: 0.3, blue: 0.8).opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .animation(.easeInOut(duration: 0.2), value: Int(tempRadius) == radius)
                        }
                        Spacer()
                    }
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
                        .font(.system(size: 14))
                    
                    Text("Show pets within \(Int(tempRadius)) miles of your location")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Pet Species Section
    private var petSpeciesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 18, weight: .bold))
                }
                
                Text("Pet Type")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if tempSpecies != nil {
                    Button("Clear") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            tempSpecies = nil
                        }
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.red)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                // All Pets Option
                ModernFilterSpeciesCard(
                    species: nil,
                    isSelected: tempSpecies == nil,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            tempSpecies = nil
                        }
                    }
                )
                
                // Individual Species
                ForEach(PetSpecies.allCases, id: \.self) { species in
                    ModernFilterSpeciesCard(
                        species: species,
                        isSelected: tempSpecies == species,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                tempSpecies = tempSpecies == species ? nil : species
                            }
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Pet Size Section
    private var petSizeSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "ruler.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 18, weight: .bold))
                }
                
                Text("Pet Size")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !selectedSizes.isEmpty {
                    Button("Clear") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSizes.removeAll()
                        }
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.red)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(PetSize.allCases, id: \.self) { size in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedSizes.contains(size) {
                                selectedSizes.remove(size)
                            } else {
                                selectedSizes.insert(size)
                            }
                        }
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(selectedSizes.contains(size) ? Color.green : Color.gray.opacity(0.2))
                                    .frame(width: 24, height: 24)
                                
                                if selectedSizes.contains(size) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Text(size.rawValue)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedSizes.contains(size) ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedSizes.contains(size) ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Additional Filters Section
    private var additionalFiltersSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.blue)
                        .font(.system(size: 18, weight: .bold))
                }
                
                Text("Additional Filters")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                ModernToggleRow(
                    title: "Recent Only",
                    subtitle: "Show pets reported in the last 7 days",
                    icon: "clock.fill",
                    iconColor: .orange,
                    isOn: $showRecentOnly
                )
                
                ModernToggleRow(
                    title: "With Reward",
                    subtitle: "Show only pets with monetary rewards",
                    icon: "dollarsign.circle.fill",
                    iconColor: .green,
                    isOn: $showWithRewardOnly
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Quick Filters Section
    private var quickFiltersSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.purple)
                        .font(.system(size: 18, weight: .bold))
                }
                
                Text("Quick Filters")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    QuickFilterButton(
                        title: "Dogs Only",
                        icon: "🐕",
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                tempSpecies = .dog
                            }
                        }
                    )
                    
                    QuickFilterButton(
                        title: "Cats Only",
                        icon: "🐱",
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                tempSpecies = .cat
                            }
                        }
                    )
                }
                
                QuickFilterButton(
                    title: "Nearby (5 miles)",
                    icon: "📍",
                    isFullWidth: true,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            tempRadius = 5
                        }
                    }
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        HStack(spacing: 16) {
            Button("Reset All") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    resetFilters()
                }
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.red)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(filteredPetCount)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("pets found")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: -4)
        )
    }
    
    // MARK: - Computed Properties
    private var filteredPetCount: Int {
        let baseCount = viewModel.lostPets.count
        var count = baseCount
        
        if tempSpecies != nil {
            count = Int(Double(count) * 0.6)
        }
        
        return max(count, 0)
    }
    
    // MARK: - Actions
    private func applyFilters() {
        viewModel.updateSearchRadius(tempRadius)
        viewModel.updateSpeciesFilter(tempSpecies)
    }
    
    private func resetFilters() {
        tempRadius = 10.0
        tempSpecies = nil
        selectedSizes.removeAll()
        showRecentOnly = false
        showWithRewardOnly = false
    }
}

// MARK: - Modern Filter Species Card
struct ModernFilterSpeciesCard: View {
    let species: PetSpecies?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(red: 0.4, green: 0.3, blue: 0.8) : Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    if let species = species {
                        Text(species.emoji)
                            .font(.system(size: 24))
                    } else {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? .white : .gray)
                    }
                }
                
                Text(species?.rawValue ?? "All Pets")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isSelected ? Color(red: 0.4, green: 0.3, blue: 0.8) : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(red: 0.4, green: 0.3, blue: 0.8).opacity(0.1) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color(red: 0.4, green: 0.3, blue: 0.8) : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Modern Toggle Row
struct ModernToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(red: 0.4, green: 0.3, blue: 0.8))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Quick Filter Button
struct QuickFilterButton: View {
    let title: String
    let icon: String
    var isFullWidth: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.4, green: 0.3, blue: 0.8).opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.4, green: 0.3, blue: 0.8).opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ModernFilterView()
}
