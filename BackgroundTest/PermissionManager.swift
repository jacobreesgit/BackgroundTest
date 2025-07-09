import Foundation
import MediaPlayer
import SwiftUI
import Combine

class PermissionManager: ObservableObject {
    @Published var musicLibraryStatus: MPMediaLibraryAuthorizationStatus = .notDetermined
    @Published var showingSettingsAlert = false
    
    init() {
        checkMusicLibraryPermission()
    }
    
    func checkMusicLibraryPermission() {
        musicLibraryStatus = MPMediaLibrary.authorizationStatus()
    }
    
    func requestMusicLibraryPermission() async {
        let status = await MusicTrackingManager.shared.requestMusicLibraryAccess()
        
        DispatchQueue.main.async {
            self.musicLibraryStatus = status ? .authorized : .denied
            
            if !status {
                self.showingSettingsAlert = true
            }
        }
    }
    
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    var isPermissionDenied: Bool {
        musicLibraryStatus == .denied
    }
    
    var isPermissionRestricted: Bool {
        musicLibraryStatus == .restricted
    }
    
    var isPermissionNotDetermined: Bool {
        musicLibraryStatus == .notDetermined
    }
    
    var isPermissionGranted: Bool {
        musicLibraryStatus == .authorized
    }
    
    var permissionStatusText: String {
        switch musicLibraryStatus {
        case .authorized:
            return "Access granted to your music library"
        case .denied:
            return "Access to music library was denied"
        case .restricted:
            return "Music library access is restricted"
        case .notDetermined:
            return "Music library access not requested"
        @unknown default:
            return "Unknown permission status"
        }
    }
    
    var permissionStatusColor: Color {
        switch musicLibraryStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .restricted:
            return .orange
        case .notDetermined:
            return .secondary
        @unknown default:
            return .secondary
        }
    }
}