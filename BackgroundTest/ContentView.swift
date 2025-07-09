import SwiftUI
import MediaPlayer

struct ContentView: View {
    @State private var authorizationStatus: MPMediaLibraryAuthorizationStatus = .notDetermined
    @State private var isObserverSetup = false
    @State private var playCountTimer: Timer?
    @State private var currentTrackingItem: MPMediaItem?
    
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
        
        if authorizationStatus == .authorized && !isObserverSetup {
            setupMusicPlayerObserver()
        }
    }
    
    private func requestMusicLibraryAccess() {
        print("🎵 [MUSIC_ACCESS] Requesting music library access...")
        
        MPMediaLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
                print("🎵 [MUSIC_ACCESS] Authorization result: \(self.logStatusDescription(status))")
                
                if status == .authorized && !self.isObserverSetup {
                    self.setupMusicPlayerObserver()
                }
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
    
    private func setupMusicPlayerObserver() {
        guard !isObserverSetup else {
            print("⚠️ [MUSIC_PLAYER] Observer already setup, skipping")
            return
        }
        
        print("🎧 [MUSIC_PLAYER] Setting up music player observer...")
        
        let musicPlayer = MPMusicPlayerController.systemMusicPlayer
        musicPlayer.beginGeneratingPlaybackNotifications()
        
        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: musicPlayer,
            queue: .main
        ) { _ in
            self.handleNowPlayingItemChange()
        }
        
        isObserverSetup = true
        print("✅ [MUSIC_PLAYER] Music player observer setup completed")
    }
    
    private func handleNowPlayingItemChange() {
        let musicPlayer = MPMusicPlayerController.systemMusicPlayer
        
        // Cancel existing timer if there was a previous song being tracked
        if let timer = playCountTimer {
            timer.invalidate()
            
            if let previousItem = currentTrackingItem {
                let previousTitle = previousItem.title ?? "Unknown Title"
                let previousArtist = previousItem.artist ?? "Unknown Artist"
                print("⏭️ [PLAY_COUNT] Song skipped before 30 seconds: \"\(previousTitle)\" by \(previousArtist)")
            }
        }
        
        guard let nowPlayingItem = musicPlayer.nowPlayingItem else {
            print("🎵 [NOW_PLAYING] No song currently playing")
            currentTrackingItem = nil
            playCountTimer = nil
            return
        }
        
        let title = nowPlayingItem.title ?? "Unknown Title"
        let artist = nowPlayingItem.artist ?? "Unknown Artist"
        
        print("🎵 [NOW_PLAYING] Song changed: \"\(title)\" by \(artist)")
        
        // Start tracking this new song
        startPlayCountTimer(for: nowPlayingItem)
    }
    
    private func startPlayCountTimer(for item: MPMediaItem) {
        currentTrackingItem = item
        
        let title = item.title ?? "Unknown Title"
        let artist = item.artist ?? "Unknown Artist"
        
        print("⏱️ [PLAY_COUNT] Starting 30-second timer for: \"\(title)\" by \(artist)")
        
        playCountTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { _ in
            self.recordPlayCount(for: item)
        }
    }
    
    private func recordPlayCount(for item: MPMediaItem) {
        let title = item.title ?? "Unknown Title"
        let artist = item.artist ?? "Unknown Artist"
        
        print("✅ [PLAY_COUNT] Song played for 30+ seconds - counting as play: \"\(title)\" by \(artist)")
        
        // Here you would typically save to Core Data or increment a counter
        // For now, we'll just log the successful play count
        
        // Clear the timer and tracking item
        playCountTimer = nil
        currentTrackingItem = nil
    }
}

#Preview {
    ContentView()
}