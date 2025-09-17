import SwiftUI
import MapKit

struct PetDetailView: View {
    let pet: LostPet
    let viewModel = SearchNearbyViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @State private var currentPhotoIndex = 0

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
                    VStack(spacing: 0) {
                        // Enhanced Photo Carousel
                        photoCarousel
                        
                        // Main content with modern cards
                        VStack(spacing: 20) {
                            // Pet Info Header with glassmorphism
                            petInfoHeader
                            
                            // Quick Actions with enhanced styling
                            quickActions
                            
                            // Pet Details Card
                            petDetailsSection
                            
                            // Location Card
                            locationSection
                            
                            // Contact Information Card
                            contactSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        .offset(y: -20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        sharePet()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Enhanced Photo Carousel
    private var photoCarousel: some View {
        VStack(spacing: 0) {
            if !pet.photos.isEmpty {
                ZStack {
                    TabView(selection: $currentPhotoIndex) {
                        ForEach(0..<pet.photos.count, id: \.self) { index in
                            AsyncImage(url: URL(string: pet.photos[index])) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ZStack {
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.4, green: 0.3, blue: 0.8).opacity(0.4),
                                            Color(red: 0.6, green: 0.4, blue: 0.9).opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    
                                    VStack(spacing: 12) {
                                        Image(systemName: pet.species.iconName)
                                            .font(.system(size: 60))
                                            .foregroundColor(.white)
                                        
                                        Text("Loading photo...")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            }
                            .frame(height: 320)
                            .clipped()
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 320)
                    
                    // Custom photo indicators with modern styling
                    if pet.photos.count > 1 {
                        VStack {
                            Spacer()
                            
                            HStack(spacing: 8) {
                                ForEach(0..<pet.photos.count, id: \.self) { index in
                                    Circle()
                                        .fill(index == currentPhotoIndex ? Color.white : Color.white.opacity(0.5))
                                        .frame(width: 8, height: 8)
                                        .scaleEffect(index == currentPhotoIndex ? 1.2 : 1.0)
                                        .animation(.easeInOut(duration: 0.2), value: currentPhotoIndex)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                    
                    // Status overlay
                    VStack {
                        HStack {
                            Spacer()
                            
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 20, height: 20)
                                        .shadow(color: Color.red.opacity(0.4), radius: 4, x: 0, y: 2)
                                }
                                
                                Text("MISSING")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.red)
                                            .shadow(color: Color.red.opacity(0.4), radius: 6, x: 0, y: 3)
                                    )
                            }
                        }
                        Spacer()
                    }
                    .padding(20)
                }
            } else {
                // Enhanced placeholder when no photos
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.4, green: 0.3, blue: 0.8).opacity(0.6),
                            Color(red: 0.6, green: 0.4, blue: 0.9).opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    VStack(spacing: 16) {
                        Image(systemName: pet.species.iconName)
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("No photos available")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 320)
            }
        }
    }

    // MARK: - Pet Info Header with Glassmorphism
    private var petInfoHeader: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(pet.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(pet.breed) • \(pet.age) years old")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(distanceString(for: pet))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.2))
                        )
                        
                        if let rewardAmount = pet.rewardAmount, rewardAmount > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                
                                Text("$\(Int(rewardAmount))")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.3))
                            )
                        }
                    }
                }
                
                Spacer()
                
                Text(pet.species.emoji)
                    .font(.system(size: 50))
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.15))
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Enhanced Quick Actions
    private var quickActions: some View {
        HStack(spacing: 16) {
            Button(action: {
                viewModel.showSightingReport(for: pet)
            }) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "eye.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Report Sighting")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
                )
            }
            
            Button(action: {
                callOwner()
            }) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "phone.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.green)
                    }
                    
                    Text("Call Owner")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green, lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
            }
        }
    }

    private func callOwner() {
        if let url = URL(string: "tel://\(pet.contactInfo.phone)") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Modern Pet Details Section
    private var petDetailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                Text("Pet Details")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                ModernDetailRow(title: "Description", value: pet.description, icon: "text.alignleft")
                ModernDetailRow(title: "Color", value: pet.color, icon: "paintpalette.fill")
                ModernDetailRow(title: "Size", value: pet.size.rawValue, icon: "ruler.fill")

                if let rewardAmount = pet.rewardAmount, rewardAmount > 0 {
                    ModernDetailRow(title: "Reward", value: "$\(Int(rewardAmount))", icon: "dollarsign.circle.fill")
                }

                if !pet.distinctiveFeatures.isEmpty {
                    ModernDetailRow(title: "Distinctive Features", value: pet.distinctiveFeatures.joined(separator: ", "), icon: "star.fill")
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - Modern Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "location.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.red)
                }
                
                Text("Last Seen Location")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pet.lastSeenLocation.address)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Last seen: \(pet.lastSeenDate, formatter: dateFormatter)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.red.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                )
            }

            // Enhanced Mini Map
            ZStack {
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: pet.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )), annotationItems: [pet]) { pet in
                    MapPin(coordinate: pet.coordinate, tint: .red)
                }
                .frame(height: 180)
                .cornerRadius(16)
                .disabled(true)
                
                // Map overlay with directions button
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            openInMaps()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                    .font(.system(size: 14, weight: .bold))
                                
                                Text("Directions")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.blue)
                                    .shadow(color: Color.blue.opacity(0.4), radius: 6, x: 0, y: 3)
                            )
                        }
                    }
                    .padding(16)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - Modern Contact Section
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                }
                
                Text("Contact Owner")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }

            VStack(spacing: 16) {
                ModernDetailRow(title: "Owner", value: pet.ownerName, icon: "person.fill")
                ModernDetailRow(title: "Phone", value: pet.contactInfo.phone, icon: "phone.fill")

                if !pet.contactInfo.email.isEmpty {
                    ModernDetailRow(title: "Email", value: pet.contactInfo.email, icon: "envelope.fill")
                }

                ModernDetailRow(title: "Preferred Contact", value: pet.contactInfo.preferredContactMethod.rawValue, icon: "text.bubble.fill")
            }
            
            // Emergency contact note
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
                
                Text("Please contact immediately if you see this pet. Every moment counts!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - Helper Functions
    private func distanceString(for pet: LostPet) -> String {
        if let distance = pet.distanceFromUser, distance > 0 {
            if distance < 0.1 {
                return "Nearby"
            } else if distance < 1.0 {
                return String(format: "%.1f mi", distance)
            } else {
                return String(format: "%.0f mi", distance)
            }
        }

        if let userLocation = viewModel.userLocation {
            let petLocation = CLLocation(latitude: pet.coordinate.latitude, longitude: pet.coordinate.longitude)
            let distance = userLocation.distance(from: petLocation) / 1609.34

            if distance < 0.1 {
                return "Nearby"
            } else if distance < 1.0 {
                return String(format: "%.1f mi", distance)
            } else {
                return String(format: "%.0f mi", distance)
            }
        }

        return "Distance unknown"
    }

    private func openInMaps() {
        let coordinate = pet.coordinate
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = "Last seen location for \(pet.name)"
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    private func sharePet() {
        let shareText = "🐾 Help find \(pet.name)! This \(pet.breed) was last seen at \(pet.lastSeenLocation.address). Contact: \(pet.contactInfo.phone) #FindMyPet #PawFinder"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Modern Detail Row Component
struct ModernDetailRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    PetDetailView(
        pet: LostPet(
            id: "1",
            ownerId: "preview_owner_123", // ✅ Added missing ownerId parameter
            name: "Buddy",
            breed: "Golden Retriever",
            species: PetSpecies.dog,
            age: 3,
            color: "Golden",
            size: PetSize.large,
            description: "Friendly golden retriever",
            lastSeenLocation: LocationData(
                latitude: 37.7749,
                longitude: -122.4194,
                address: "San Francisco, CA",
                city: "San Francisco",
                state: "CA"
            ),
            lastSeenDate: Date(),
            contactInfo: ContactInfo(
                phone: "(555) 123-4567",
                email: "owner@email.com",
                preferredContactMethod: ContactMethod.phone
            ),
            ownerName: "John Doe",
            photos: [],
            isActive: true,
            reportedDate: Date(),
            rewardAmount: 500.0,
            distinctiveFeatures: ["Blue collar"],
            temperament: "Friendly"
        )
    )
}
