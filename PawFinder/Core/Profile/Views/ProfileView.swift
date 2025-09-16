import SwiftUI
import FirebaseAuth
import PhotosUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var newName: String = ""
    @State private var oldPassword: String = ""
    @State private var newPassword: String = ""
    @State private var retypePassword: String = ""
    @State private var notificationGeneral: Bool = true
    @State private var notificationLostPets: Bool = false
    @State private var notificationMessages: Bool = true
    @State private var showSavedAlert = false
    @State private var showLogoutAlert = false
    @State private var showingBiometricSettings = false
    
    // Image picker states
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var isUploadingImage = false
    @State private var showingImagePicker = false

    var hasChanges: Bool {
        let nameChanged = !newName.isEmpty && newName != viewModel.userName
        let notificationsChanged = notificationGeneral != viewModel.notificationGeneral ||
                                 notificationLostPets != viewModel.notificationLostPets ||
                                 notificationMessages != viewModel.notificationMessages
        let passwordChange = !oldPassword.isEmpty && !newPassword.isEmpty && !retypePassword.isEmpty
        
        return nameChanged || notificationsChanged || passwordChange
    }
    
    var passwordsMatch: Bool {
        newPassword == retypePassword
    }
    
    var isPasswordChangeValid: Bool {
        if newPassword.isEmpty && retypePassword.isEmpty && oldPassword.isEmpty {
            return true
        }
        return !oldPassword.isEmpty && !newPassword.isEmpty && !retypePassword.isEmpty && passwordsMatch && newPassword.count >= 6
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.35, green: 0.25, blue: 0.8),
                        Color(red: 0.55, green: 0.35, blue: 0.9),
                        Color(red: 0.65, green: 0.45, blue: 0.95)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header with Back Button and Logout Button
                        HStack {
                            Button(action: { dismiss() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Back")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showLogoutAlert = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("Logout")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [Color.white.opacity(0.6), Color.white.opacity(0.2)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.top, 30)
                        .padding(.horizontal, 20)

                        // Profile Section
                        VStack(spacing: 16) {
                            // Profile Topic with glass effect
                            Text("Profile")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.white, Color.white.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                                .padding(.bottom, 8)
                            
                            // Profile Picture with enhanced glass effect
                            ZStack {
                                // Outer glow effect
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [Color.white.opacity(0.3), Color.clear],
                                            center: .center,
                                            startRadius: 55,
                                            endRadius: 80
                                        )
                                    )
                                    .frame(width: 160, height: 160)
                                
                                // Glass background ring
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 130, height: 130)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.8),
                                                        Color.white.opacity(0.3),
                                                        Color.white.opacity(0.1)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                                
                                // Profile Image
                                Group {
                                    if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else if !viewModel.profileImageURL.isEmpty {
                                        AsyncImage(url: URL(string: viewModel.profileImageURL)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Image("profile_photo")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        }
                                    } else {
                                        Image("profile_photo")
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    }
                                }
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.8), Color.white.opacity(0.4)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 3
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
                                
                                // Upload overlay when uploading
                                if isUploadingImage {
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 110, height: 110)
                                    
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.2)
                                }
                                
                                // Enhanced camera button
                                if !isUploadingImage {
                                    Button(action: {
                                        showingImagePicker = true
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                                .frame(width: 36, height: 36)
                                                .overlay(
                                                    Circle()
                                                        .stroke(
                                                            LinearGradient(
                                                                colors: [Color.white.opacity(0.6), Color.white.opacity(0.2)],
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            ),
                                                            lineWidth: 1
                                                        )
                                                )
                                            
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [Color.blue, Color.purple],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        }
                                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                                    }
                                    .offset(x: 40, y: 40)
                                }
                            }
                            .onTapGesture {
                                if !isUploadingImage {
                                    showingImagePicker = true
                                }
                            }
                            
                            // User's Name with gradient text
                            Text(viewModel.userName.isEmpty ? "Your Name" : viewModel.userName)
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.white, Color.white.opacity(0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                .padding(.top, 16)
                            
                            Text("Pet Parent • Community Helper")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .padding(.top, 8)

                        // Enhanced Profile Details Card
                        VStack(spacing: 24) {
                            // Name field
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Name")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                                
                                TextField("Your Name", text: $newName)
                                    .font(.system(size: 17, weight: .medium))
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(
                                                        LinearGradient(
                                                            colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: 1
                                                    )
                                            )
                                    )
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                            }
                            
                            // Email field (disabled)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Email")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                                
                                TextField("Your Email", text: .constant(viewModel.email))
                                    .font(.system(size: 17, weight: .medium))
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.gray.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                    .disabled(true)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThickMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                        .padding(.horizontal, 20)

                        // Security Settings Section
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Image(systemName: "shield.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.green, Color.blue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    Text("Security Settings")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                
                                VStack(spacing: 16) {
                                    // Biometric Authentication Toggle
                                    Button(action: {
                                        showingBiometricSettings = true
                                    }) {
                                        HStack {
                                            HStack(spacing: 12) {
                                                Image(systemName: authViewModel.biometricIcon)
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundColor(.primary)
                                                    .frame(width: 24)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("\(authViewModel.biometricName) Authentication")
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(.primary)
                                                    
                                                    Text(authViewModel.isBiometricEnabled ? "Enabled" : (authViewModel.isBiometricAvailable ? "Available" : "Not Available"))
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            HStack(spacing: 8) {
                                                // Status indicator
                                                Circle()
                                                    .fill(authViewModel.isBiometricEnabled ? Color.green : (authViewModel.isBiometricAvailable ? Color.orange : Color.gray))
                                                    .frame(width: 8, height: 8)
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThickMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                        .padding(.horizontal, 20)

                        // Enhanced Password Change Section
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Image(systemName: "lock.shield")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.blue, Color.purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    Text("Change Password")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                                
                                VStack(spacing: 20) {
                                    // Current Password field
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Current Password")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 4)
                                        
                                        SecureField("Enter current password", text: $oldPassword)
                                            .font(.system(size: 17, weight: .medium))
                                            .padding(.vertical, 16)
                                            .padding(.horizontal, 18)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(.ultraThinMaterial)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 14)
                                                            .stroke(
                                                                LinearGradient(
                                                                    colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                ),
                                                                lineWidth: 1
                                                            )
                                                    )
                                            )
                                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                                    }
                                    
                                    // New Password field
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("New Password")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 4)
                                        
                                        SecureField("Enter new password (min 6 characters)", text: $newPassword)
                                            .font(.system(size: 17, weight: .medium))
                                            .padding(.vertical, 16)
                                            .padding(.horizontal, 18)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(.ultraThinMaterial)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 14)
                                                            .stroke(
                                                                !newPassword.isEmpty && newPassword.count < 6 ?
                                                                LinearGradient(
                                                                    colors: [Color.red.opacity(0.6), Color.red.opacity(0.3)],
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                ) :
                                                                LinearGradient(
                                                                    colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                ),
                                                                lineWidth: 1
                                                            )
                                                    )
                                            )
                                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                                        
                                        if !newPassword.isEmpty && newPassword.count < 6 {
                                            HStack {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.red)
                                                Text("Password must be at least 6 characters")
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(.red)
                                            }
                                            .padding(.leading, 4)
                                        }
                                    }
                                    
                                    // Retype Password field
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Confirm New Password")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 4)
                                        
                                        SecureField("Retype new password", text: $retypePassword)
                                            .font(.system(size: 17, weight: .medium))
                                            .padding(.vertical, 16)
                                            .padding(.horizontal, 18)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(.ultraThinMaterial)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 14)
                                                            .stroke(
                                                                !retypePassword.isEmpty && !passwordsMatch ?
                                                                LinearGradient(
                                                                    colors: [Color.red.opacity(0.6), Color.red.opacity(0.3)],
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                ) :
                                                                LinearGradient(
                                                                    colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                ),
                                                                lineWidth: 1
                                                            )
                                                    )
                                            )
                                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                                        
                                        if !retypePassword.isEmpty && !passwordsMatch {
                                            HStack {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.red)
                                                Text("Passwords do not match")
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(.red)
                                            }
                                            .padding(.leading, 4)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThickMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                        .padding(.horizontal, 20)

                        // Enhanced Notification Settings
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Image(systemName: "bell.badge")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.orange, Color.red],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    Text("Notification Settings")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                                
                                VStack(spacing: 16) {
                                    NotificationToggle(
                                        title: "General Notifications",
                                        subtitle: "App updates and announcements",
                                        isOn: $notificationGeneral
                                    )
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                    
                                    NotificationToggle(
                                        title: "Lost Pet Alerts",
                                        subtitle: "New missing pets in your area",
                                        isOn: $notificationLostPets
                                    )
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                    
                                    NotificationToggle(
                                        title: "Messages",
                                        subtitle: "Direct messages and replies",
                                        isOn: $notificationMessages
                                    )
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThickMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                        .padding(.horizontal, 20)

                        // Enhanced Save Button
                        Button(action: {
                            saveProfile()
                        }) {
                            HStack(spacing: 12) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .medium))
                                    
                                    Text("Save Changes")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        (hasChanges && isPasswordChangeValid) ?
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                (hasChanges && isPasswordChangeValid) ?
                                                Color.white.opacity(0.3) :
                                                Color.clear,
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .shadow(
                                color: (hasChanges && isPasswordChangeValid) ?
                                Color.blue.opacity(0.3) :
                                Color.black.opacity(0.1),
                                radius: (hasChanges && isPasswordChangeValid) ? 15 : 8,
                                x: 0,
                                y: (hasChanges && isPasswordChangeValid) ? 8 : 4
                            )
                        }
                        .disabled(!(hasChanges && isPasswordChangeValid) || viewModel.isLoading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.fetchProfile()
        }
        .onChange(of: viewModel.userName) { _ in
            setupInitialValues()
        }
        .onChange(of: viewModel.notificationGeneral) { _ in
            setupInitialValues()
        }
        .onChange(of: viewModel.notificationLostPets) { _ in
            setupInitialValues()
        }
        .onChange(of: viewModel.notificationMessages) { _ in
            setupInitialValues()
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let newItem = newItem {
                    await loadSelectedImage(from: newItem)
                }
            }
        }
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .fullScreenCover(isPresented: $showingBiometricSettings) {
            NavigationView {
                BiometricSettingsView()
                    .environmentObject(authViewModel)
                    .navigationBarTitleDisplayMode(.inline)                   
                    
            }
        }
        .alert("Profile Updated", isPresented: $showSavedAlert) {
            Button("OK") { }
        } message: {
            Text("Your profile has been updated successfully.")
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func setupInitialValues() {
        if newName.isEmpty || newName == viewModel.userName {
            newName = viewModel.userName
        }
        notificationGeneral = viewModel.notificationGeneral
        notificationLostPets = viewModel.notificationLostPets
        notificationMessages = viewModel.notificationMessages
    }
    
    private func loadSelectedImage(from item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                DispatchQueue.main.async {
                    self.selectedImageData = data
                    self.uploadProfileImage()
                }
            }
        } catch {
            DispatchQueue.main.async {
                viewModel.errorMessage = "Failed to load selected image: \(error.localizedDescription)"
            }
        }
    }
    
    private func uploadProfileImage() {
        guard let imageData = selectedImageData,
              let image = UIImage(data: imageData) else {
            viewModel.errorMessage = "Invalid image data"
            return
        }
        
        isUploadingImage = true
        
        Task {
            do {
                try await viewModel.uploadProfileImage(image)
                DispatchQueue.main.async {
                    self.isUploadingImage = false
                    self.selectedItem = nil
                    self.selectedImageData = nil
                    self.showingImagePicker = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isUploadingImage = false
                    self.viewModel.errorMessage = "Failed to upload image: \(error.localizedDescription)"
                    self.showingImagePicker = false
                }
            }
        }
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            dismiss()
        } catch let signOutError as NSError {
            viewModel.errorMessage = "Error signing out: \(signOutError.localizedDescription)"
        }
    }
    
    private func saveProfile() {
        // Validate password change if attempted
        if !oldPassword.isEmpty || !newPassword.isEmpty || !retypePassword.isEmpty {
            guard isPasswordChangeValid else {
                viewModel.errorMessage = "Please fill in all password fields correctly"
                return
            }
        }
        
        let passwordToUpdate = (!oldPassword.isEmpty && !newPassword.isEmpty && !retypePassword.isEmpty && passwordsMatch && newPassword.count >= 6) ? newPassword : nil
        
        viewModel.saveProfile(
            newName: newName,
            newPassword: passwordToUpdate,
            notificationGeneral: notificationGeneral,
            notificationLostPets: notificationLostPets,
            notificationMessages: notificationMessages
        ) { success in
            if success {
                showSavedAlert = true
                // Clear password fields after successful update
                oldPassword = ""
                newPassword = ""
                retypePassword = ""
            }
        }
    }
}

struct NotificationToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(isOn ? Color.blue : Color.gray.opacity(0.3))
                .scaleEffect(0.9)
                .shadow(color: isOn ? Color.blue.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
