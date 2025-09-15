import SwiftUI
import PhotosUI
import MapKit
import CoreLocation
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct ReportLostPetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    
    // Pet Information
    @State private var petName = ""
    @State private var selectedSpecies: PetSpecies = .dog
    @State private var breed = ""
    @State private var petDescription = ""
    
    // Photos
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []
    @State private var showingPhotoPicker = false
    
    // Location
    @State private var useCurrentLocation = true
    @State private var customLocation = ""
    @State private var showingMapPicker = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedAddress = ""
    
    // Additional Fields
    @State private var lastSeenDate = Date()
    @State private var petAge = ""
    @State private var petSize: PetSize = .medium
    @State private var petColor = ""
    @State private var reward = ""
    @State private var contactInfo = ""
    @State private var distinctiveFeatures = ""
    
    // UI State
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?

    // Define gradient colors as separate properties
    private let gradientColors = [
        Color(red: 0.4, green: 0.3, blue: 0.8),
        Color(red: 0.6, green: 0.4, blue: 0.9),
        Color(red: 0.5, green: 0.2, blue: 0.85)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced Gradient Background
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
                        headerSection
                        
                        petNameSection
                        
                        speciesSelectionSection
                        
                        petDetailsSection
                        
                        descriptionSection
                        
                        locationSection
                        
                        photoPickerSection
                        
                        submitSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Report Lost Pet")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundColor(.black)
                    }
                }
            }
            .sheet(isPresented: $showingMapPicker) {
                MapPickerView(selectedCoordinate: $selectedCoordinate, selectedAddress: $selectedAddress)
            }
            .alert("Report Submitted", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { dismiss() }
            } message: {
                Text("Your lost pet report has been successfully submitted.")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - View Sections
    
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
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Report Lost Pet")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            Text("Help the community find your beloved pet by providing detailed information.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(.top, 20)
    }
    
    private var petNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Pet Name", systemImage: "heart.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            TextField("Enter your pet's name", text: $petName)
                .textFieldStyle(GlassMorphismTextFieldStyle())
        }
    }
    
    private var speciesSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Pet Species", systemImage: "pawprint.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ForEach(PetSpecies.allCases, id: \.self) { species in
                    speciesButton(for: species)
                }
            }
        }
    }
    
    private func speciesButton(for species: PetSpecies) -> some View {
        Button(action: {
            selectedSpecies = species
        }) {
            VStack(spacing: 8) {
                Image(systemName: getIconName(for: species))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(selectedSpecies == species ? .white : .white.opacity(0.7))
                
                Text(species.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(selectedSpecies == species ? .white : .white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selectedSpecies == species ?
                          Color.white.opacity(0.25) :
                          Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedSpecies == species ?
                                    Color.white.opacity(0.3) :
                                    Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var petDetailsSection: some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                Label("Breed", systemImage: "tag.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                TextField("e.g., Golden Retriever", text: $breed)
                    .textFieldStyle(GlassMorphismTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Age (in years)", systemImage: "calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                TextField("e.g., 3", text: $petAge)
                    .keyboardType(.numberPad)
                    .textFieldStyle(GlassMorphismTextFieldStyle())
            }
            
            sizePickerSection
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Color", systemImage: "paintbrush.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                TextField("e.g., Golden Brown", text: $petColor)
                    .textFieldStyle(GlassMorphismTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Distinctive Features", systemImage: "star.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                TextField("e.g., White spot on chest", text: $distinctiveFeatures)
                    .textFieldStyle(GlassMorphismTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Reward Amount (Optional)", systemImage: "dollarsign.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                TextField("e.g., 500", text: $reward)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(GlassMorphismTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Contact Information", systemImage: "phone.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                TextField("Your phone number", text: $contactInfo)
                    .textFieldStyle(GlassMorphismTextFieldStyle())
            }
        }
    }
    
    private var sizePickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Size", systemImage: "ruler")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Menu {
                ForEach(PetSize.allCases, id: \.self) { size in
                    Button(action: {
                        petSize = size
                    }) {
                        HStack {
                            Text(size.rawValue)
                            if petSize == size {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(petSize.rawValue)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
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
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Description", systemImage: "text.alignleft")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            TextField("Describe your pet's behavior, personality, etc.", text: $petDescription, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(GlassMorphismTextFieldStyle())
        }
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Last Seen Location", systemImage: "location.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            HStack {
                Toggle("Use Current Location", isOn: $useCurrentLocation)
                    .toggleStyle(GlassToggleStyle())
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
            
            if !useCurrentLocation {
                Button(action: {
                    showingMapPicker = true
                }) {
                    HStack {
                        Image(systemName: "map")
                            .font(.system(size: 16, weight: .medium))
                        Text("Select Location on Map")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var photoPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Pet Photos", systemImage: "photo.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            PhotosPicker(selection: $selectedPhotos, matching: .images) {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("Select Photos")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.15)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
            }
        }
        .onChange(of: selectedPhotos) { _ in loadSelectedPhotos() }
    }
    
    private var submitSection: some View {
        VStack(spacing: 16) {
            if isSubmitting {
                submittingView
            } else {
                submitButton
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 14, weight: .medium))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.top, 12)
    }
    
    private var submittingView: some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
            Text("Submitting Report...")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var submitButton: some View {
        Button(action: submitReport) {
            HStack {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18, weight: .bold))
                Text("Submit Report")
                    .font(.system(size: 19, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(20)
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
        .disabled(!isFormValid)
        .opacity(isFormValid ? 1.0 : 0.6)
    }
    
    // MARK: - Helper Functions
    
    private func getIconName(for species: PetSpecies) -> String {
        switch species {
        case .dog:
            return "pawprint.fill"
        case .cat:
            return "cat.fill"
        case .bird:
            return "bird.fill"
        case .rabbit:
            return "hare.fill"
        case .other:
            return "questionmark.circle.fill"
        }
    }
    
    private var isFormValid: Bool {
        !petName.isEmpty && !breed.isEmpty && !petDescription.isEmpty && !contactInfo.isEmpty
    }
    
    private func loadSelectedPhotos() {
        Task {
            photoImages.removeAll()
            for item in selectedPhotos {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        photoImages.append(image)
                    }
                }
            }
        }
    }
    
    private func submitReport() {
        isSubmitting = true
        
        let locationData = LocationData(
            latitude: selectedCoordinate?.latitude ?? locationManager.currentLocation?.coordinate.latitude ?? 0.0,
            longitude: selectedCoordinate?.longitude ?? locationManager.currentLocation?.coordinate.longitude ?? 0.0,
            address: customLocation.isEmpty ? selectedAddress : customLocation,
            city: "Unknown",
            state: "Unknown"
        )
        
        // Upload photos and then save the report
        uploadPhotos { photoURLs, error in
            if let error = error {
                errorMessage = "Photo upload failed: \(error.localizedDescription)"
                isSubmitting = false
                return
            }
            
            let contactInfoStruct = ContactInfo(
                phone: contactInfo.isEmpty ? "(555) 123-4567" : contactInfo,
                email: "owner@example.com",
                preferredContactMethod: .phone
            )

            let lostPet = LostPet(
                id: UUID().uuidString,
                name: petName,
                breed: breed,
                species: selectedSpecies,
                age: Int(petAge) ?? 0,
                color: petColor,
                size: petSize,
                description: petDescription,
                lastSeenLocation: locationData,
                lastSeenDate: lastSeenDate,
                contactInfo: contactInfoStruct,
                ownerName: "Pet Owner",
                photos: photoURLs ?? [],
                isActive: true,
                reportedDate: Date(),
                rewardAmount: Double(reward),
                distinctiveFeatures: distinctiveFeatures.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
                temperament: "Friendly"
            )
            
            Task {
                do {
                    let db = Firestore.firestore()
                    
                    try await FirebaseService().submitLostPetReport(report: lostPet)
                    
                    try await db.collection("lostPets").document(lostPet.id).updateData([
                        "ownerID": FirebaseAuth.Auth.auth().currentUser?.uid ?? "unknown"
                    ])
                    
                    DispatchQueue.main.async {
                        showingMapPicker = false
                        isSubmitting = false
                        showSuccessAlert = true
                        
                        // Clear the form
                        petName = ""
                        breed = ""
                        petDescription = ""
                        petAge = ""
                        petColor = ""
                        distinctiveFeatures = ""
                        reward = ""
                        contactInfo = ""
                        selectedPhotos = []
                        photoImages = []
                    }
                } catch {
                    DispatchQueue.main.async {
                        isSubmitting = false
                        errorMessage = "Failed to submit report: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    private func uploadPhotos(completion: @escaping ([String]?, Error?) -> Void) {
        guard !photoImages.isEmpty else {
            completion([], nil)
            return
        }
        
        var uploadedPhotoURLs: [String] = []
        let storage = Storage.storage()
        let dispatchGroup = DispatchGroup()
        
        for (index, image) in photoImages.enumerated() {
            dispatchGroup.enter()
            let storageRef = storage.reference().child("lostPetsPhotos/\(UUID().uuidString)_\(index).jpg")
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                storageRef.putData(imageData, metadata: nil) { metadata, error in
                    if let error = error {
                        dispatchGroup.leave()
                        completion(nil, error)
                        return
                    }
                    
                    storageRef.downloadURL { url, error in
                        if let url = url {
                            uploadedPhotoURLs.append(url.absoluteString)
                        }
                        dispatchGroup.leave()
                    }
                }
            } else {
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(uploadedPhotoURLs, nil)
        }
    }
}

// MARK: - Custom Styles

struct GlassMorphismTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
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

struct GlassToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.purple : Color.gray.opacity(0.3))
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

#Preview {
    ReportLostPetView()
}
