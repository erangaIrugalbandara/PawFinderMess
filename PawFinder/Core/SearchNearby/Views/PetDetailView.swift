import SwiftUI
import MapKit

struct PetDetailView: View {
    let pet: LostPet
    let viewModel = SearchNearbyViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @State private var currentPhotoIndex = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo Carousel
                    photoCarousel

                    VStack(spacing: 24) {
                        // Pet Info Header
                        petInfoHeader

                        // Quick Actions
                        quickActions

                        // Pet Details
                        petDetailsSection

                        // Location Section
                        locationSection

                        // Contact Information
                        contactSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        sharePet()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    // MARK: - Photo Carousel
    private var photoCarousel: some View {
        VStack(spacing: 12) {
            if !pet.photos.isEmpty {
                TabView(selection: $currentPhotoIndex) {
                    ForEach(0..<pet.photos.count, id: \.self) { index in
                        AsyncImage(url: URL(string: pet.photos[index])) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                            VStack(spacing: 12) {
                                Image(systemName: pet.species.iconName)
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                                Text("Loading...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .frame(height: 300)
                        .cornerRadius(16)
                        .clipped()
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .frame(height: 300)
            } else {
                // Placeholder when no photos
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 300)
                    .cornerRadius(16)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: pet.species.iconName)
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            Text("No photos available")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    )
            }

            // Photo indicators
            if pet.photos.count > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<pet.photos.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPhotoIndex ? Color.blue : Color.gray.opacity(0.5))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
    }

    // MARK: - Pet Info Header
    private var petInfoHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pet.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)

                    Text("\(pet.breed) • \(pet.age) years old")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(pet.species.emoji)
                        .font(.system(size: 40))

                    Text(distanceString(for: pet))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
        }
    }

    // MARK: - Quick Actions
    private var quickActions: some View {
        HStack(spacing: 16) {
            Button(action: {
                viewModel.showSightingReport(for: pet)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 16))
                    Text("Report Sighting")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            
            Button(action: {
                callOwner()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16))
                    Text("Call Owner")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 1)
                )
            }
        }
    }

    private func callOwner() {
        if let url = URL(string: "tel://\(pet.contactInfo)") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Pet Details Section
    private var petDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pet Details")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                DetailRow(title: "Description", value: pet.description)
                DetailRow(title: "Color", value: pet.color)
                DetailRow(title: "Size", value: pet.size.rawValue)

                if let rewardAmount = pet.rewardAmount, rewardAmount > 0 {
                    DetailRow(title: "Reward", value: "$\(Int(rewardAmount))")
                }

                if !pet.distinctiveFeatures.isEmpty {
                    DetailRow(title: "Distinctive Features", value: pet.distinctiveFeatures.joined(separator: ", "))
                }
            }
        }
        .padding(20)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last Seen Location")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                Text(pet.lastSeenLocation.address)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)

                Text("Last seen: \(pet.lastSeenDate, formatter: dateFormatter)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // Mini Map
            Map(coordinateRegion: .constant(MKCoordinateRegion(
                center: pet.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )), annotationItems: [pet]) { pet in
                MapPin(coordinate: pet.coordinate, tint: .red)
            }
            .frame(height: 150)
            .cornerRadius(12)
            .disabled(true)
        }
        .padding(20)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Contact Section
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Owner")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                DetailRow(title: "Owner", value: pet.ownerName)
                DetailRow(title: "Phone", value: pet.contactInfo.phone)

                if !pet.contactInfo.email.isEmpty {
                    DetailRow(title: "Email", value: pet.contactInfo.email)
                }

                DetailRow(title: "Preferred Contact", value: pet.contactInfo.preferredContactMethod.rawValue)
            }
        }
        .padding(20)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Helper Functions
    private func distanceString(for pet: LostPet) -> String {
        // Use the existing distanceFromUser property if available
        if let distance = pet.distanceFromUser, distance > 0 {
            if distance < 0.1 {
                return "Nearby"
            } else if distance < 1.0 {
                return String(format: "%.1f mi", distance)
            } else {
                return String(format: "%.0f mi", distance)
            }
        }

        // Calculate distance if user location is available
        if let userLocation = viewModel.userLocation {
            let petLocation = CLLocation(latitude: pet.coordinate.latitude, longitude: pet.coordinate.longitude)
            let distance = userLocation.distance(from: petLocation) / 1609.34 // Convert to miles

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

    private func sharePet() {
        let shareText = "Help find \(pet.name)! This \(pet.breed) was last seen at \(pet.lastSeenLocation.address). Contact: \(pet.contactInfo.phone)"
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

// MARK: - Detail Row Component
struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

#Preview {
    PetDetailView(
        pet: LostPet(
            id: "1",
            name: "Buddy",
            breed: "Golden Retriever",
            species: PetSpecies.dog, // Use explicit type
            age: 3,
            color: "Golden",
            size: PetSize.large, // Use explicit type
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
                preferredContactMethod: ContactMethod.phone // Use explicit type
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
