import SwiftUI
import MapKit

struct SearchNearbyView: View {
    @StateObject private var viewModel = SearchNearbyViewModel.shared
    @StateObject private var locationManager = LocationManager()
    @State private var showingFilters = false
    @State private var dragOffset: CGFloat = 0
    @State private var isExpanded = false
    @Environment(\.presentationMode) var presentationMode
    
    private let minPetListHeight: CGFloat = 180
    private let maxPetListHeight: CGFloat = 360
    
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
                
                if viewModel.isLoading {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Finding Lost Pets")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Searching for pets in your area...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 12) {
                            Text("Something went wrong")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(errorMessage)
                                .font(.system(size: 16, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 32)
                        }
                        
                        Button("Try Again") {
                            viewModel.loadPetsFromDatabase()
                        }
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.8))
                        .frame(width: 160, height: 50)
                        .background(Color.white)
                        .cornerRadius(25)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 32)
                } else {
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            // Map View with enhanced styling
                            ZStack {
                                MapView(
                                    region: $viewModel.mapRegion,
                                    pets: viewModel.filteredPets,
                                    userLocation: locationManager.currentLocation,
                                    onPetSelected: { pet in
                                        viewModel.selectPet(pet)
                                    }
                                )
                                .frame(height: geometry.size.height - (isExpanded ? maxPetListHeight : minPetListHeight))
                                .cornerRadius(isExpanded ? 0 : 20)
                                .animation(.easeInOut(duration: 0.3), value: isExpanded)
                                
                                // Modern overlay with glassmorphism effect
                                VStack {
                                    HStack {
                                        Spacer()
                                        
                                        Button(action: {
                                            showingFilters = true
                                        }) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(Color.white.opacity(0.25))
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                    )
                                                    .frame(width: 56, height: 56)
                                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                                
                                                Image(systemName: "slider.horizontal.3")
                                                    .font(.system(size: 20, weight: .semibold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                                    
                                    Spacer()
                                }
                            }
                            
                            // Enhanced Draggable Pet List Container with theme-matching design
                            VStack(alignment: .leading, spacing: 0) {
                                // Modern drag handle with purple theme
                                VStack(spacing: 16) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.6))
                                        .frame(width: 48, height: 6)
                                        .padding(.top, 12)
                                        .frame(maxWidth: .infinity)
                                    
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Lost Pets Nearby")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.white)
                                            
                                            Text("\(viewModel.filteredPets.count) pets found")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            showingFilters = true
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "slider.horizontal.3")
                                                    .font(.system(size: 16, weight: .semibold))
                                                
                                                Text("Filter")
                                                    .font(.system(size: 16, weight: .semibold))
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(Color.white.opacity(0.2))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 20)
                                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                
                                if viewModel.filteredPets.isEmpty {
                                    VStack(spacing: 20) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white.opacity(0.2))
                                                .frame(width: 80, height: 80)
                                            
                                            Image(systemName: "pawprint.circle")
                                                .font(.system(size: 40))
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        
                                        VStack(spacing: 8) {
                                            Text("No lost pets found")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.white)
                                            
                                            Text("Try adjusting your search filters or check back later")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white.opacity(0.8))
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal, 32)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .padding(.vertical, 40)
                                } else {
                                    ScrollView {
                                        LazyVStack(spacing: 16) {
                                            ForEach(Array(viewModel.filteredPets.prefix(isExpanded ? 4 : 2).enumerated()), id: \.element.id) { index, pet in
                                                ThemedPetListCardView(pet: pet) {
                                                    viewModel.showPetDetail(pet)
                                                }
                                                .padding(.horizontal, 20)
                                            }
                                        }
                                        .padding(.vertical, 16)
                                    }
                                    .frame(height: isExpanded ? maxPetListHeight - 80 : minPetListHeight - 80)
                                    .clipped()
                                }
                            }
                            .frame(height: isExpanded ? maxPetListHeight : minPetListHeight)
                            .background(
                                // Gradient background matching the main theme
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.5, green: 0.4, blue: 0.85),
                                                Color(red: 0.6, green: 0.45, blue: 0.9)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -8)
                            )
                            .offset(y: dragOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let translationY = value.translation.height
                                        if isExpanded {
                                            dragOffset = max(0, translationY)
                                        } else {
                                            dragOffset = min(0, translationY)
                                        }
                                    }
                                    .onEnded { value in
                                        let translationY = value.translation.height
                                        
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            if isExpanded {
                                                if translationY > 50 {
                                                    isExpanded = false
                                                }
                                            } else {
                                                if translationY < -50 {
                                                    isExpanded = true
                                                }
                                            }
                                            dragOffset = 0
                                        }
                                    }
                            )
                            .animation(.easeInOut(duration: 0.3), value: isExpanded)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Search Nearby")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            })
            .refreshable {
                viewModel.loadPetsFromDatabase()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            viewModel.requestLocationPermission()
            viewModel.loadPetsFromDatabase()
        }
        .sheet(isPresented: $showingFilters) {
            ModernFilterView()
        }
        .sheet(isPresented: $viewModel.showingPetDetail) {
            if let pet = viewModel.selectedPet {
                PetDetailView(pet: pet)
            }
        }
        .sheet(isPresented: $viewModel.showingSightingReport) {
            if let pet = viewModel.selectedPet {
                SightingReportView(pet: pet)
            }
        }
    }
}

// MARK: - Theme-Matching Pet List Card View
struct ThemedPetListCardView: View {
    let pet: LostPet
    let onTap: () -> Void
    
    // Computed properties to break down complex expressions
    private var rewardBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.green.opacity(0.2))
    }
    
    private var rewardBorder: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color.green.opacity(0.4), lineWidth: 1)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.15))
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Enhanced Pet Photo with overlay
                ZStack {
                    AsyncImage(url: URL(string: pet.photos.first ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            Image(systemName: pet.species.iconName)
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .frame(width: 70, height: 70)
                    .cornerRadius(16)
                    .clipped()
                    
                    // Status indicator
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.red)
                                .frame(width: 16, height: 16)
                                .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        Spacer()
                    }
                    .frame(width: 70, height: 70)
                }
                
                // Pet Info with enhanced typography
                VStack(alignment: .leading, spacing: 6) {
                    Text(pet.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(pet.breed) • \(pet.species.rawValue)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Last seen: \(pet.lastSeenLocation.address)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text(pet.species.emoji)
                                .font(.system(size: 16))
                            
                            if let distance = pet.distanceFromUser, distance > 0 {
                                Text(String(format: "%.1f mi", distance))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        if let rewardAmount = pet.rewardAmount, rewardAmount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.green)
                                
                                Text("$\(Int(rewardAmount))")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.green.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.green.opacity(0.4), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                
                Spacer()
                
                // Modern arrow indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(20)
            .background(cardBackground)
            .overlay(cardBorder)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SearchNearbyView()
}
