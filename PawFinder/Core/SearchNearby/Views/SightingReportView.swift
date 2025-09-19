import SwiftUI
import MapKit
import FirebaseAuth

struct SightingReportView: View {
    let pet: LostPet
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SearchNearbyViewModel.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var sightingDate = Date()
    @State private var sightingLocation = ""
    @State private var sightingDescription = ""
    @State private var reporterName = ""
    @State private var reporterContact = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var showingMapPicker = false
    @State private var showingSuccessNotification = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    // Add FirebaseService for saving sightings
    private let firebaseService = FirebaseService()
    
    // App gradient colors
    private let gradientColors = [
        Color(red: 0.4, green: 0.3, blue: 0.8),
        Color(red: 0.6, green: 0.4, blue: 0.9),
        Color(red: 0.5, green: 0.2, blue: 0.85)
    ]

    var body: some View {
        ZStack {
            // Beautiful gradient background matching app theme
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating circles for background effect
            backgroundCircles
            
            ScrollView {
                VStack(spacing: 28) {
                    // Custom header with back button
                    headerSection
                    
                    // Pet info card
                    petInfoCard
                    
                    // Sighting form sections
                    VStack(spacing: 24) {
                        sightingDateSection
                        locationSection
                        descriptionSection
                        reporterInfoSection
                    }
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        errorMessageView(errorMessage)
                    }
                    
                    // Submit button
                    submitButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingMapPicker) {
            MapPickerView(
                selectedCoordinate: $selectedCoordinate,
                selectedAddress: $sightingLocation
            )
        }
        .overlay(
            // Enhanced Success Notification Overlay
            ZStack {
                if showingSuccessNotification {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingSuccessNotification = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                dismiss()
                            }
                        }
                    
                    QuickSuccessView(
                        petName: pet.name,
                        isPresented: $showingSuccessNotification,
                        onDismiss: {
                            dismiss()
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingSuccessNotification)
        )
    }
    
    // MARK: - Background Effects
    private var backgroundCircles: some View {
        Group {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 200, height: 200)
                .offset(x: -100, y: -300)
                .blur(radius: 20)
            
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 300, height: 300)
                .offset(x: 150, y: 400)
                .blur(radius: 30)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Custom back button
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Cancel")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                Spacer()
            }
            .padding(.top, 20)
            
            // Title
            VStack(spacing: 8) {
                Text("Report Sighting")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Text("Help reunite \(pet.name) with their family")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Pet Info Card
    private var petInfoCard: some View {
        VStack(spacing: 16) {
            // Pet Photo
            if let firstPhoto = pet.photos.first, !firstPhoto.isEmpty {
                AsyncImage(url: URL(string: firstPhoto)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .overlay(
                            Image(systemName: pet.species.iconName)
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.6))
                        )
                }
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        Image(systemName: pet.species.iconName)
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.6))
                    )
            }
            
            VStack(spacing: 8) {
                Text(pet.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(pet.breed) • \(pet.species.rawValue.capitalized)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Sighting Date Section
    private var sightingDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("When did you see \(pet.name)?")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            DatePicker("Sighting Date", selection: $sightingDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(CompactDatePickerStyle())
                .accentColor(.white)
                .colorScheme(.dark)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Where did you see \(pet.name)?")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Button(action: {
                showingMapPicker = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                    
                    Text(sightingLocation.isEmpty ? "Select location on map" : sightingLocation)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(sightingLocation.isEmpty ? .white.opacity(0.7) : .white)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Description (Optional)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            TextField("What was the pet doing? Any additional details...", text: $sightingDescription, axis: .vertical)
                .lineLimit(3...6)
                .padding(16)
                .font(.system(size: 16, weight: .medium))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Reporter Info Section
    private var reporterInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Your Information")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                TextField("Your name", text: $reporterName)
                    .padding(16)
                    .font(.system(size: 16, weight: .medium))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.primary)
                
                TextField("Your contact (phone or email)", text: $reporterContact)
                    .padding(16)
                    .font(.system(size: 16, weight: .medium))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.primary)
            }
        }
    }
    
    // MARK: - Error Message View
    private func errorMessageView(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(.red)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.5), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: {
            submitSighting()
        }) {
            HStack(spacing: 12) {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }
                
                Text(isSubmitting ? "Submitting..." : "Submit Sighting Report")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.2, green: 0.6, blue: 1.0),
                                Color(red: 0.1, green: 0.4, blue: 0.9)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isFormValid || isSubmitting)
        .opacity(isFormValid && !isSubmitting ? 1.0 : 0.6)
    }
    
    // MARK: - Form Validation
    private var isFormValid: Bool {
        !sightingLocation.isEmpty && !reporterName.isEmpty && !reporterContact.isEmpty
    }
    
    // MARK: - Submit Function
    private func submitSighting() {
        print("🔄 Starting sighting submission...")
        isSubmitting = true
        errorMessage = nil
        
        // Create the sighting object
        let sighting = PetSighting(
            id: UUID().uuidString,
            petId: pet.id,
            reporterId: Auth.auth().currentUser?.uid ?? "anonymous_user",
            reporterName: reporterName,
            reporterContact: reporterContact,
            location: LocationData(
                latitude: selectedCoordinate?.latitude ?? 0.0,
                longitude: selectedCoordinate?.longitude ?? 0.0,
                address: sightingLocation,
                city: "Unknown",
                state: "Unknown"
            ),
            sightingDate: sightingDate,
            description: sightingDescription.isEmpty ? "No additional details provided" : sightingDescription,
            confidence: .medium, // Default confidence level
            photos: [], // No photo support in current UI, but could be added
            isVerified: false
        )
        
        print("🐾 Created sighting object for pet: \(pet.name)")
        print("📍 Location: \(sightingLocation)")
        print("👤 Reporter: \(reporterName)")
        
        // Submit to Firebase
        Task {
            do {
                try await firebaseService.submitSightingReport(sighting: sighting)
                print("✅ Sighting successfully saved to Firebase!")
                
                await MainActor.run {
                    // Report sighting to SearchNearbyViewModel for any local updates
                    viewModel.reportSighting(for: pet)
                    
                    // Schedule phone notification
                    notificationManager.scheduleThankYouNotification(petName: pet.name)
                    
                    // Schedule follow-up hero notification
                    notificationManager.scheduleDelayedHeroNotification(petName: pet.name)
                    
                    isSubmitting = false
                    
                    // Show quick in-app confirmation
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showingSuccessNotification = true
                    }
                    
                    // Auto-dismiss after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingSuccessNotification = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            dismiss()
                        }
                    }
                }
                
            } catch {
                print("❌ Error saving sighting: \(error.localizedDescription)")
                
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "Failed to submit sighting. Please try again."
                }
            }
        }
    }
}

// MARK: - Quick Success View (Enhanced)
struct QuickSuccessView: View {
    let petName: String
    @Binding var isPresented: Bool
    let onDismiss: () -> Void
    
    @State private var animateHeart = false
    @State private var animateScale = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated Heart Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .scaleEffect(animateScale ? 1.2 : 1.0)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
                    .scaleEffect(animateHeart ? 1.2 : 1.0)
            }
            
            VStack(spacing: 16) {
                Text("🎉 Report Submitted!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Thank you for helping \(petName)!\nYour sighting has been saved and the owner will be notified.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text("Every report helps bring pets home! 🏠💕")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 25, x: 0, y: 15)
        )
        .padding(.horizontal, 30)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                animateHeart = true
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animateScale = true
            }
        }
    }
}
