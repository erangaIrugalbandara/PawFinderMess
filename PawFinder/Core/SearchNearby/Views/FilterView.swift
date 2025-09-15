import SwiftUI

struct FilterView: View {
    // Use the shared instance of SearchNearbyViewModel
    let viewModel = SearchNearbyViewModel.shared

    @Environment(\.dismiss) private var dismiss
    @State private var tempRadius: Double
    @State private var tempSpecies: PetSpecies?
    @State private var showRecentOnly = false
    @State private var showWithRewardOnly = false
    @State private var selectedSizes: Set<PetSize> = []

    init() {
        // Access the shared instance to initialize the state variables
        self._tempRadius = State(initialValue: SearchNearbyViewModel.shared.searchRadius)
        self._tempSpecies = State(initialValue: SearchNearbyViewModel.shared.selectedSpecies)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Info
                    headerInfo

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

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Filter Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button("Reset All") {
                            resetFilters()
                        }
                        .foregroundColor(.red)

                        Spacer()

                        Text("\(filteredPetCount) pets found")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Header Info
    private var headerInfo: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.blue)
                    .font(.system(size: 20))

                Text("Customize Your Search")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()
            }

            Text("Adjust filters to find missing pets more effectively. All changes are applied in real-time.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Search Radius Section
    private var searchRadiusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))

                Text("Search Radius")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()
            }

            VStack(spacing: 12) {
                HStack {
                    Text("1 mi")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(tempRadius)) miles")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.blue)
                    Spacer()
                    Text("50 mi")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Slider(value: $tempRadius, in: 1...50, step: 1) {
                    Text("Radius")
                } minimumValueLabel: {
                    Image(systemName: "location")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                } maximumValueLabel: {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 12))
                }
                .accentColor(.blue)

                // Quick radius buttons
                HStack(spacing: 12) {
                    ForEach([5, 10, 25, 50], id: \.self) { radius in
                        Button("\(radius) mi") {
                            tempRadius = Double(radius)
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Int(tempRadius) == radius ? .white : .blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Int(tempRadius) == radius ? Color.blue : Color.blue.opacity(0.1))
                        .cornerRadius(15)
                    }
                    Spacer()
                }
            }

            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 12))
                Text("Show pets within \(Int(tempRadius)) miles of your location")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Pet Species Section
    private var petSpeciesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "pawprint.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))

                Text("Pet Type")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                if tempSpecies != nil {
                    Button("Clear") {
                        tempSpecies = nil
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                }
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // All Pets Option
                FilterSpeciesCard(
                    species: nil,
                    isSelected: tempSpecies == nil,
                    action: { tempSpecies = nil }
                )

                // Individual Species
                ForEach(PetSpecies.allCases, id: \.self) { species in
                    FilterSpeciesCard(
                        species: species,
                        isSelected: tempSpecies == species,
                        action: {
                            tempSpecies = tempSpecies == species ? nil : species
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Pet Size Section
    private var petSizeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "ruler.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))

                Text("Pet Size")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                if !selectedSizes.isEmpty {
                    Button("Clear") {
                        selectedSizes.removeAll()
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                }
            }

            ForEach(PetSize.allCases, id: \.self) { size in
                HStack {
                    Text(size.rawValue)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    Spacer()
                    if selectedSizes.contains(size) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                    Button(action: {
                        if selectedSizes.contains(size) {
                            selectedSizes.remove(size)
                        } else {
                            selectedSizes.insert(size)
                        }
                    }) {
                        EmptyView()
                    }
                }
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Additional Filters Section
    private var additionalFiltersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))

                Text("Additional Filters")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()
            }

            Toggle("Recent Only", isOn: $showRecentOnly)
            Toggle("With Reward", isOn: $showWithRewardOnly)
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Quick Filters Section
    private var quickFiltersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Filters")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            HStack {
                Button("Dogs Only") {
                    tempSpecies = .dog
                }
                Button("Cats Only") {
                    tempSpecies = .cat
                }
                Button("Nearby (5mi)") {
                    tempRadius = 5
                }
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Computed Properties
    private var filteredPetCount: Int {
        // Calculate filtered count based on current filter settings
        let baseCount = viewModel.lostPets.count
        
        // Apply radius filter
        var count = baseCount
        
        // Apply species filter
        if tempSpecies != nil {
            count = Int(Double(count) * 0.6) // Rough estimate
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

struct FilterSpeciesCard: View {
    let species: PetSpecies?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if let species = species {
                    Text(species.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .primary)
                } else {
                    Text("All Pets")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .primary)
                }
            }
        }
    }
}

#Preview {
    FilterView()
}
