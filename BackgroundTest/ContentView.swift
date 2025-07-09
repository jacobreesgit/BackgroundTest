import SwiftUI
import MediaPlayer

struct ContentView: View {
    @State private var authorizationStatus: MPMediaLibraryAuthorizationStatus = .notDetermined
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "music.note")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .font(.system(size: 50))
            
            Text("Music Library Access")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Current Status: \(statusDescription)")
                .font(.body)
                .foregroundColor(statusColor)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Grant Music Access") {
                requestMusicLibraryAccess()
            }
            .buttonStyle(.borderedProminent)
            .font(.headline)
            
            if authorizationStatus == .authorized {
                Button("Test Library Access") {
                    testMusicLibraryAccess()
                }
                .buttonStyle(.bordered)
                .font(.headline)
            }
        }
        .padding()
        .onAppear {
            checkCurrentAuthorizationStatus()
        }
    }
    
    private var statusDescription: String {
        switch authorizationStatus {
        case .authorized:
            return "Authorized ✅"
        case .denied:
            return "Denied ❌"
        case .restricted:
            return "Restricted ⚠️"
        case .notDetermined:
            return "Not Determined ❓"
        @unknown default:
            return "Unknown Status"
        }
    }
    
    private var statusColor: Color {
        switch authorizationStatus {
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
    
    private func checkCurrentAuthorizationStatus() {
        authorizationStatus = MPMediaLibrary.authorizationStatus()
        print("📱 [MUSIC_ACCESS] Current authorization status: \(logStatusDescription(authorizationStatus))")
    }
    
    private func requestMusicLibraryAccess() {
        print("🎵 [MUSIC_ACCESS] Requesting music library access...")
        
        MPMediaLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
                print("🎵 [MUSIC_ACCESS] Authorization result: \(self.logStatusDescription(status))")
            }
        }
    }
    
    private func logStatusDescription(_ status: MPMediaLibraryAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "Authorized - Full access to music library granted"
        case .denied:
            return "Denied - User denied access to music library"
        case .restricted:
            return "Restricted - Access restricted by system policies"
        case .notDetermined:
            return "Not Determined - User hasn't been asked for permission yet"
        @unknown default:
            return "Unknown - Unrecognized authorization status"
        }
    }
    
    private func testMusicLibraryAccess() {
        guard authorizationStatus == .authorized else {
            print("❌ [MUSIC_LIBRARY] Cannot access music library - insufficient permissions")
            return
        }
        
        print("🎵 [MUSIC_LIBRARY] Testing music library access...")
        
        let songsQuery = MPMediaQuery.songs()
        guard let songs = songsQuery.items else {
            print("❌ [MUSIC_LIBRARY] Failed to fetch songs from library")
            return
        }
        
        print("📊 [MUSIC_LIBRARY] Total songs in library: \(songs.count)")
        
        if songs.isEmpty {
            print("📭 [MUSIC_LIBRARY] No songs found in music library")
            return
        }
        
        let firstFiveSongs = Array(songs.prefix(5))
        print("🎶 [MUSIC_LIBRARY] First \(firstFiveSongs.count) songs:")
        
        for (index, song) in firstFiveSongs.enumerated() {
            let title = song.title ?? "Unknown Title"
            let artist = song.artist ?? "Unknown Artist"
            print("   \(index + 1). \"\(title)\" by \(artist)")
        }
        
        print("✅ [MUSIC_LIBRARY] Music library access test completed successfully")
    }
}

#Preview {
    ContentView()
}