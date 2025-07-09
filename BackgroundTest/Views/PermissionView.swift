import SwiftUI
import MediaPlayer

struct PermissionView: View {
    @StateObject private var permissionManager = PermissionManager()
    @State private var isRequestingPermission = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            Image(systemName: "music.note.list")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            // Title
            Text("Music Library Access")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Description
            Text("To track your music listening habits and provide personalized statistics, this app needs access to your music library.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Status
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: statusIcon)
                        .foregroundColor(permissionManager.permissionStatusColor)
                    
                    Text(permissionManager.permissionStatusText)
                        .font(.subheadline)
                        .foregroundColor(permissionManager.permissionStatusColor)
                }
                
                if permissionManager.isPermissionDenied {
                    Text("You can enable access in Settings > Privacy & Security > Media & Apple Music")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Spacer()
            
            // Actions
            VStack(spacing: 16) {
                if permissionManager.isPermissionNotDetermined {
                    Button(action: {
                        requestPermission()
                    }) {
                        HStack {
                            if isRequestingPermission {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            
                            Text(isRequestingPermission ? "Requesting..." : "Grant Access")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(isRequestingPermission)
                    .padding(.horizontal)
                }
                
                if permissionManager.isPermissionDenied {
                    Button(action: {
                        permissionManager.openSettings()
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Open Settings")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            permissionManager.checkMusicLibraryPermission()
        }
        .alert("Permission Required", isPresented: $permissionManager.showingSettingsAlert) {
            Button("Settings") {
                permissionManager.openSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable music library access in Settings to use this app.")
        }
    }
    
    private var statusIcon: String {
        switch permissionManager.musicLibraryStatus {
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .restricted:
            return "exclamationmark.triangle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        @unknown default:
            return "questionmark.circle.fill"
        }
    }
    
    private func requestPermission() {
        isRequestingPermission = true
        
        Task {
            await permissionManager.requestMusicLibraryPermission()
            
            DispatchQueue.main.async {
                isRequestingPermission = false
            }
        }
    }
}

#Preview {
    PermissionView()
}