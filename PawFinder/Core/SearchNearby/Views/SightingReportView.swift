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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Pet Info Header
                    petInfoHeader
                    
                    // Sighting Form
                    sightingForm
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        Text("Error: \(errorMessage)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Submit Button
                    submitButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Report Sighting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingMapPicker) {
            MapPickerView(
                selectedCoordinate: $selectedCoordinate,
                selectedAddress: $sightingLocation
            )
        }
        .overlay(
            // Enhanced Success Notification Overlay (kept for immediate feedback)
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
    
    private var petInfoHeader: some View {
        VStack(spacing: 16) {
            // Pet Photo
            if let firstPhoto = pet.photos.first, !firstPhoto.isEmpty {
                AsyncImage(url: URL(string: firstPhoto)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: pet.species.iconName)
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 120, height: 120)
                .cornerRadius(16)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .cornerRadius(16)
                    .overlay(
                        Image(systemName: pet.species.iconName)
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(spacing: 8) {
                Text(pet.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("\(pet.breed) • \(pet.species.rawValue.capitalized)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var sightingForm: some View {
        VStack(spacing: 20) {
            // Date and Time
            VStack(alignment: .leading, spacing: 8) {
                Text("When did you see \(pet.name)?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                DatePicker("Sighting Date", selection: $sightingDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(CompactDatePickerStyle())
            }
            
            // Location
            VStack(alignment: .leading, spacing: 8) {
                Text("Where did you see \(pet.name)?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Button(action: {
                    showingMapPicker = true
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        
                        Text(sightingLocation.isEmpty ? "Select location on map" : sightingLocation)
                            .foregroundColor(sightingLocation.isEmpty ? .secondary : .primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description (Optional)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                TextField("What was the pet doing? Any additional details...", text: $sightingDescription, axis: .vertical)
                    .lineLimit(3...6)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            
            // Reporter Info
            VStack(alignment: .leading, spacing: 16) {
                Text("Your Information")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                TextField("Your name", text: $reporterName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
                TextField("Your contact (phone or email)", text: $reporterContact)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }
    
    private var submitButton: some View {
        Button(action: {
            submitSighting()
        }) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                }
                Text(isSubmitting ? "Submitting..." : "Submit Sighting Report")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .disabled(!isFormValid || isSubmitting)
        .opacity(isFormValid && !isSubmitting ? 1.0 : 0.6)
    }
    
    private var isFormValid: Bool {
        !sightingLocation.isEmpty && !reporterName.isEmpty && !reporterContact.isEmpty
    }
    
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

// MARK: - Quick Success View (simplified version for quick feedback)
struct QuickSuccessView: View {
    let petName: String
    @Binding var isPresented: Bool
    let onDismiss: () -> Void
    
    @State private var animateHeart = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated Heart Icon
            Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
                .scaleEffect(animateHeart ? 1.2 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true),
                    value: animateHeart
                )
            
            VStack(spacing: 12) {
                Text("🎉 Report Submitted!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Thank you for helping \(petName)!\nYour sighting has been saved and the owner will be notified.")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 40)
        .onAppear {
            animateHeart = true
        }
    }
}
